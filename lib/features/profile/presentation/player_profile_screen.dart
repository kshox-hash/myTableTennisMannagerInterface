import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/achievement_row.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/match_history_row.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/profile/api/profile_api.dart";
import "package:myttmi/features/profile/models/profile_model.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/achievement_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

class PlayerProfileScreen extends StatefulWidget {
  final String userId;
  final String? playerName;

  const PlayerProfileScreen({super.key, required this.userId, this.playerName});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _profileApi = ProfileApi();
  final _playerApi = PlayerApi();
  late Future<PublicPlayerProfile> _profileFuture;
  late Future<List<PlayerMatchHistoryItem>> _historyFuture;
  late Future<List<PlayerAchievement>> _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileApi.getPublicProfile(widget.userId);
    _historyFuture = _playerApi.getPlayerMatchHistory(widget.userId, limit: 15);
    _achievementsFuture = _playerApi.getPlayerAchievements(widget.userId);
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileApi.getPublicProfile(widget.userId);
      _historyFuture = _playerApi.getPlayerMatchHistory(
        widget.userId,
        limit: 15,
      );
      _achievementsFuture = _playerApi.getPlayerAchievements(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TopHeader(title: widget.playerName ?? "Jugador"),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<PublicPlayerProfile>(
                    future: _profileFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const LoadingState();
                      }
                      if (snap.hasError) {
                        return ErrorStateView(
                          message:
                              "No pudimos cargar este perfil.\n${snap.error}",
                          onRetry: _reload,
                        );
                      }

                      final p = snap.data!;
                      return ListView(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Identicon(seed: p.idUser, size: 76),
                                const SizedBox(height: 12),
                                Text(
                                  p.displayName,
                                  style: AppTypography.h1.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                if (p.club != null)
                                  Text(p.club!, style: AppTypography.bodyMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: "Jugados",
                                  value: "${p.stats.matchesPlayed}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  label: "Ganados",
                                  value: "${p.stats.matchesWon}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  label: "% Victoria",
                                  value: "${(p.stats.winRate * 100).round()}%",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<List<PlayerAchievement>>(
                            future: _achievementsFuture,
                            builder: (context, aSnap) => AchievementsCard(
                              achievements: aSnap.data ?? [],
                            ),
                          ),
                          Text("Historial", style: AppTypography.h1),
                          const SizedBox(height: 10),
                          FutureBuilder<List<PlayerMatchHistoryItem>>(
                            future: _historyFuture,
                            builder: (context, hSnap) {
                              if (hSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const LoadingState();
                              }
                              final items = hSnap.data ?? [];
                              if (items.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.sports_tennis_rounded,
                                  message: "Sin partidos jugados todavía.",
                                );
                              }
                              return Column(
                                children: items.map((m) {
                                  final isP1 = m.player1Id == widget.userId;
                                  final opponent = isP1
                                      ? m.player2Name
                                      : m.player1Name;
                                  final opponentId = isP1
                                      ? m.player2Id
                                      : m.player1Id;
                                  final mySets = isP1
                                      ? m.setsPlayer1
                                      : m.setsPlayer2;
                                  final oppSets = isP1
                                      ? m.setsPlayer2
                                      : m.setsPlayer1;
                                  final won = m.winnerId == widget.userId;
                                  return MatchHistoryRow(
                                    opponentName: "vs $opponent",
                                    opponentId: opponentId,
                                    meta:
                                        "${m.tournamentName} · ${m.categoryLabel} · ${matchStatusLabel[m.status] ?? m.status}",
                                    won: won,
                                    scoreText: "$mySets-$oppSets",
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: AppTypography.monoStrong.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
