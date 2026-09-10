import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/glass_card.dart';
import 'package:myttmi/core/ui/list_states.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/ranking/api/ranking_api.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';

class StatsScreen extends StatefulWidget {
  // false cuando vive embebido dentro de una sub-pestaña (p.ej. "Mi
  // rendimiento") que ya muestra su propio encabezado.
  final bool showHeader;

  const StatsScreen({super.key, this.showHeader = true});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with TabAutoRefreshMixin<StatsScreen> {
  @override
  int get tabIndex => 2;

  @override
  void onTabActivated() => _load();

  final _profileApi = ProfileApi();
  final _rankingApi = RankingApi();

  PlayerStats? _stats;
  int? _myRankingPosition;
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
      final results = await Future.wait([
        _profileApi.getStats(),
        _rankingApi.getGlobal(),
        SessionStorage().getUserId(),
      ]);
      if (!mounted) return;
      final stats = results[0] as PlayerStats;
      final ranking = results[1] as List;
      final myId = results[2] as String?;
      final mine = ranking
          .cast<dynamic>()
          .where((r) => r.idUser == myId)
          .toList();
      setState(() {
        _stats = stats;
        _myRankingPosition = mine.isNotEmpty
            ? mine.first.rankingPosition as int
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                ? ErrorStateView(
                    message: "No pudimos cargar tus estadísticas.\n$_error",
                    onRetry: _load,
                  )
                : RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _load,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatKpi(
                                label: "Partidos",
                                value: "${_stats?.matchesPlayed ?? 0}",
                                icon: Icons.sports_tennis_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatKpi(
                                label: "Victorias",
                                value: "${_stats?.matchesWon ?? 0}",
                                icon: Icons.emoji_events_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatKpi(
                                label: "Win rate",
                                value:
                                    "${((_stats?.winRate ?? 0) * 100).round()}%",
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatKpi(
                                label: "Ranking",
                                value: _myRankingPosition != null
                                    ? "#$_myRankingPosition"
                                    : "—",
                                icon: Icons.leaderboard_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text("Sets", style: AppTypography.h2),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "${_stats?.setsWon ?? 0}",
                                      style: AppTypography.displayMd.copyWith(
                                        color: AppColors.scorifyMint,
                                      ),
                                    ),
                                    Text(
                                      "Ganados",
                                      style: AppTypography.bodyMuted,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.10),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "${_stats?.setsLost ?? 0}",
                                      style: AppTypography.displayMd.copyWith(
                                        color: AppColors.scorifyNegative,
                                      ),
                                    ),
                                    Text(
                                      "Perdidos",
                                      style: AppTypography.bodyMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((_stats?.matchesPlayed ?? 0) == 0) ...[
                          const SizedBox(height: 24),
                          const EmptyState(
                            icon: Icons.sports_tennis_rounded,
                            message: "Todavía no jugaste ningún partido.",
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatKpi({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scorifyMint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.scorifyCardBorder),
            ),
            child: Icon(icon, color: AppColors.scorifyMint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyMuted),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.monoStrong.copyWith(
                    fontSize: 18,
                    color: AppColors.scorifyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
