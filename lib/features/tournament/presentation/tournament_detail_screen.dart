import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/routes/app_routes.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final TournamentApi api = TournamentApi();
  late List<TournamentCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.tournament.categories;
  }

  String _genderLabel(String g) {
    switch (g) {
      case "male":
        return "Masculino";
      case "female":
        return "Femenino";
      case "mixed":
        return "Mixto";
      default:
        return g;
    }
  }

  Future<void> _subscribe(TournamentCategory c) async {
    try {
      await api.subscribeToCategory(
        tournamentId: widget.tournament.idTournament,
        categoryId: c.idCategory,
      );

      if (!mounted) return;

      setState(() {
        _categories = _categories
            .map(
              (cat) => cat.idCategory == c.idCategory
                  ? cat.copyWith(isEnrolled: true)
                  : cat,
            )
            .toList();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Inscripción realizada")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _goMyCategory(TournamentCategory c) {
    Navigator.pushNamed(
      context,
      AppRoutes.myCategory,
      arguments: {
        "tournamentId": widget.tournament.idTournament,
        "tournamentName": widget.tournament.tournamentName,
        "categoryId": c.idCategory,
        "categoryLabel": c.categoryLabel,
      },
    );
  }

  void _goPlayers() {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentPlayers,
      arguments: {
        "tournamentId": widget.tournament.idTournament,
        "tournamentName": widget.tournament.tournamentName,
      },
    );
  }

  void _goMatches() {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentMatches,
      arguments: {
        "tournamentId": widget.tournament.idTournament,
        "tournamentName": widget.tournament.tournamentName,
      },
    );
  }

  void _goTables() {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentTables,
      arguments: {
        "tournamentId": widget.tournament.idTournament,
        "tournamentName": widget.tournament.tournamentName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final location = [
      t.address,
      t.region,
    ].where((s) => (s ?? "").trim().isNotEmpty).join(" · ");

    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TopHeader(title: t.tournamentName),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      if (location.isNotEmpty)
                        _InfoTile(
                          icon: Icons.place_rounded,
                          label: "Ubicación",
                          value: location,
                        ),

                      if ((t.description ?? "").trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoTile(
                          icon: Icons.info_outline_rounded,
                          label: "Descripción",
                          value: t.description!,
                        ),
                      ],

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinePillButton(
                              icon: Icons.people_outline_rounded,
                              label: "Jugadores",
                              onTap: _goPlayers,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinePillButton(
                              icon: Icons.sports_tennis_rounded,
                              label: "Partidos",
                              onTap: _goMatches,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinePillButton(
                              icon: Icons.table_bar_rounded,
                              label: "Mesas",
                              onTap: _goTables,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text("Categorías", style: AppTypography.h1),
                      const SizedBox(height: 12),

                      if (_categories.isEmpty)
                        Text(
                          "Este campeonato no tiene categorías aún.",
                          style: AppTypography.bodyMuted,
                        )
                      else
                        ..._categories.map((c) {
                          final enrolled = c.isEnrolled;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.categoryLabel,
                                    style: AppTypography.h1,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      InfoChip(label: _genderLabel(c.gender)),
                                      InfoChip(
                                        label: "\$${c.inscriptionPrice}",
                                      ),
                                      InfoChip(
                                        label: c.quotas != null
                                            ? "Cupos: ${c.quotas}"
                                            : "Sin límite de cupos",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      // Ver grupos/posiciones está disponible para
                                      // cualquier jugador, esté o no inscripto — antes
                                      // este botón solo aparecía si ya estabas inscripto,
                                      // lo que dejaba a cualquiera que solo quisiera
                                      // mirar sin ninguna forma de hacerlo.
                                      Expanded(
                                        child: OutlinePillButton(
                                          icon: Icons.groups_rounded,
                                          label: enrolled
                                              ? "Resultados"
                                              : "Ver grupos",
                                          onTap: () => _goMyCategory(c),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: enrolled
                                            ? const Center(
                                                child: InfoChip(
                                                  label: "Inscrito ✓",
                                                  tone: ChipTone.positive,
                                                ),
                                              )
                                            : SolidPillButton(
                                                label: "Suscribirme",
                                                onTap: () => _subscribe(c),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scorifyMint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.scorifyCardBorder),
            ),
            child: Icon(icon, color: AppColors.scorifyMint, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.bodyText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
