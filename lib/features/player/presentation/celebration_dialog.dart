import "package:myttmi/core/ui/panel_style.dart";
import "dart:convert";

import "package:flutter/material.dart";
import "package:lottie/lottie.dart";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/user_avatar.dart";

/// Ventana de celebración: cuando terminan categorías en las que el jugador
/// estaba inscrito, al abrir la app le aparece una sola ventana con sus
/// resultados, ordenados del mejor al peor. La animación (Lottie) se ve solo
/// en el primero; los demás se pasan deslizando (puntitos "1 de N") y al
/// final hay un resumen. Al cerrarla se marcan todas como vistas en el
/// servidor (no vuelven a salir ni en la app ni en la web).
///
/// Animación: el mismo Lottie que usa la web (/celebration/celebration.json
/// en myttm.cl), así se cambia sin publicar una versión nueva de la app; si
/// no existe, la ventana se muestra igual.
class Celebrations {
  static bool _shown = false;

  static Future<Map<String, String>> _headers() async {
    final token = await SessionStorage().getToken();
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// Revisa si hay celebraciones pendientes y las muestra (una vez por sesión).
  static Future<void> check(BuildContext context) async {
    if (_shown) return;
    _shown = true;
    try {
      final res = await apiHttp
          .get(
            Uri.parse("${AppConfig.baseUrl}${Endpoints.playerCelebrations}"),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return;
      final data =
          ((jsonDecode(res.body) as Map<String, dynamic>)["data"] as List? ??
                  const [])
              .cast<Map<String, dynamic>>()
              .toList()
            ..sort(
              (a, b) => (a["position"] as num).compareTo(b["position"] as num),
            );
      if (data.isEmpty || !context.mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Cerrar",
        barrierColor: Colors.black.withValues(alpha: 0.7),
        transitionDuration: const Duration(milliseconds: 320),
        transitionBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        pageBuilder: (_, __, ___) => _CelebrationDialog(items: data),
      );
      // Cerrar de cualquier forma marca todas como vistas.
      for (final c in data) {
        _dismiss(c["id_notification"].toString());
      }
    } catch (_) {
      // Sin conexión o error: no se muestra nada.
    }
  }

  static Future<void> _dismiss(String id) async {
    try {
      await apiHttp.post(
        Uri.parse(
          "${AppConfig.baseUrl}${Endpoints.playerCelebrationDismiss(id)}",
        ),
        headers: await _headers(),
      );
    } catch (_) {}
  }
}

const _gold = Color(0xFFD99A2B);

/// Metal de cada lugar (dorado = mismo trío que la final de la llave).
const _metal = {
  1: [Color(0xFFFFD479), Color(0xFF8A5C12), Color(0xFF2B1C04)],
  2: [Color(0xFFECEFF1), Color(0xFF78909C), Color(0xFF1C262B)],
  3: [Color(0xFFF3C79A), Color(0xFF8A4F22), Color(0xFF2B1606)],
};

/// Medalla del lugar (1°-3°); del 4° hacia abajo, una insignia con el número.
class _MedalBadge extends StatelessWidget {
  final int position;
  final double size;
  const _MedalBadge({required this.position, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final m = _metal[position];
    if (m == null) {
      // Del 4° hacia abajo: medalla de participación (celeste y lima de la marca).
      return Image.asset(
        "assets/images/medal_participation.webp",
        width: size,
        height: size,
      );
    }
    // Medallas oficiales de MyTTM (oro, plata, bronce) con un brillo detrás.
    const files = {1: "gold", 2: "silver", 3: "bronze"};
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Image.asset(
        "assets/images/medal_${files[position]}.webp",
        width: size,
        height: size,
      ),
    );
  }
}

(String, String) _headline(int p) {
  if (p == 1) return ("¡Eres campeón!", "Ganaste la categoría");
  if (p == 2) return ("¡Subcampeón!", "Llegaste a la final");
  if (p == 3) return ("¡Tercer lugar!", "Terminaste en el podio");
  return ("¡Terminaste en el lugar $p!", "Gracias por jugar");
}

String _roundLabel(int round, int total) {
  if (round == 0) return "Pre-llave";
  final fromEnd = total - round;
  if (fromEnd == 0) return "Final";
  if (fromEnd == 1) return "Semifinal";
  if (fromEnd == 2) return "Cuartos de final";
  if (fromEnd == 3) return "Octavos de final";
  return "Llave de ${1 << (fromEnd + 1)}";
}

/// Sin podio: el título celebra hasta dónde llegó, no el número de lugar.
String _achievementTitle(Map<String, dynamic> c) {
  final round = (c["reached_round"] as num?)?.toInt();
  final total = (c["total_rounds"] as num?)?.toInt();
  if (round == null || total == null) return "¡Completaste la fase de grupos!";
  if (round == 0) return "¡Jugaste la pre-llave!";
  final label = _roundLabel(round, total);
  return label.startsWith("Llave")
      ? "¡Llegaste a la ${label.toLowerCase()}!"
      : "¡Llegaste a ${label.toLowerCase()}!";
}

String _placeLabel(int p) => p == 1
    ? "Campeón"
    : p == 2
    ? "Subcampeón"
    : "$p° lugar";

class _CelebrationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const _CelebrationDialog({required this.items});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  final _pager = PageController();
  int _index = 0;
  bool _animDone = false;

  bool get _multi => widget.items.length > 1;
  int get _pages => widget.items.length + (_multi ? 1 : 0);
  bool get _onSummary => _multi && _index == widget.items.length;

  void _go(int to) {
    if (to < 0 || to >= _pages) return;
    _pager.animateToPage(
      to,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final champion =
        !_onSummary && (widget.items[_index]["position"] as num).toInt() == 1;
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: size.height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scorifyCardFill,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: champion
                                  ? const [
                                      Color(0xFF8A5C12),
                                      Color(0xFFFFD479),
                                      Color(0xFF8A5C12),
                                    ]
                                  : const [
                                      AppColors.scorifyButterfly,
                                      AppColors.scorifyMint,
                                    ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 430,
                          child: PageView(
                            controller: _pager,
                            onPageChanged: (i) => setState(() {
                              if (i != 0) _animDone = true;
                              _index = i;
                            }),
                            children: [
                              for (final c in widget.items)
                                _ResultPage(data: c),
                              if (_multi) _SummaryPage(items: widget.items),
                            ],
                          ),
                        ),
                        if (_multi)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _index == 0
                                    ? null
                                    : () => _go(_index - 1),
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: _index == 0
                                      ? Colors.transparent
                                      : AppColors.scorifyTextMuted,
                                ),
                              ),
                              for (var i = 0; i < _pages; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: i == _index ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: i == _index
                                        ? AppColors.scorifyMint
                                        : Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              IconButton(
                                onPressed: _index == _pages - 1
                                    ? null
                                    : () => _go(_index + 1),
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: _index == _pages - 1
                                      ? Colors.transparent
                                      : AppColors.scorifyTextMuted,
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.scorifyButterfly,
                                    foregroundColor:
                                        AppColors.scorifyOnButterfly,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    _onSummary || !_multi
                                        ? "¡Listo!"
                                        : "¡Genial!",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              if (_multi && !_onSummary)
                                TextButton(
                                  onPressed: () => _go(widget.items.length),
                                  child: const Text(
                                    "Ver resumen",
                                    style: TextStyle(
                                      color: AppColors.scorifyTextMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.scorifyTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Serpentina cayendo por toda la pantalla (solo en el primer
        // resultado), encima de la ventana y sin bloquear los toques.
        if (_index == 0 && !_animDone)
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.network(
                "${AppConfig.webBaseUrl}/celebration/celebration.json",
                repeat: false,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultPage({required this.data});

  static const _tone = {1: _gold, 2: Color(0xFFB9C4CA), 3: Color(0xFFD8925A)};

  @override
  Widget build(BuildContext context) {
    final position = (data["position"] as num?)?.toInt() ?? 0;
    final podiumPlace = position <= 3;
    final podium =
        ((data["podium"] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => (a["position"] as num).compareTo(b["position"] as num),
          );
    var (title, sub) = _headline(position);
    if (!podiumPlace) {
      title = _achievementTitle(data);
      sub = "$position° lugar en la categoría";
    }
    final points = (data["ranking_points"] as num?)?.toInt() ?? 0;
    final wins = (data["matches_won"] as num?)?.toInt() ?? 0;

    Widget chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    // Mismo lenguaje que el resto de la app: título de sección con barrita y
    // filas como el ranking (sin bordes en los avatares, sin brillos).
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        children: [
          _MedalBadge(position: position, size: 92),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: position == 1 ? _gold : AppColors.scorifyText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.scorifyTextMuted,
              fontSize: 13,
            ),
          ),
          if (points > 0 || wins > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (points > 0)
                  chip("+$points pts de ranking", AppColors.scorifyButterfly),
                if (wins > 0)
                  chip(
                    "$wins ${wins == 1 ? "partido ganado" : "partidos ganados"}",
                    AppColors.scorifyMint,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 12),
          Text(
            (data["tournament_name"] ?? "").toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.scorifyText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            (data["category_label"] ?? "").toString(),
            style: const TextStyle(
              color: AppColors.scorifyTextMuted,
              fontSize: 12,
            ),
          ),
          if (podium.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.scorifyMint,
                    borderRadius: BorderRadius.circular(Panel.radius),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "PODIO",
                  style: TextStyle(
                    color: AppColors.scorifyTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final p in podium)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _MedalBadge(
                      position: (p["position"] as num).toInt(),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    UserAvatar(
                      userId: p["id_user"].toString(),
                      url: p["avatar_url"] as String?,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p["name"].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.scorifyText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _placeLabel((p["position"] as num).toInt()),
                            style: TextStyle(
                              color:
                                  _tone[(p["position"] as num).toInt()] ??
                                  AppColors.scorifyTextMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _SummaryPage({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
      child: Column(
        children: [
          const Text(
            "Tus resultados",
            style: TextStyle(
              color: AppColors.scorifyText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Terminaron ${items.length} campeonatos en los que jugaste",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.scorifyTextMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scorifySurface2.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(Panel.radius),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                itemBuilder: (_, i) {
                  final c = items[i];
                  final p = (c["position"] as num).toInt();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _MedalBadge(position: p, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _placeLabel(p),
                                      style: TextStyle(
                                        color: p == 1
                                            ? _gold
                                            : AppColors.scorifyText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (((c["ranking_points"] as num?) ?? 0) >
                                        0)
                                      TextSpan(
                                        text: "  +${c["ranking_points"]} pts",
                                        style: const TextStyle(
                                          color: AppColors.scorifyButterfly,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                "${c["tournament_name"]} · ${c["category_label"]}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.scorifyTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
