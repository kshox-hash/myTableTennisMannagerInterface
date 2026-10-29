import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/features/home/presentation/live_players_screen.dart";
import "package:myttmi/features/player/models/live_summary_model.dart";
import "package:myttmi/routes/cyber_page_route.dart";

/// "En vivo" del Inicio: en el campeonato que estás jugando (tu categoría),
/// quiénes siguen (clasificados a la llave, o en carrera si ya se juega la
/// llave) y quiénes quedaron eliminados. Aquí van unos pocos nombres, cada
/// uno en su cajita; "Ver todos los jugadores" abre la lista completa. Se
/// actualiza con cada resultado (ver HomeScreen). Si juegas varias
/// categorías, las flechas del título cambian entre ellas.
class HomeLiveCard extends StatefulWidget {
  final List<LiveSummary> summaries;
  const HomeLiveCard({super.key, required this.summaries});

  @override
  State<HomeLiveCard> createState() => _HomeLiveCardState();
}

class _HomeLiveCardState extends State<HomeLiveCard> {
  int _i = 0;

  // Nombres por lista en el Inicio; el resto, en "Ver todos los jugadores".
  static const _preview = 4;

  @override
  Widget build(BuildContext context) {
    final all = widget.summaries;
    final s = all[_i.clamp(0, all.length - 1)];

    return SectionCard(
      title: "En vivo · ${s.tournamentName}",
      icon: Icons.sensors_rounded,
      titleColor: AppColors.scorifyNegative,
      trailing: all.length < 2
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Arrow(icon: Icons.chevron_left_rounded, onTap: _i == 0 ? null : () => setState(() => _i--)),
                Text("${_i + 1}/${all.length}", style: AppTypography.bodyMuted.copyWith(fontSize: 11.5)),
                _Arrow(icon: Icons.chevron_right_rounded, onTap: _i == all.length - 1 ? null : () => setState(() => _i++)),
              ],
            ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.categoryLabel, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600))),
              if (s.currentRound != null) PanelChip(label: s.currentRound!, color: AppColors.scorifyButterfly, fontSize: 11),
            ],
          ),
          const SizedBox(height: 12),
          if (s.classified.isEmpty && s.eliminated.isEmpty)
            Text("Todavía no termina ningún grupo.", style: AppTypography.bodyMuted.copyWith(fontSize: 12.5))
          else ...[
            _Names(title: s.aliveTitle, color: AppColors.scorifyButterfly, people: s.classified, max: _preview),
            const SizedBox(height: 14),
            _Names(title: "Eliminados", color: AppColors.scorifyNegative, people: s.eliminated, max: _preview, faint: true),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, CyberPageRoute(waitForData: false, builder: (_) => LivePlayersScreen(summary: s))),
                child: const Text(
                  "Ver todos los jugadores ›",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyMint),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Arrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: onTap == null ? AppColors.scorifyTextFaint : AppColors.scorifyText),
        ),
      );
}

/// "SIGUEN EN CARRERA · 8" y debajo los primeros nombres, cada uno en su
/// cajita con aire entre ellas ("Tú" siempre primero y en celeste); si hay
/// más, "+5".
class _Names extends StatelessWidget {
  final String title;
  final Color color;
  final List<LivePerson> people;
  final int max;
  final bool faint;
  const _Names({required this.title, required this.color, required this.people, required this.max, this.faint = false});

  @override
  Widget build(BuildContext context) {
    final sorted = [...people.where((p) => p.isMe), ...people.where((p) => !p.isMe)];
    final shown = sorted.take(max).toList();
    final rest = sorted.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${title.toUpperCase()} · ${people.length}",
          style: TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: color),
        ),
        const SizedBox(height: 8),
        if (people.isEmpty)
          Text("—", style: AppTypography.bodyMuted.copyWith(fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in shown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: panelBox(color: p.isMe ? AppColors.scorifyMint : null),
                  child: Text(
                    p.short,
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 13,
                      fontWeight: p.isMe ? FontWeight.w700 : FontWeight.w500,
                      color: p.isMe ? AppColors.scorifyMint : (faint ? AppColors.scorifyTextMuted : AppColors.scorifyText),
                    ),
                  ),
                ),
              if (rest > 0) Text("+$rest", style: AppTypography.bodyMuted.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
      ],
    );
  }
}
