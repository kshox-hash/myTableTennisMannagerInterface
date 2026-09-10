import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/match_history_row.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = PlayerApi();
  Future<List<PlayerMatchHistoryItem>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await SessionStorage().getUserId();
    if (userId == null || userId.isEmpty) {
      setState(() {
        _future = Future.value([]);
      });
      return;
    }
    setState(() {
      _future = _api.getPlayerMatchHistory(userId, limit: 50);
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
                const TopHeader(title: "Historial"),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _load,
                    child: FutureBuilder<List<PlayerMatchHistoryItem>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const LoadingState();
                        }
                        if (snap.hasError) {
                          return ListView(
                            children: [
                              ErrorStateView(
                                message:
                                    "No pudimos cargar tu historial.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final items = snap.data ?? [];
                        if (items.isEmpty) {
                          return ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: EmptyState(
                                  icon: Icons.history_rounded,
                                  message: "Todavía no jugaste ningún partido.",
                                ),
                              ),
                            ],
                          );
                        }

                        return FutureBuilder<String?>(
                          future: SessionStorage().getUserId(),
                          builder: (context, userSnap) {
                            final myId = userSnap.data;
                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final m = items[i];
                                final isP1 = m.player1Id == myId;
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
                                final won = myId != null && m.winnerId == myId;

                                return MatchHistoryRow(
                                  opponentName: "vs $opponent",
                                  opponentId: opponentId,
                                  meta: [
                                    m.tournamentName,
                                    m.categoryLabel,
                                    if (m.groupName != null)
                                      "Grupo ${m.groupName}",
                                    if (m.round != null)
                                      matchRoundLabel(m.round!),
                                    matchStatusLabel[m.status] ?? m.status,
                                  ].join(" · "),
                                  won: won,
                                  scoreText: "$mySets-$oppSets",
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
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
