import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";

/// Card de UN grupo completo (posiciones de todos sus jugadores) — usada
/// tanto en "Resultados" (mi categoría) como en "Partidos › Grupos", para
/// que las dos pantallas se vean igual.
class GroupCard extends StatelessWidget {
  final GroupFullView group;
  final String? myUserId;
  final bool isMyGroup;
  const GroupCard({super.key, required this.group, this.myUserId, this.isMyGroup = false});

  @override
  Widget build(BuildContext context) {
    final sorted = group.standings.toList()..sort((a, b) => (a.position ?? 999).compareTo(b.position ?? 999));

    return GlassCard(
      borderColor: isMyGroup ? AppColors.scorifyMint.withOpacity(0.45) : null,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text("Grupo ${group.groupName}", style: AppTypography.h2),
                if (isMyGroup) ...[
                  const SizedBox(width: 8),
                  const InfoChip(label: "Tu grupo", tone: ChipTone.positive),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < sorted.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.white.withOpacity(0.06)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: sorted[i].idUser == myUserId ? AppColors.scorifyMint.withOpacity(0.08) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      sorted[i].position?.toString() ?? "-",
                      style: AppTypography.mono14.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.nameFor(sorted[i].idUser),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyText,
                    ),
                  ),
                  StatMini(label: "PJ", value: "${sorted[i].played}"),
                  const SizedBox(width: 12),
                  StatMini(label: "PG", value: "${sorted[i].won}"),
                  const SizedBox(width: 12),
                  StatMini(label: "SETS", value: "${sorted[i].setsFor}-${sorted[i].setsAgainst}"),
                  if (sorted[i].qualifiedToBracket) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded, color: AppColors.scorifyMint, size: 16),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatMini extends StatelessWidget {
  final String label;
  final String value;
  const StatMini({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.mono14.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}
