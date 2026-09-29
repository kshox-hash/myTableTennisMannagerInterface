import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Card de UN grupo en "Partidos › Grupos": solo su composición — quiénes
/// lo integran, en el orden en que se armó. Las posiciones y estadísticas
/// del grupo propio se ven en "Tu grupo" (mi categoría).
class GroupCard extends StatelessWidget {
  final GroupFullView group;
  final String? myUserId;
  final bool isMyGroup;
  const GroupCard({super.key, required this.group, this.myUserId, this.isMyGroup = false});

  // "GR-3" → "Grupo 3"
  static String _label(String name) {
    final m = RegExp(r"^GR-?(\w+)$", caseSensitive: false).firstMatch(name.trim());
    return "Grupo ${m != null ? m.group(1) : name}";
  }

  @override
  Widget build(BuildContext context) {
    final members = group.members.toList()
      ..sort((a, b) => (a.groupPosition ?? 999).compareTo(b.groupPosition ?? 999));

    return GlassCard(
      borderColor: isMyGroup ? AppColors.scorifyMint.withValues(alpha: 0.45) : null,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(_label(group.groupName),
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                if (isMyGroup) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.scorifyMint, borderRadius: BorderRadius.circular(999)),
                    child: const Text("Tu grupo",
                        style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.scorifyOnMint)),
                  ),
                ],
                const Spacer(),
                Text("${members.length} ${members.length == 1 ? "jugador" : "jugadores"}",
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < members.length; i++)
            Material(
              color: members[i].idUser == myUserId ? AppColors.scorifyMint.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.playerProfile,
                  arguments: {"userId": members[i].idUser, "playerName": members[i].displayName},
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text("${i + 1}",
                            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyTextMuted)),
                      ),
                      ClipOval(child: Identicon(seed: members[i].idUser, size: 30)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              members[i].idUser == myUserId ? "${members[i].displayName} (tú)" : members[i].displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                            ),
                            if ((members[i].clubName ?? "").trim().isNotEmpty)
                              Text(members[i].clubName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.scorifyTextFaint),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
