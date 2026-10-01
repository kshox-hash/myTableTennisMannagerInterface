import "package:flutter/material.dart";
import "package:myttmi/core/live/live_refresh.dart";
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

class _TournamentPlayersScreenState extends State<TournamentPlayersScreen> with LiveRefreshMixin<TournamentPlayersScreen> {
  // Se actualiza solo (cada 30 s, al llegar una notificación o al volver a la app).
  @override
  void onLiveRefresh() => _reload();

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
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (groupsGenerated) ...[
                            Material(
                              color: AppColors.scorifyMint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: _goGroups,
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: const BoxDecoration(color: AppColors.scorifyMint, shape: BoxShape.circle),
                                        child: const Icon(Icons.groups_rounded, color: AppColors.scorifyOnMint, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Los grupos ya se armaron",
                                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                                            SizedBox(height: 2),
                                            Text("Toca para ver los grupos y la llave",
                                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyMint),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          for (final cat in categories) ...[
                            _CategoryPlayers(
                              label: cat,
                              players: byCategory[cat]!..sort((a, b) => a.playerName.compareTo(b.playerName)),
                            ),
                            const SizedBox(height: 14),
                          ],
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

/// Categoría con sus inscritos: encabezado con el total y una fila por
/// jugador (avatar recortado en círculo, nombre, club y "ver perfil").
class _CategoryPlayers extends StatefulWidget {
  final String label;
  final List<TournamentParticipant> players;
  const _CategoryPlayers({required this.label, required this.players});

  @override
  State<_CategoryPlayers> createState() => _CategoryPlayersState();
}

class _CategoryPlayersState extends State<_CategoryPlayers> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final players = widget.players;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.label,
                        style: const TextStyle(fontFamily: AppTypography.body, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(999)),
                    child: Text("${players.length} inscritos",
                        style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                  ),
                  const SizedBox(width: 6),
                  Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.scorifyMint),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < players.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.playerProfile,
                  arguments: {"userId": players[i].idUser, "playerName": players[i].playerName},
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text("${i + 1}",
                            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
                      ),
                      ClipOval(child: Identicon(seed: players[i].idUser, size: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(players[i].playerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                            Text((players[i].clubName ?? "").trim().isEmpty ? "Sin club" : players[i].clubName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.visibility_outlined, size: 19, color: AppColors.scorifyMint),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
