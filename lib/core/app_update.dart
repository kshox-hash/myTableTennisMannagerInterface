import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
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

  /// Sugerencia (no obligatoria), una vez por sesión.
  static Future<void> suggest(BuildContext context) async {
    if (!shouldUpdate) return;
    shouldUpdate = false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scorifyDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hay una versión nueva", style: TextStyle(color: AppColors.scorifyText, fontWeight: FontWeight.w700)),
        content: Text("Actualiza MyTTM para tener las últimas mejoras.", style: AppTypography.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Ahora no")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Actualizar")),
        ],
      ),
    );
    if (go == true) await openStore();
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
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 28),
                  AppButton(label: "Actualizar", onPressed: AppUpdate.openStore),
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
