import "package:myttmi/core/ui/panel_style.dart";
import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:ota_update/ota_update.dart";
import "package:http/http.dart" as http;
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:url_launcher/url_launcher.dart";

/// Versión de la app frente a lo que pide el servidor (GET /app/version).
///
/// - Build menor que `min_build` → [mustUpdate]: la app no sigue, muestra
///   [ForceUpdateScreen]. Para cuando un cambio del servidor deja inservible
///   una versión vieja (sin esto, quien no actualizó vería errores).
/// - Build menor que `latest_build` → [shouldUpdate]: se sugiere una vez.
///
/// Los números y la dirección de descarga se cambian en Render
/// (APP_MIN_BUILD, APP_LATEST_BUILD, APP_UPDATE_URL), sin publicar la app.
class AppUpdate {
  AppUpdate._();

  static String version = "";
  static int build = 0;
  static bool mustUpdate = false;
  static bool shouldUpdate = false;
  static String updateUrl = "https://play.google.com/store/apps/details?id=cl.myttm.app";

  /// "1.0.0 (44)" para Ajustes y los reportes de problemas.
  static String get label => version.isEmpty ? "" : "$version ($build)";

  /// Al abrir la app. Sin señal o si el servidor no responde, sigue normal:
  /// nunca deja al jugador afuera por un error de esta consulta.
  static Future<void> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {}
    try {
      final res = await http
          .get(Uri.parse("${AppConfig.baseUrl}/api/v1/app/version"))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return;
      final data = (jsonDecode(res.body) as Map<String, dynamic>)["data"] as Map<String, dynamic>;
      final min = (data["min_build"] as num?)?.toInt() ?? 0;
      final latest = (data["latest_build"] as num?)?.toInt() ?? 0;
      final url = data["update_url"];
      if (url is String && url.isNotEmpty) updateUrl = url;
      if (build > 0) {
        mustUpdate = build < min;
        shouldUpdate = !mustUpdate && build < latest;
      }
    } catch (_) {}
  }

  static Future<void> openStore() => launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);

  /// El enlace de descarga es un APK y estamos en Android: se descarga y se
  /// instala desde la propia app (distribución directa, sin Play Store).
  static bool get canSelfUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android && Uri.tryParse(updateUrl)?.path.toLowerCase().endsWith(".apk") == true;

  /// "Actualizar": con APK, lo descarga dentro de la app (con progreso) y
  /// abre el instalador de Android — la persona solo toca "Instalar" (la
  /// primera vez Android pide permitir instalar apps de MyTTM). Si no se
  /// puede (otro sistema, error), abre el enlace en el navegador.
  static Future<void> update(BuildContext context) async {
    if (!canSelfUpdate) return openStore();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SelfUpdateDialog(),
    );
    if (ok == false) await openStore();
  }

  /// Sugerencia (no obligatoria), una vez por sesión.
  static Future<void> suggest(BuildContext context) async {
    if (!shouldUpdate) return;
    shouldUpdate = false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Panel.sheetColor,
        shape: Panel.dialogShape,
        titlePadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        title: const PanelTitleBar(title: "Hay una versión nueva"),
        content: Text("Actualiza MyTTM para tener las últimas mejoras.", style: AppTypography.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Ahora no")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Actualizar")),
        ],
      ),
    );
    if (go == true && context.mounted) await update(context);
  }
}

/// Descarga del APK nuevo con barra de progreso. Cierra con true cuando se
/// abrió el instalador de Android, false si falló (y entonces se ofrece el
/// navegador).
class _SelfUpdateDialog extends StatefulWidget {
  const _SelfUpdateDialog();

  @override
  State<_SelfUpdateDialog> createState() => _SelfUpdateDialogState();
}

class _SelfUpdateDialogState extends State<_SelfUpdateDialog> {
  StreamSubscription<OtaEvent>? _sub;
  double? _progress; // 0..1; null = preparando
  String _status = "Preparando la descarga…";

  @override
  void initState() {
    super.initState();
    try {
      _sub = OtaUpdate()
          // Por el servidor (cuenta la descarga para el panel de superusuario
          // y redirige al mismo APK de APP_UPDATE_URL).
          .execute("${AppConfig.baseUrl}/api/v1/app/download?src=app", destinationFilename: "myttm-update.apk")
          .listen(_onEvent, onError: (_) => _finish(false));
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(false));
    }
  }

  void _onEvent(OtaEvent e) {
    if (!mounted) return;
    switch (e.status) {
      case OtaStatus.DOWNLOADING:
        final p = double.tryParse(e.value ?? "");
        setState(() {
          _progress = p == null ? null : (p / 100).clamp(0.0, 1.0);
          _status = "Descargando la versión nueva…";
        });
      case OtaStatus.INSTALLING:
      case OtaStatus.INSTALLATION_DONE:
        // Se abrió el instalador de Android: allí se toca "Instalar".
        _finish(true);
      case OtaStatus.CANCELED:
        Navigator.of(context).pop(true);
      default:
        // PERMISSION_NOT_GRANTED_ERROR, DOWNLOAD_ERROR, INTERNAL_ERROR, …
        _finish(false);
    }
  }

  void _finish(bool ok) {
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _progress == null ? null : (_progress! * 100).round();
    return AlertDialog(
      backgroundColor: Panel.sheetColor,
      shape: Panel.dialogShape,
      titlePadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      title: const PanelTitleBar(title: "Actualizando MyTTM"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status, style: AppTypography.bodyMuted),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.scorifySurface2,
              color: AppColors.scorifyMint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct == null ? "" : "$pct %",
            textAlign: TextAlign.right,
            style: AppTypography.bodyMuted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            "Al terminar se abre el instalador: toca \"Instalar\". La primera vez Android te pide permitir instalar apps de MyTTM.",
            style: AppTypography.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Pantalla que bloquea la app cuando la versión ya no es compatible.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.scorifyBg,
        body: PrismBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(markSize: 72, showWordmark: false),
                  const SizedBox(height: 24),
                  const Text(
                    "Actualiza MyTTM",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.scorifyText),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Esta versión ya no es compatible. Descarga la última para seguir viendo tus campeonatos y partidos.",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: "Actualizar", onPressed: () => AppUpdate.update(context)),
                  if (AppUpdate.label.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Versión instalada: ${AppUpdate.label}", style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
