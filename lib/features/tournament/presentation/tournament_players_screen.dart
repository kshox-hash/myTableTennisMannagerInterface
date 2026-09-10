import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/routes/app_routes.dart";

class _PlayersData {
  final List<TournamentParticipant> participants;
  // Si ya hay partidos de grupo/llave generados, los inscritos ya se pueden
  // ver organizados en "Partidos" — evitamos repetir esa lista acá.
  final bool groupsGenerated;
  _PlayersData({required this.participants, required this.groupsGenerated});
}

class TournamentPlayersScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentPlayersScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentPlayersScreen> createState() =>
      _TournamentPlayersScreenState();
}

class _TournamentPlayersScreenState extends State<TournamentPlayersScreen> {
  final _api = PlayerApi();
  late Future<_PlayersData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAll();
  }

  Future<_PlayersData> _fetchAll() async {
    final results = await Future.wait([
      _api.getTournamentParticipants(widget.tournamentId),
      _api.getTournamentMatches(widget.tournamentId),
    ]);
    final participants = results[0] as List<TournamentParticipant>;
    final matches = results[1] as List<dynamic>;
    return _PlayersData(
      participants: participants,
      groupsGenerated: matches.isNotEmpty,
    );
  }

  void _reload() {
    setState(() {
      _future = _fetchAll();
    });
  }

  void _goGroups() {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentMatches,
      arguments: {
        "tournamentId": widget.tournamentId,
        "tournamentName": widget.tournamentName,
        "initialMode": "groups",
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
                TopHeader(title: widget.tournamentName, subtitle: "Inscritos"),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<_PlayersData>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const LoadingState();
                      }
                      if (snap.hasError) {
                        return ErrorStateView(
                          message:
                              "No pudimos cargar los inscritos.\n${snap.error}",
                          onRetry: _reload,
                        );
                      }

                      final players = snap.data?.participants ?? [];
                      final groupsGenerated =
                          snap.data?.groupsGenerated ?? false;
                      if (players.isEmpty) {
                        return const EmptyState(
                          icon: Icons.people_outline_rounded,
                          message: "Todavía no hay inscritos.",
                        );
                      }

                      final byCategory =
                          <String, List<TournamentParticipant>>{};
                      for (final p in players) {
                        byCategory
                            .putIfAbsent(p.categoryLabel, () => [])
                            .add(p);
                      }
                      final categories = byCategory.keys.toList()..sort();

                      return ListView(
                        children: [
                          if (groupsGenerated) ...[
                            GlassCard(
                              borderColor: AppColors.scorifyMint.withOpacity(
                                0.45,
                              ),
                              onTap: _goGroups,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    color: AppColors.scorifyMint,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Los grupos ya se armaron",
                                          style: AppTypography.h2,
                                        ),
                                        Text(
                                          "Toca para ver grupos y llave",
                                          style: AppTypography.bodyMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.scorifyTextFaint,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          ...categories.map((cat) {
                            final list = byCategory[cat]!
                              ..sort(
                                (a, b) => a.playerName.compareTo(b.playerName),
                              );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  backgroundColor: AppColors.scorifyCardFill,
                                  collapsedBackgroundColor:
                                      AppColors.scorifyCardFill,
                                  iconColor: AppColors.scorifyMint,
                                  collapsedIconColor:
                                      AppColors.scorifyTextMuted,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(
                                      color: AppColors.scorifyCardBorder,
                                    ),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(
                                      color: AppColors.scorifyCardBorder,
                                    ),
                                  ),
                                  title: Text(cat, style: AppTypography.h1),
                                  subtitle: Text(
                                    "${list.length} inscritos",
                                    style: AppTypography.bodyMuted,
                                  ),
                                  children: list.map((p) {
                                    return ListTile(
                                      dense: true,
                                      leading: Identicon(
                                        seed: p.idUser,
                                        size: 40,
                                      ),
                                      title: Text(
                                        p.playerName,
                                        style: AppTypography.bodyText,
                                      ),
                                      subtitle: p.clubName != null
                                          ? Text(
                                              p.clubName!,
                                              style: AppTypography.bodyMuted,
                                            )
                                          : null,
                                      trailing: Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.scorifyTextFaint,
                                      ),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.playerProfile,
                                        arguments: {
                                          "userId": p.idUser,
                                          "playerName": p.playerName,
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          }),
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
