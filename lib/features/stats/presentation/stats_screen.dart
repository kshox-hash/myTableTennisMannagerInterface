import 'package:myttmi/core/ui/panel_style.dart';
import 'package:myttmi/core/ui/page_skeleton.dart';
import 'package:myttmi/core/ui/stagger_in.dart';
import 'package:myttmi/core/ui/stat_gauge.dart';
import 'package:myttmi/core/ui/section_card.dart';
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/list_states.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/features/player/models/tournament_match_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';
import 'package:myttmi/routes/app_routes.dart';

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  color: AppColors.scorifyTextMuted,
);

class StatsScreen extends StatefulWidget {
  // false cuando vive embebido dentro de una sub-pestaña (p.ej. "Mi
  // rendimiento") que ya muestra su propio encabezado.
  final bool showHeader;
  /// Avisa cuando terminó la primera carga ("Mi rendimiento" muestra el
  /// esqueleto de pestaña completa hasta entonces).
  final VoidCallback? onLoaded;

  const StatsScreen({super.key, this.showHeader = true, this.onLoaded});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TabAutoRefreshMixin<StatsScreen> {
  @override
  int get tabIndex => 2;

  @override
  // Al volver a la pestaña se actualiza en silencio (sin esqueleto).
  void onTabActivated() => _load(silent: true);

  final _profileApi = ProfileApi();
  final _playerApi = PlayerApi();

  PlayerStats? _stats;
  String? _myId;
  // Partidos terminados, del más reciente al más antiguo.
  List<PlayerMatchHistoryItem> _recent = [];
  bool _loading = true;
  // Primera carga: esqueleto de la página entera (después, recargas en silencio).
  bool _loadedOnce = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });
    try {
      final myId = await SessionStorage().getUserId();
      final results = await Future.wait([
        _profileApi.getStats(),
        // 200: alcanza para el gráfico de los últimos 6 meses.
        if (myId != null) _playerApi.getPlayerMatchHistory(myId, limit: 200),
      ]);
      if (!mounted) return;
      final history = results.length > 1 ? results[1] as List<PlayerMatchHistoryItem> : <PlayerMatchHistoryItem>[];
      setState(() {
        _stats = results[0] as PlayerStats;
        _myId = myId;
        _recent = history.where((m) => m.status == "played" || m.status == "walkover").toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadedOnce = true;
        });
      }
      widget.onLoaded?.call();
    }
  }

  bool _won(PlayerMatchHistoryItem m) => m.winnerId != null && m.winnerId == _myId;

  // Racha actual: cuántos resultados iguales seguidos desde el más reciente.
  (int, bool)? get _streak {
    if (_recent.isEmpty) return null;
    final first = _won(_recent.first);
    var n = 0;
    for (final m in _recent) {
      if (_won(m) != first) break;
      n++;
    }
    return (n, first);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedOnce) return const PageSkeleton();
    final s = _stats;
    final played = s?.matchesPlayed ?? 0;
    final won = s?.matchesWon ?? 0;
    final lost = s?.matchesLost ?? (played - won).clamp(0, 1 << 30);
    final rate = played == 0 ? 0.0 : won / played;
    final setsWon = s?.setsWon ?? 0;
    final setsLost = s?.setsLost ?? 0;
    final sets = setsWon + setsLost;
    final setRate = sets == 0 ? 0.0 : setsWon / sets;
    final streak = _streak;
    final form = _recent.take(5).toList().reversed.toList();
    // "Ganas 7 de cada 10" (un decimal solo si hace falta: 6,5).
    final perTenText = (rate * 10).toStringAsFixed(1).replaceAll(".0", "").replaceAll(".", ",");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ScrollingHeaderPage(
        header: [
          const SizedBox(height: 16),
          if (widget.showHeader) ...[
            const TopHeader(title: "Mi rendimiento", showBack: false),
            const SizedBox(height: 16),
          ],
        ],
        body: _loading
                ? const LoadingState()
                : _error != null
                    ? ErrorStateView(message: "No pudimos cargar tus estadísticas.\n$_error", onRetry: _load)
                    : RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: staggerChildren([
                            // ── Resumen: efectividad grande y los tres totales ──
                            // (antes el % salía dos veces y los mini medidores
                            // flotaban sueltos, sin panel).
                            SectionCard(
                              title: "Resumen",
                              icon: Icons.insights_rounded,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      StatGauge(
                                        fraction: rate,
                                        value: played == 0 ? "—" : "${(rate * 100).round()}%",
                                        caption: "Efectividad",
                                        size: 96,
                                        stroke: 6,
                                        open: false,
                                        valueSize: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              played == 0 ? "Aún no juegas partidos" : "Ganas $perTenText de cada 10 partidos",
                                              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, height: 1.25, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              played == 0 ? "Tus números aparecen apenas juegues el primero." : "Sumando todos tus campeonatos.",
                                              style: _muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _StatBox(value: "$played", label: "Partidos", color: AppColors.scorifyText)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _StatBox(value: "$won", label: "Victorias", color: AppColors.scorifyButterfly)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _StatBox(value: "$lost", label: "Derrotas", color: AppColors.scorifyNegative)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ── Racha y forma: los últimos 5, del más viejo al último ──
                            const SizedBox(height: 14),
                            SectionCard(
                              title: "Racha",
                              icon: Icons.local_fire_department_rounded,
                              titleColor: _fire,
                              padding: const EdgeInsets.all(16),
                              child: streak == null
                                  ? const Text("Juega tu primer partido para empezar una racha.", style: _muted)
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "${streak.$1}",
                                              style: TextStyle(fontFamily: AppTypography.display, fontSize: 54, height: 0.9, fontWeight: FontWeight.w600, color: streak.$2 ? _fire : AppColors.scorifyNegative),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                streak.$2
                                                    ? (streak.$1 == 1 ? "victoria en tu último partido" : "victorias seguidas")
                                                    : (streak.$1 == 1 ? "derrota en tu último partido" : "derrotas seguidas"),
                                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, height: 1.2, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            for (var i = 0; i < form.length; i++) ...[
                                              if (i > 0) const SizedBox(width: 6),
                                              _FormBox(won: _won(form[i])),
                                            ],
                                            const Spacer(),
                                            Text(
                                              form.length == 1 ? "ÚLTIMO PARTIDO" : "ÚLTIMOS ${form.length}",
                                              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.scorifyTextFaint),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),

                            // ── Evolución: partidos por mes, ganados sobre perdidos ──
                            if (_recent.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              SectionCard(
                                title: "Últimos 6 meses",
                                icon: Icons.bar_chart_rounded,
                                trailing: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _LegendDot(color: _chartWon, label: "Ganados"),
                                    SizedBox(width: 10),
                                    _LegendDot(color: _chartLost, label: "Perdidos"),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                                child: _MonthlyChart(matches: _recent, won: _won),
                              ),
                            ],

                            // ── Sets ──
                            const SizedBox(height: 14),
                            SectionCard(
                              title: "Sets",
                              icon: Icons.scoreboard_rounded,
                              trailing: sets == 0 ? null : PanelChip(label: "${(setRate * 100).round()}% ganados", color: AppColors.scorifyButterfly),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: _BigNumber(value: "$setsWon", label: "Ganados", color: AppColors.scorifyButterfly)),
                                      Column(
                                        children: [
                                          Text(
                                            "${setsWon - setsLost >= 0 ? "+" : ""}${setsWon - setsLost}",
                                            style: TextStyle(
                                              fontFamily: AppTypography.display,
                                              fontSize: 30,
                                              height: 1,
                                              fontWeight: FontWeight.w600,
                                              color: setsWon >= setsLost ? AppColors.scorifyText : AppColors.scorifyNegative,
                                            ),
                                          ),
                                          const Text("Diferencia", style: _muted),
                                        ],
                                      ),
                                      Expanded(child: _BigNumber(value: "$setsLost", label: "Perdidos", color: AppColors.scorifyNegative, alignEnd: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Panel.buttonRadius),
                                    child: SizedBox(
                                      height: 6,
                                      child: sets == 0
                                          ? Container(color: Panel.field)
                                          : Row(
                                              children: [
                                                if (setsWon > 0) Expanded(flex: setsWon, child: Container(color: AppColors.scorifyButterfly)),
                                                if (setsWon > 0 && setsLost > 0) const SizedBox(width: 3),
                                                if (setsLost > 0) Expanded(flex: setsLost, child: Container(color: AppColors.scorifyNegative)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Últimos partidos ──
                            const SizedBox(height: 14),
                            SectionCard(
                              title: "Últimos partidos",
                              icon: Icons.history_rounded,
                              trailing: _recent.isEmpty
                                  ? null
                                  : TextButton(
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                                      child: const Text("Ver historial", style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.scorifyMint)),
                                    ),
                              padding: _recent.isEmpty ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: _recent.isEmpty
                                  ? const Text("Todavía no has jugado ningún partido.", style: _muted)
                                  : Column(
                                      children: dividedRows([for (final m in _recent.take(5)) _RecentRow(match: m, myId: _myId ?? "")]),
                                    ),
                            ),
                          ]),
                        ),
                      ),
      ),
    );
  }
}

/// Un total del resumen: número grande (Teko) y su nombre, en caja de panel.
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: panelBox(),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: AppTypography.display, fontSize: 30, height: 1, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.scorifyTextMuted),
            ),
          ],
        ),
      );
}

/// Un resultado: caja cuadrada con G o P y filete del color.
class _FormBox extends StatelessWidget {
  final bool won;
  const _FormBox({required this.won});

  @override
  Widget build(BuildContext context) {
    final c = won ? AppColors.scorifyButterfly : AppColors.scorifyNegative;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: panelBox(color: c),
      child: Text(won ? "G" : "P", style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool alignEnd;
  const _BigNumber({required this.value, required this.label, required this.color, this.alignEnd = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontFamily: AppTypography.display, fontSize: 36, height: 1, fontWeight: FontWeight.w600, color: color)),
          Text(label, style: _muted),
        ],
      );
}

/// Un partido terminado: G/P, rival, torneo y marcador (mis sets primero).
class _RecentRow extends StatelessWidget {
  final PlayerMatchHistoryItem match;
  final String myId;
  const _RecentRow({required this.match, required this.myId});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final iAmP1 = m.player1Id == myId;
    final won = m.winnerId != null && m.winnerId == myId;
    final rival = iAmP1 ? m.player2Name : m.player1Name;
    final mine = iAmP1 ? m.setsPlayer1 : m.setsPlayer2;
    final theirs = iAmP1 ? m.setsPlayer2 : m.setsPlayer1;
    final range = m.categoryRange.trim();
    final cat = range.isEmpty || range == "General" ? m.categoryType : "${m.categoryType} $range";

    return InkWell(
      borderRadius: BorderRadius.circular(Panel.radius),
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            _FormBox(won: won),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("vs $rival",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                  Text([if (_date(m.playedAt).isNotEmpty) _date(m.playedAt), m.tournamentName, cat].join(" · "), maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text("$mine-$theirs",
                style: const TextStyle(fontFamily: AppTypography.display, fontSize: 24, height: 1, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.scorifyTextFaint),
          ],
        ),
      ),
    );
  }
}

/// Racha: naranja de fuego (separa la racha de las victorias, que son verdes).
const _fire = Color(0xFFFFA62B);

// Colores del gráfico: el verde y el rojo de la app, un poco más oscuros y
// separados en luminosidad (validados sobre el fondo de la tarjeta: se
// distinguen también con daltonismo).
const _chartWon = Color(0xFF7EA21F);
const _chartLost = Color(0xFFC23C3C);

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label, style: _muted.copyWith(fontSize: 11)),
        ],
      );
}

/// Barras por mes (los últimos 6, el actual a la derecha): ganados arriba,
/// perdidos abajo, separados por 2 px. Arriba de cada barra, el total; al
/// tocarla, el detalle.
class _MonthlyChart extends StatelessWidget {
  final List<PlayerMatchHistoryItem> matches;
  final bool Function(PlayerMatchHistoryItem) won;
  const _MonthlyChart({required this.matches, required this.won});

  static const _months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
  static const _plotHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)];
    final w = List.filled(6, 0), l = List.filled(6, 0);
    for (final m in matches) {
      final d = DateTime.tryParse(m.playedAt ?? "")?.toLocal();
      if (d == null) continue;
      final i = buckets.indexWhere((b) => b.year == d.year && b.month == d.month);
      if (i < 0) continue;
      won(m) ? w[i]++ : l[i]++;
    }
    final maxTotal = [for (var i = 0; i < 6; i++) w[i] + l[i]].fold<int>(1, (a, b) => b > a ? b : a);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 6; i++)
          Expanded(
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: "${_months[buckets[i].month - 1]}: ${w[i]} ganados · ${l[i]} perdidos",
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    w[i] + l[i] == 0 ? "" : "${w[i] + l[i]}",
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: _plotHeight,
                    width: 22,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (w[i] > 0)
                          Container(
                            height: _plotHeight * w[i] / maxTotal,
                            decoration: const BoxDecoration(
                              color: _chartWon,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        if (w[i] > 0 && l[i] > 0) const SizedBox(height: 2),
                        if (l[i] > 0)
                          Container(
                            height: (_plotHeight * l[i] / maxTotal - (w[i] > 0 ? 2 : 0)).clamp(1.0, _plotHeight),
                            decoration: BoxDecoration(
                              color: _chartLost,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(w[i] == 0 ? 4 : 0)),
                            ),
                          ),
                        // Mes sin partidos: solo la línea de base.
                        if (w[i] + l[i] == 0) Container(height: 2, color: Panel.fieldBorder),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _months[buckets[i].month - 1],
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 11,
                      fontWeight: i == 5 ? FontWeight.w700 : FontWeight.w500,
                      color: i == 5 ? AppColors.scorifyText : AppColors.scorifyTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _date(String? iso) {
  const months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  final d = DateTime.tryParse(iso ?? "")?.toLocal();
  return d == null ? "" : "${d.day} ${months[d.month - 1]}";
}
