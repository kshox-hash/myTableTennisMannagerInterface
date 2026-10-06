import "package:myttmi/core/ui/section_card.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
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

    return SectionCard(
      title: isMyGroup ? "${_label(group.groupName)} · Tu grupo" : _label(group.groupName),
      icon: Icons.groups_rounded,
      titleColor: isMyGroup ? AppColors.scorifyMint : null,
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text("${members.length} ${members.length == 1 ? "jugador" : "jugadores"}",
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < members.length; i++)
            Material(
              color: members[i].idUser == myUserId ? AppColors.scorifyMint.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              child: InkWell(
                borderRadius: BorderRadius.circular(2),
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
                            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
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
                                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
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
