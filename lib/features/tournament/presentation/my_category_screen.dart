import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/match_history_row.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/section_header.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/routes/app_routes.dart";

const Map<String, String> _phaseLabel = {
  "enrollment": "Inscripción",
  "groups": "Grupos",
  "bracket": "Llaves",
  "finished": "Finalizado",
};

const _playedStatuses = {"played", "walkover"};

class _CategoryData {
  final PlayerCategoryView view;
  final CategoryStandings generalStandings;
  final String? myUserId;
  _CategoryData({
    required this.view,
    required this.generalStandings,
    this.myUserId,
  });
}

class MyCategoryScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String categoryId;
  final String categoryLabel;

  const MyCategoryScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryId,
    required this.categoryLabel,
  });

  @override
  State<MyCategoryScreen> createState() => _MyCategoryScreenState();
}

class _MyCategoryScreenState extends State<MyCategoryScreen> {
  final _api = PlayerApi();
  late Future<_CategoryData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetchAll();
    });
  }

  Future<_CategoryData> _fetchAll() async {
    final results = await Future.wait([
      _api.getCategoryView(widget.tournamentId, widget.categoryId),
      _api.getCategoryStandings(widget.tournamentId, widget.categoryId),
      SessionStorage().getUserId(),
    ]);
    return _CategoryData(
      view: results[0] as PlayerCategoryView,
      generalStandings: results[1] as CategoryStandings,
      myUserId: results[2] as String?,
    );
  }

  void _goMatchTyped(PlayerMatch m, String type) {
    Navigator.pushNamed(
      context,
      AppRoutes.matchDetail,
      arguments: {"matchType": type, "matchId": m.idMatch},
    );
  }

  // El detalle de grupos y la llave completa del torneo ya se ven en
  // "Partidos" (con todas las categorías) — desde acá solo saltamos directo
  // a la pestaña correcta en vez de repetir esos datos en esta pantalla.
  void _goViewMore(String phase) {
    final toBracket = phase == "bracket" || phase == "finished";
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentMatches,
      arguments: {
        "tournamentId": widget.tournamentId,
        "tournamentName": widget.tournamentName,
        "initialMode": toBracket ? "bracket" : "groups",
      },
    );
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
                TopHeader(title: widget.categoryLabel),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<_CategoryData>(
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
                                    "No pudimos cargar la categoría.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final data = snap.data!;
                        final view = data.view;
                        final isEnrolled =
                            view.myGroupName != null ||
                            view.myGroupMatches.isNotEmpty ||
                            view.myBracketMatches.isNotEmpty;
                        final generalStandings =
                            data.generalStandings.standings;

                        // Grupo + llave combinados, cada uno con su tipo (para el
                        // link al detalle) — separados por jugado/pendiente en vez
                        // de una sola lista mezclada.
                        final allMatches = [
                          for (final m in view.myGroupMatches)
                            (match: m, type: "group"),
                          for (final m in view.myBracketMatches)
                            (match: m, type: "bracket"),
                        ];
                        final results = allMatches
                            .where(
                              (t) => _playedStatuses.contains(t.match.status),
                            )
                            .toList();
                        final upcoming = allMatches
                            .where(
                              (t) => !_playedStatuses.contains(t.match.status),
                            )
                            .toList();

                        final isEmpty =
                            generalStandings.isEmpty && allMatches.isEmpty;

                        return ListView(
                          children: [
                            Row(
                              children: [
                                InfoChip(
                                  label: _phaseLabel[view.phase] ?? view.phase,
                                  tone: ChipTone.positive,
                                ),
                                if (view.myGroupName != null) ...[
                                  const SizedBox(width: 8),
                                  InfoChip(label: "Grupo ${view.myGroupName}"),
                                ],
                                if (!isEnrolled) ...[
                                  const SizedBox(width: 8),
                                  const InfoChip(
                                    label: "Viendo como espectador",
                                  ),
                                ],
                              ],
                            ),

                            if (generalStandings.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              SectionHeader(
                                title: data.generalStandings.source == "bracket"
                                    ? "Posiciones finales"
                                    : "Tabla general",
                              ),
                              const SizedBox(height: 10),
                              _GeneralStandingsList(
                                standings: generalStandings,
                                myUserId: data.myUserId,
                              ),
                            ],

                            if (view.phase != "enrollment") ...[
                              const SizedBox(height: 22),
                              GlassCard(
                                onTap: () => _goViewMore(view.phase),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_tree_outlined,
                                      color: AppColors.scorifyMint,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        view.phase == "groups"
                                            ? "Ver todos los grupos"
                                            : "Ver llave completa",
                                        style: AppTypography.h2,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.scorifyTextFaint,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (results.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              SectionHeader(
                                title: "Resultados (${results.length})",
                              ),
                              const SizedBox(height: 10),
                              ...results.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _matchTile(
                                    t.match,
                                    t.type,
                                    () => _goMatchTyped(t.match, t.type),
                                  ),
                                ),
                              ),
                            ],

                            if (upcoming.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              const SectionHeader(title: "Próximos partidos"),
                              const SizedBox(height: 10),
                              ...upcoming.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _matchTile(
                                    t.match,
                                    t.type,
                                    () => _goMatchTyped(t.match, t.type),
                                  ),
                                ),
                              ),
                            ],

                            if (isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: EmptyState(
                                  icon: Icons.groups_outlined,
                                  message:
                                      "Todavía no hay grupos ni llave para esta categoría.",
                                ),
                              ),
                          ],
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

class _GeneralStandingsList extends StatelessWidget {
  final List<CategoryStandingRow> standings;
  final String? myUserId;
  const _GeneralStandingsList({required this.standings, this.myUserId});

  @override
  Widget build(BuildContext context) {
    final sorted = standings.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: sorted.map((s) {
          final isMe = s.idUser == myUserId;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.scorifyMint.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.position == 1
                        ? AppColors.scorifyMint
                        : Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${s.position}",
                    style: AppTypography.mono14.copyWith(
                      fontWeight: FontWeight.w700,
                      color: s.position == 1
                          ? AppColors.scorifyOnMint
                          : AppColors.scorifyText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.playerName,
                        style: isMe ? AppTypography.h2 : AppTypography.bodyText,
                      ),
                      if (s.clubName != null)
                        Text(s.clubName!, style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
                if (s.position == 1)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.scorifyMint,
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _matchTile(PlayerMatch match, String type, VoidCallback onTap) {
  final played = _playedStatuses.contains(match.status);
  final iWon =
      played &&
      match.winnerId != null &&
      (match.mySlot == "player1"
          ? match.setsPlayer1 > match.setsPlayer2
          : match.setsPlayer2 > match.setsPlayer1);

  return MatchHistoryRow(
    opponentName: match.opponentName ?? "Vacante",
    opponentId: match.opponentId,
    meta: [
      type == "bracket" ? "Llave" : "Grupo",
      if (match.round != null) matchRoundLabel(match.round!),
      matchStatusLabel[match.status] ?? match.status,
      if (match.tableNumber != null) "Mesa ${match.tableNumber}",
    ].join(" · "),
    won: played ? iWon : null,
    scoreText: played ? "${match.setsPlayer1}-${match.setsPlayer2}" : null,
    onTap: onTap,
  );
}
