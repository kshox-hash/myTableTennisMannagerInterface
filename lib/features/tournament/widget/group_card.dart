import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/player_actions.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Card de UN grupo en "Partidos › Grupos": la tabla (posición, partidos
/// jugados, ganados, perdidos y diferencia de sets; los que clasifican
/// marcados) y, debajo, los resultados de cada partido del grupo. Antes solo
/// mostraba quiénes lo integraban y no se podían ver los resultados.
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

  static const _num = TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText);
  static const _head = TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.scorifyTextFaint);

  @override
  Widget build(BuildContext context) {
    final standing = {for (final s in group.standings) s.idUser: s};
    final members = group.members.toList()
      ..sort((a, b) {
        final pa = standing[a.idUser]?.position ?? a.groupPosition ?? 999;
        final pb = standing[b.idUser]?.position ?? b.groupPosition ?? 999;
        return pa.compareTo(pb);
      });
    final anyPlayed = group.standings.any((s) => s.played > 0);
    final matches = group.matches.toList()
      ..sort((a, b) {
        final r = (a.round ?? 0).compareTo(b.round ?? 0);
        return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
      });

    Widget stat(String v, {double w = 26, TextStyle style = _num}) =>
        SizedBox(width: w, child: Text(v, textAlign: TextAlign.center, style: style));

    return SectionCard(
      title: isMyGroup ? "${_label(group.groupName)} · Tu grupo" : _label(group.groupName),
      icon: Icons.groups_rounded,
      titleColor: isMyGroup ? AppColors.scorifyMint : null,
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text("${members.length} ${members.length == 1 ? "jugador" : "jugadores"}",
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la tabla.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: Row(
              children: [
                const SizedBox(width: 22),
                const Expanded(child: Text("JUGADOR", style: _head)),
                stat("PJ", style: _head),
                stat("G", style: _head),
                stat("P", style: _head),
                stat("SETS", w: 40, style: _head),
                const SizedBox(width: 28),
              ],
            ),
          ),
          for (var i = 0; i < members.length; i++) _memberRow(context, members[i], i, standing[members[i].idUser], anyPlayed, stat),
          if (group.standings.any((s) => s.qualifiedToBracket)) ...[
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.scorifyButterfly),
                  SizedBox(width: 4),
                  Text("Clasifica a la llave", style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextMuted)),
                ],
              ),
            ),
          ],
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("RESULTADOS", style: _head),
            ),
            const SizedBox(height: 4),
            ...dividedRows([for (final m in matches) _matchRow(m)]),
          ],
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, GroupMemberInfo m, int i, GroupStandingInfo? s, bool anyPlayed,
      Widget Function(String, {double w, TextStyle style}) stat) {
    final me = m.idUser == myUserId;
    final diff = s == null ? 0 : s.setsFor - s.setsAgainst;
    return Material(
      color: me ? AppColors.scorifyMint.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(Panel.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Panel.radius),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.playerProfile,
          arguments: {"userId": m.idUser, "playerName": m.displayName},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text("${s?.position ?? i + 1}",
                    style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: s?.qualifiedToBracket == true ? AppColors.scorifyButterfly : AppColors.scorifyTextMuted)),
              ),
              UserAvatar(userId: m.idUser, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me ? "${m.displayName} (tú)" : m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                    ),
                    if ((m.clubName ?? "").trim().isNotEmpty)
                      Text(m.clubName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, color: AppColors.scorifyTextMuted)),
                  ],
                ),
              ),
              stat(anyPlayed ? "${s?.played ?? 0}" : "–"),
              stat(anyPlayed ? "${s?.won ?? 0}" : "–"),
              stat(anyPlayed ? "${s?.lost ?? 0}" : "–"),
              stat(anyPlayed ? (diff > 0 ? "+$diff" : "$diff") : "–", w: 40),
              PlayerActions(playerId: m.idUser, playerName: m.displayName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchRow(GroupMatchInfo m) {
    final played = m.status == "played" || m.status == "walkover";
    final p1 = group.nameFor(m.player1Id);
    final p2 = group.nameFor(m.player2Id);
    TextStyle name(bool winner) => TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 12.5,
          fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
          color: played && !winner ? AppColors.scorifyTextMuted : AppColors.scorifyText,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(p1, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: name(played && m.winnerId == m.player1Id))),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: played
                ? Center(child: PanelChip(label: m.status == "walkover" ? "W.O." : "${m.setsPlayer1} - ${m.setsPlayer2}", color: AppColors.scorifyMint, fontSize: 12))
                : Text(
                    m.tableNumber != null ? "Mesa ${m.tableNumber}" : "Pendiente",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: m.tableNumber != null ? AppColors.scorifyLive : AppColors.scorifyTextFaint,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(p2, maxLines: 1, overflow: TextOverflow.ellipsis, style: name(played && m.winnerId == m.player2Id))),
        ],
      ),
    );
  }
}
