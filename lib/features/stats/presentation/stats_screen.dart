import 'package:myttmi/core/ui/stagger_in.dart';
import 'package:myttmi/core/ui/stat_gauge.dart';
import 'package:myttmi/core/ui/glass_card.dart';
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

  const StatsScreen({super.key, this.showHeader = true});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TabAutoRefreshMixin<StatsScreen> {
  @override
  int get tabIndex => 2;

  @override
  void onTabActivated() => _load();

  final _profileApi = ProfileApi();
  final _playerApi = PlayerApi();

  PlayerStats? _stats;
  String? _myId;
  // Partidos terminados, del más reciente al más antiguo.
  List<PlayerMatchHistoryItem> _recent = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myId = await SessionStorage().getUserId();
      final results = await Future.wait([
        _profileApi.getStats(),
        if (myId != null) _playerApi.getPlayerMatchHistory(myId, limit: 15),
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
      if (mounted) setState(() => _loading = false);
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
    final s = _stats;
    final played = s?.matchesPlayed ?? 0;
    final won = s?.matchesWon ?? 0;
    final lost = s?.matchesLost ?? (played - won).clamp(0, 1 << 30);
    final rate = played == 0 ? 0.0 : won / played;
    final setsWon = s?.setsWon ?? 0;
    final setsLost = s?.setsLost ?? 0;
    final streak = _streak;
    final form = _recent.take(5).toList().reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          if (widget.showHeader) ...[
            const TopHeader(title: "Estadísticas", showBack: false),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _loading
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
                            // ── Efectividad + racha ──
                            GlassCard(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                              child: Row(
                                children: [
                                  StatGauge(
                                    fraction: played == 0 ? 0 : rate,
                                    value: played == 0 ? "—" : "${(rate * 100).round()}%",
                                    caption: "Victorias",
                                    size: 100,
                                    stroke: 6,
                                    open: false,
                                    valueSize: 24,
                                  ),
                                  Container(width: 1, height: 84, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.local_fire_department_rounded, size: 18, color: _fire),
                                            SizedBox(width: 6),
                                            Text("RACHA ACTUAL", style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: AppColors.scorifyTextMuted)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (streak == null)
                                          const Text("Sin partidos aún", style: TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.scorifyText))
                                        else
                                          Row(
                                            children: [
                                              Text("${streak.$1}",
                                                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 42, height: 1.0, fontWeight: FontWeight.w700, color: streak.$2 ? _fire : AppColors.scorifyNegative)),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  streak.$2
                                                      ? (streak.$1 == 1 ? "victoria" : "victorias\nseguidas")
                                                      : (streak.$1 == 1 ? "derrota" : "derrotas\nseguidas"),
                                                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, height: 1.15, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (form.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              for (final m in form) ...[
                                                _FormDot(won: _won(m)),
                                                const SizedBox(width: 5),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Indicadores: mini medidores (turquesa; derrotas en rojo) ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                StatGauge(fraction: played == 0 ? 0 : 1, value: "$played", label: "Partidos"),
                                StatGauge(fraction: played == 0 ? 0 : won / played, value: "$won", label: "Victorias"),
                                StatGauge(fraction: played == 0 ? 0 : lost / played, value: "$lost", label: "Derrotas", color: AppColors.scorifyNegative),
                                StatGauge(
                                  fraction: setsWon + setsLost == 0 ? 0 : setsWon / (setsWon + setsLost),
                                  value: setsWon + setsLost == 0 ? "—" : "${(setsWon * 100 / (setsWon + setsLost)).round()}%",
                                  label: "Sets",
                                ),
                              ],
                            ),

                            // ── Sets ──
                            const SizedBox(height: 22),
                            SectionCard(
                              title: "Sets",
                              icon: Icons.scoreboard_rounded,
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: _BigNumber(value: "$setsWon", label: "Ganados", color: AppColors.scorifyText)),
                                      Column(
                                        children: [
                                          const Text("DIFERENCIA", style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: AppColors.scorifyTextMuted)),
                                          Text(
                                            "${setsWon - setsLost >= 0 ? "+" : ""}${setsWon - setsLost}",
                                            style: TextStyle(
                                              fontFamily: AppTypography.body,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: setsWon >= setsLost ? AppColors.scorifyButterfly : AppColors.scorifyNegative,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(child: _BigNumber(value: "$setsLost", label: "Perdidos", color: AppColors.scorifyNegative, alignEnd: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: SizedBox(
                                      height: 5,
                                      child: setsWon + setsLost == 0
                                          ? Container(color: AppColors.scorifySurface2)
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
                            const SizedBox(height: 22),
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
                                  ? const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: AppColors.scorifyMint, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(child: Text("Todavía no has jugado ningún partido. Tus números aparecen aquí apenas juegues el primero.", style: _muted)),
                                  ],
                                )
                                  : Column(
                                      children: dividedRows([for (final m in _recent.take(5)) _RecentRow(match: m, myId: _myId ?? "")]),
                                    ),
                            ),
                          ]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FormDot extends StatelessWidget {
  final bool won;
  const _FormDot({required this.won});

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: won ? AppColors.scorifyButterfly : AppColors.scorifyNegative,
          shape: BoxShape.circle,
        ),
        child: Icon(won ? Icons.check_rounded : Icons.close_rounded, size: 15, color: won ? AppColors.scorifyOnButterfly : Colors.white),
      );
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
          Text(value, style: TextStyle(fontFamily: AppTypography.body, fontSize: 28, fontWeight: FontWeight.w600, color: color)),
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
      borderRadius: BorderRadius.circular(2),
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: won ? AppColors.scorifyButterfly : AppColors.scorifyNegative),
            ),
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
            Text("$mine - $theirs",
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
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

String _date(String? iso) {
  const months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  final d = DateTime.tryParse(iso ?? "")?.toLocal();
  return d == null ? "" : "${d.day} ${months[d.month - 1]}";
}

