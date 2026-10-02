import 'package:myttmi/core/ui/stagger_in.dart';
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
import 'package:myttmi/features/ranking/api/ranking_api.dart';
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
  final _rankingApi = RankingApi();
  final _playerApi = PlayerApi();

  PlayerStats? _stats;
  int? _myRankingPosition;
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
        _rankingApi.getGlobal(),
        if (myId != null) _playerApi.getPlayerMatchHistory(myId, limit: 15),
      ]);
      if (!mounted) return;
      final ranking = results[1] as List;
      final mine = ranking.cast<dynamic>().where((r) => r.idUser == myId).toList();
      final history = results.length > 2 ? results[2] as List<PlayerMatchHistoryItem> : <PlayerMatchHistoryItem>[];
      setState(() {
        _stats = results[0] as PlayerStats;
        _myId = myId;
        _myRankingPosition = mine.isNotEmpty ? mine.first.rankingPosition as int : null;
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
                            SectionCard(
                              title: "Tu forma",
                              icon: Icons.local_fire_department_rounded,
                              titleColor: AppColors.scorifyMint,
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _Ring(rate: rate, empty: played == 0),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              streak == null
                                                  ? "Sin partidos aún"
                                                  : streak.$2
                                                      ? (streak.$1 == 1 ? "Ganaste el último" : "${streak.$1} victorias seguidas")
                                                      : (streak.$1 == 1 ? "Perdiste el último" : "${streak.$1} derrotas seguidas"),
                                              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                                            ),
                                            const SizedBox(height: 10),
                                            if (form.isEmpty)
                                              const Text("Juega tu primer partido para ver tu racha.", style: _muted)
                                            else
                                              Row(
                                                children: [
                                                  for (final m in form) ...[
                                                    _FormDot(won: _won(m)),
                                                    const SizedBox(width: 6),
                                                  ],
                                                ],
                                              ),
                                            if (form.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              const Text("Últimos 5 · el más reciente a la derecha", style: TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w400, color: AppColors.scorifyTextFaint)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Indicadores ──
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.1,
                              children: [
                                _Kpi(icon: Icons.sports_tennis_rounded, label: "Partidos", value: "$played", color: AppColors.scorifyMint),
                                _Kpi(icon: Icons.emoji_events_rounded, label: "Victorias", value: "$won", color: AppColors.scorifyButterfly),
                                _Kpi(icon: Icons.close_rounded, label: "Derrotas", value: "$lost", color: AppColors.scorifyNegative),
                                _Kpi(
                                  icon: Icons.leaderboard_rounded,
                                  label: "Ranking",
                                  value: _myRankingPosition != null ? "#$_myRankingPosition" : "—",
                                  color: AppColors.scorifyPending,
                                ),
                              ],
                            ),

                            // ── Sets ──
                            const SizedBox(height: 22),
                            SectionCard(
                              title: "Sets",
                              icon: Icons.scoreboard_outlined,
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: _BigNumber(value: "$setsWon", label: "Ganados", color: AppColors.scorifyButterfly)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(999)),
                                        child: Text(
                                          "Diferencia ${setsWon - setsLost >= 0 ? "+" : ""}${setsWon - setsLost}",
                                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                                        ),
                                      ),
                                      Expanded(child: _BigNumber(value: "$setsLost", label: "Perdidos", color: AppColors.scorifyNegative, alignEnd: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: SizedBox(
                                      height: 8,
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

class _Ring extends StatelessWidget {
  final double rate;
  final bool empty;
  const _Ring({required this.rate, required this.empty});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: empty ? 0 : rate.clamp(0.0, 1.0),
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.scorifySurface2,
              color: AppColors.scorifyButterfly,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(empty ? "—" : "${(rate * 100).round()}%",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 23, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
              Text("Efectividad", style: _muted.copyWith(fontSize: 10.5)),
            ],
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

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Kpi({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                Text(label, style: _muted.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: won ? AppColors.scorifyButterfly : AppColors.scorifyNegative.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(won ? "G" : "P",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: won ? AppColors.scorifyOnButterfly : AppColors.scorifyNegative)),
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
                  Text("${m.tournamentName} · $cat", maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text("$mine - $theirs",
                style: TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: won ? AppColors.scorifyButterfly : AppColors.scorifyText)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.scorifyTextFaint),
          ],
        ),
      ),
    );
  }
}
