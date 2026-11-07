import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/routes/app_routes.dart";

/// "Campeonatos que sigo": los que sigues como visita (sin jugar). Desde acá
/// se abre su ficha, donde están los grupos, la llave y los resultados, y
/// el botón para dejar de seguirlo.
class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final _api = TournamentApi();
  List<FollowedTournament>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await _api.getFollowing();
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _open(FollowedTournament f) async {
    try {
      final t = await _api.getTournamentById(f.idTournament);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: t);
      _load(); // pudo dejar de seguirlo desde la ficha
    } catch (_) {}
  }

  static const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  String _date(DateTime? d) => d == null ? "Sin fecha" : "${d.day} ${_months[d.month - 1]} ${d.year}";

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.scorifyMint,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const TopHeader(title: "Campeonatos que sigo", subtitle: "Sin jugarlos: te avisamos de lo importante."),
                const SizedBox(height: 16),
                if (_error != null)
                  ErrorStateView(message: _error!, onRetry: _load)
                else if (items == null)
                  const LoadingState()
                else if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: "Todavía no sigues ningún campeonato. Entra a uno y toca \"Seguir\" para recibir avisos de los grupos, la llave y los campeones.",
                  )
                else
                  for (final f in items) ...[
                    GlassCard(
                      onTap: () => _open(f),
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.scorifyMint, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    _date(f.eventDate),
                                    if (f.address != null && f.address!.isNotEmpty) f.address!,
                                    if (f.status == "cancelled") "Cancelado",
                                  ].join(" · "),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMuted.copyWith(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
