import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/models/live_summary_model.dart";

/// "Ver todos los jugadores" del panel "En vivo": la categoría completa, un
/// jugador por fila. Arriba los que siguen (clasificados a la llave, o en
/// carrera si ya se juega la llave); abajo los eliminados, con dónde
/// quedaron ("Grupo 3", "Cuartos de final"). Los datos vienen del Inicio.
class LivePlayersScreen extends StatelessWidget {
  final LiveSummary summary;
  const LivePlayersScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScrollingHeaderPage(
              header: [
                const SizedBox(height: 16),
                TopHeader(title: s.categoryLabel, subtitle: s.tournamentName),
                const SizedBox(height: 14),
              ],
              body: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SectionCard(
                    title: "${s.aliveTitle} · ${s.classified.length}",
                    icon: Icons.check_circle_rounded,
                    titleColor: AppColors.scorifyButterfly,
                    trailing: s.currentRound == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(s.currentRound!, style: AppTypography.bodyMuted.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: s.classified.isEmpty
                        ? const _Empty("Todavía no hay clasificados.")
                        : Column(children: dividedRows([for (final p in s.classified) _PlayerRow(person: p)])),
                  ),
                  if (s.movedToSilver.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionCard(
                      title: "Pasaron a Plata · ${s.movedToSilver.length}",
                      icon: Icons.military_tech_rounded,
                      titleColor: AppColors.scorifyMint,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(children: dividedRows([for (final p in s.movedToSilver) _PlayerRow(person: p, showStage: false)])),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SectionCard(
                    title: "Eliminados · ${s.eliminated.length}",
                    icon: Icons.cancel_rounded,
                    titleColor: AppColors.scorifyNegative,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: s.eliminated.isEmpty
                        ? const _Empty("Nadie ha quedado eliminado todavía.")
                        : Column(children: dividedRows([for (final p in s.eliminated) _PlayerRow(person: p, faint: true)])),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
      );
}

/// Nombre completo y, en los eliminados, dónde quedaron a la derecha.
class _PlayerRow extends StatelessWidget {
  final LivePerson person;
  final bool faint;
  final bool showStage;
  const _PlayerRow({required this.person, this.faint = false, this.showStage = true});

  @override
  Widget build(BuildContext context) {
    final p = person;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.isMe ? "Tú" : p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 14,
                fontWeight: p.isMe ? FontWeight.w700 : FontWeight.w500,
                color: p.isMe ? AppColors.scorifyMint : (faint ? AppColors.scorifyTextMuted : AppColors.scorifyText),
              ),
            ),
          ),
          if (showStage && p.stage != null && p.stage!.isNotEmpty)
            Text(p.stage!, style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
