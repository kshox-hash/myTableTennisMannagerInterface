import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/features/tournament/models/tables_queue_model.dart";

/// Versión de solo lectura del panel de Mesas del admin — mesas en juego
/// ahora mismo + los próximos partidos de la cola real de despacho, para que
/// cualquier jugador sepa qué se viene sin tener que preguntarle al admin.
class TournamentTablesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentTablesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentTablesScreen> createState() => _TournamentTablesScreenState();
}

class _TournamentTablesScreenState extends State<TournamentTablesScreen> {
  final _api = TournamentApi();
  Future<TablesQueueBoard>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _api.getTablesQueue(widget.tournamentId);
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
                TopHeader(title: "Mesas", subtitle: widget.tournamentName),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<TablesQueueBoard>(
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
                                    "No pudimos cargar las mesas.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final board = snap.data!;
                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            Text("Mesas", style: AppTypography.h1),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.5,
                              children: board.tables
                                  .map((t) => _TableCard(slot: t))
                                  .toList(),
                            ),
                            const SizedBox(height: 22),
                            Text("Próximos partidos", style: AppTypography.h1),
                            const SizedBox(height: 4),
                            Text(
                              "Orden estimado en que se repartirían las mesas.",
                              style: AppTypography.bodyMuted,
                            ),
                            const SizedBox(height: 12),
                            if (board.nextMatches.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: EmptyState(
                                  icon: Icons.sports_tennis_rounded,
                                  message: "No hay partidos esperando mesa.",
                                ),
                              )
                            else
                              ...board.nextMatches.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _QueueRow(
                                    position: entry.key + 1,
                                    match: entry.value,
                                  ),
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

class _TableCard extends StatelessWidget {
  final TableSlot slot;
  const _TableCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final m = slot.match;
    final occupied = m != null;

    return GlassCard(
      borderColor: occupied
          ? AppColors.scorifyMint.withOpacity(0.45)
          : AppColors.scorifyCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                "🏓 Mesa ${slot.tableNumber}",
                style: AppTypography.bodyText.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: occupied
                      ? AppColors.scorifyMint.withOpacity(0.16)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  occupied ? "En juego" : "Libre",
                  style: AppTypography.caption.copyWith(
                    color: occupied
                        ? AppColors.scorifyMint
                        : AppColors.scorifyTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (occupied) ...[
            Text(
              m.categoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
            Text(
              "${m.player1Name ?? "—"} vs ${m.player2Name ?? "—"}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMuted.copyWith(
                color: AppColors.scorifyText,
              ),
            ),
          ] else
            Text("Sin partido asignado", style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final int position;
  final QueueMatch match;
  const _QueueRow({required this.position, required this.match});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scorifyCardFill,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$position",
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ),
                    Text(match.matchLabel, style: AppTypography.caption),
                  ],
                ),
                Text(
                  "${match.player1Name ?? "—"} vs ${match.player2Name ?? "—"}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
