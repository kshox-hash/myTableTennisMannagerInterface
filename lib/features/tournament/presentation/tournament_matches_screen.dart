import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/tournament/widget/bracket_tree_view.dart";
import "package:myttmi/features/tournament/widget/group_card.dart";
import "package:myttmi/routes/app_routes.dart";

enum _ViewMode { list, groups, bracket }

class TournamentMatchesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  /// "groups" o "bracket" para abrir directo en esa pestaña (ej. desde el
  /// link de "Resultados"); null usa la lista de partidos por defecto.
  final String? initialMode;

  const TournamentMatchesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.initialMode,
  });

  @override
  State<TournamentMatchesScreen> createState() =>
      _TournamentMatchesScreenState();
}

class _TournamentMatchesScreenState extends State<TournamentMatchesScreen> {
  final _api = PlayerApi();
  late Future<List<TournamentMatch>> _future;
  String _statusFilter = "all";
  late _ViewMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.initialMode) {
      "groups" => _ViewMode.groups,
      "bracket" => _ViewMode.bracket,
      _ => _ViewMode.list,
    };
    _load();
  }

  void _load() {
    // En modo Grupos/Llaves siempre se pide todo sin filtro de estado — esas
    // vistas necesitan ver las rondas futuras y las ya jugadas a la vez, si
    // no quedan incompletas.
    final status = (_mode != _ViewMode.list || _statusFilter == "all")
        ? null
        : _statusFilter;
    setState(() {
      _future = _api.getTournamentMatches(widget.tournamentId, status: status);
    });
  }

  void _setMode(_ViewMode mode) {
    setState(() => _mode = mode);
    _load();
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
                TopHeader(title: widget.tournamentName, subtitle: "Partidos"),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ModeChip(
                      label: "Partidos",
                      selected: _mode == _ViewMode.list,
                      onTap: () => _setMode(_ViewMode.list),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: "Grupos",
                      selected: _mode == _ViewMode.groups,
                      onTap: () => _setMode(_ViewMode.groups),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: "Llaves",
                      selected: _mode == _ViewMode.bracket,
                      onTap: () => _setMode(_ViewMode.bracket),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_mode == _ViewMode.list)
                  Row(
                    children: [
                      _FilterChip(
                        label: "Todos",
                        selected: _statusFilter == "all",
                        onTap: () {
                          setState(() => _statusFilter = "all");
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: "Por jugar",
                        selected: _statusFilter == "scheduled",
                        onTap: () {
                          setState(() => _statusFilter = "scheduled");
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: "Jugados",
                        selected: _statusFilter == "finished",
                        onTap: () {
                          setState(() => _statusFilter = "finished");
                          _load();
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<List<TournamentMatch>>(
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
                                    "No pudimos cargar los partidos.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final matches = snap.data ?? [];

                        if (_mode == _ViewMode.bracket) {
                          return _BracketByCategory(matches: matches);
                        }

                        if (_mode == _ViewMode.groups) {
                          return _GroupsByCategory(
                            tournamentId: widget.tournamentId,
                            matches: matches,
                          );
                        }

                        if (matches.isEmpty) {
                          return ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 30),
                                child: EmptyState(
                                  icon: Icons.sports_tennis_rounded,
                                  message: "No hay partidos con ese filtro.",
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          itemCount: matches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final m = matches[i];
                            final played =
                                m.status == "played" || m.status == "walkover";
                            final meta = [
                              m.categoryLabel,
                              if (m.groupName != null) "Grupo ${m.groupName}",
                              if (m.round != null) matchRoundLabel(m.round!),
                            ].join(" · ");

                            return GlassCard(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.matchDetail,
                                arguments: {
                                  "matchType": m.matchType,
                                  "matchId": m.idMatch,
                                },
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${m.player1Name} vs ${m.player2Name}",
                                          style: AppTypography.h2,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$meta · ${matchStatusLabel[m.status] ?? m.status}",
                                          style: AppTypography.bodyMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  played
                                      ? Text(
                                          "${m.setsPlayer1}-${m.setsPlayer2}",
                                          style: AppTypography.monoStrong,
                                        )
                                      : m.tableNumber != null
                                      ? InfoChip(
                                          label: "Mesa ${m.tableNumber}",
                                          tone: ChipTone.pending,
                                        )
                                      : Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.scorifyTextFaint,
                                        ),
                                ],
                              ),
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

/// Todos los grupos de todas las categorías del torneo (no solo "los
/// míos") — una card por grupo, con el propio resaltado si el jugador
/// logueado está en él.
class _GroupsByCategory extends StatefulWidget {
  final String tournamentId;
  final List<TournamentMatch> matches;
  const _GroupsByCategory({required this.tournamentId, required this.matches});

  @override
  State<_GroupsByCategory> createState() => _GroupsByCategoryState();
}

class _GroupsByCategoryState extends State<_GroupsByCategory> {
  final _api = PlayerApi();
  late Future<List<(String label, CategoryGroupsView view)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAll();
  }

  @override
  void didUpdateWidget(covariant _GroupsByCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches != widget.matches) {
      _future = _fetchAll();
    }
  }

  Future<List<(String label, CategoryGroupsView view)>> _fetchAll() async {
    final byCategory = <String, String>{}; // idCategory -> label
    for (final m in widget.matches) {
      byCategory.putIfAbsent(m.idCategory, () => m.categoryLabel);
    }
    final results = await Future.wait(
      byCategory.entries.map((e) async {
        final view = await _api.getAllGroups(widget.tournamentId, e.key);
        return (label: e.value, view: view);
      }),
    );
    return [for (final r in results) (r.label, r.view)];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(String label, CategoryGroupsView view)>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snap.hasError) {
          return ListView(
            children: [
              ErrorStateView(
                message: "No pudimos cargar los grupos.\n${snap.error}",
                onRetry: () => setState(() {
                  _future = _fetchAll();
                }),
              ),
            ],
          );
        }

        final categories = (snap.data ?? [])
            .where((c) => c.$2.groups.isNotEmpty)
            .toList();
        if (categories.isEmpty) {
          return ListView(
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyState(
                  icon: Icons.groups_outlined,
                  message: "Todavía no hay grupos generados.",
                ),
              ),
            ],
          );
        }

        return FutureBuilder<String?>(
          future: SessionStorage().getUserId(),
          builder: (context, userSnap) {
            final myUserId = userSnap.data;
            return ListView(
              children: [
                for (final cat in categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(cat.$1, style: AppTypography.h1),
                  ),
                  for (final g in cat.$2.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GroupCard(
                        group: g,
                        myUserId: myUserId,
                        isMyGroup:
                            myUserId != null &&
                            g.members.any((m) => m.idUser == myUserId),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Agrupa los partidos de llave por categoría — la mayoría de los torneos
/// tienen una sola, pero si hay más de una se muestran todas apiladas, cada
/// una con su propio cuadro.
class _BracketByCategory extends StatelessWidget {
  final List<TournamentMatch> matches;
  const _BracketByCategory({required this.matches});

  @override
  Widget build(BuildContext context) {
    final bracketMatches = matches
        .where((m) => m.matchType == "bracket")
        .toList();
    if (bracketMatches.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: EmptyState(
              icon: Icons.account_tree_outlined,
              message: "Todavía no hay llave generada.",
            ),
          ),
        ],
      );
    }

    final byCategory = <String, List<TournamentMatch>>{};
    for (final m in bracketMatches) {
      byCategory.putIfAbsent(m.idCategory, () => []).add(m);
    }

    return ListView(
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              entry.value.first.categoryLabel,
              style: AppTypography.h1,
            ),
          ),
          BracketTreeView(matches: entry.value),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.scorifyMint : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.scorifyMint
                  : AppColors.scorifyCardBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              fontSize: 12.5,
              color: selected ? AppColors.scorifyOnMint : AppColors.scorifyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.scorifyMint
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.scorifyMint
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              color: selected ? AppColors.scorifyOnMint : AppColors.scorifyText,
            ),
          ),
        ),
      ),
    );
  }
}
