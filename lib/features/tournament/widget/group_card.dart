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
/// jugados, ganados y perdidos; los que clasifican
/// marcados) y, debajo, los resultados de cada partido del grupo. Antes solo
/// mostraba quiénes lo integraban y no se podían ver los resultados.
class GroupCard extends StatelessWidget {
  final GroupFullView group;
  final String? myUserId;
  final bool isMyGroup;
  /// Cuántos clasifican a la llave por grupo (null = no se sabe).
  final int? qualifiers;
  /// La categoría tiene Plata: el puesto siguiente va a la llave de Plata.
  final bool hasSilver;
  const GroupCard({super.key, required this.group, this.myUserId, this.isMyGroup = false, this.qualifiers, this.hasSilver = false});

  static const _silver = Color(0xFFB8C4CC);

  // "GR-3" → "Grupo 3"
  static String _label(String name) {
    final m = RegExp(r"^GR-?(\w+)$", caseSensitive: false).firstMatch(name.trim());
    return "Grupo ${m != null ? m.group(1) : name}";
  }

  static const _num = TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyText);
  static const _numMuted = TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted);
  static const _numStrong = TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.scorifyText);
  static const _head = TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: AppColors.scorifyTextFaint);

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

    Widget stat(String v, {double w = 28, TextStyle style = _num}) =>
        SizedBox(width: w, child: Text(v, textAlign: TextAlign.center, style: style));
    // Los botones de cada jugador (ver recorrido) solo existen dentro de
    // "Partidos": fuera de ahí la columna no se reserva. Antes el encabezado
    // guardaba 24 px aunque los botones no estuvieran y PJ/G/P quedaban
    // corridos respecto de los números.
    final hasActions = TournamentMatchesScope.of(context) != null;

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
          // La regla, antes de jugar: cuántos pasan y a dónde.
          if (qualifiers != null && qualifiers! > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _ruleChip(AppColors.scorifyMint, qualifiers == 1 ? "1º a la llave" : qualifiers == 2 ? "1º y 2º a la llave" : "1º al ${qualifiers}º a la llave"),
                  if (hasSilver) _ruleChip(_silver, "${qualifiers! + 1}º a Plata"),
                ],
              ),
            ),
          // Encabezado de la tabla.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: Row(
              children: [
                const SizedBox(width: 22 + 26 + 10),
                const Expanded(child: Text("Jugador", style: _head)),
                stat("PJ", style: _head),
                stat("G", style: _head),
                stat("P", style: _head),
                if (hasActions) const SizedBox(width: _actionsW),
              ],
            ),
          ),
          for (var i = 0; i < members.length; i++) _memberRow(context, members[i], i, standing[members[i].idUser], anyPlayed, stat, hasActions),
          if (qualifiers == null && group.standings.any((s) => s.qualifiedToBracket)) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _ruleChip(AppColors.scorifyMint, "Clasifica a la llave"),
            ),
          ],
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("Resultados", style: _head),
            ),
            const SizedBox(height: 4),
            // Todos con la misma cantidad de columnas de set (la del partido
            // más largo): uno de 2 sets no corre la columna de sets ganados.
            ...dividedRows([
              for (final m in matches)
                _matchRow(m, matches.fold<int>(0, (n, x) => x.setScores.length > n ? x.setScores.length : n)),
            ]),
          ],
        ],
      ),
    );
  }

  static const double _actionsW = 28;

  static Widget _ruleChip(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
        ],
      );

  Widget _memberRow(BuildContext context, GroupMemberInfo m, int i, GroupStandingInfo? s, bool anyPlayed,
      Widget Function(String, {double w, TextStyle style}) stat, bool hasActions) {
    final me = m.idUser == myUserId;
    final pos = s?.position ?? i + 1;
    final q = qualifiers;
    // Zona: con resultados (o ya definido). Antes de jugar el orden es el
    // del sorteo y marcar "clasifica" confundiría.
    final decided = s?.qualifiedToBracket == true;
    final inGold = decided || (anyPlayed && q != null && pos <= q);
    final inSilver = !inGold && anyPlayed && hasSilver && q != null && pos == q + 1;
    final zone = inGold ? AppColors.scorifyMint : (inSilver ? _silver : null);
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
              Container(
                width: 3,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: zone ?? Colors.transparent, borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(
                width: 13,
                child: Text("${s?.position ?? i + 1}",
                    style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: zone ?? AppColors.scorifyTextMuted)),
              ),
              UserAvatar(userId: m.idUser, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me ? "${m.displayName} (tú)" : m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                    ),
                    if ((m.clubName ?? "").trim().isNotEmpty)
                      Text(m.clubName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextMuted)),
                  ],
                ),
              ),
              stat(anyPlayed ? "${s?.played ?? 0}" : "–", style: _numMuted),
              stat(anyPlayed ? "${s?.won ?? 0}" : "–", style: _numStrong),
              stat(anyPlayed ? "${s?.lost ?? 0}" : "–", style: _numMuted),
              if (hasActions)
                SizedBox(
                  width: _actionsW,
                  child: PlayerActions(playerId: m.idUser, playerName: m.displayName, showProfile: false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Un partido como marcador de dos renglones: cada jugador a la izquierda y
  // sus sets a la derecha (el ganador en blanco y negrita, el otro en gris),
  // y a la derecha el estado: "Mesa N" en vivo, "Por jugar" o "W.O.". Debajo,
  // los puntos de cada set. Todo queda alineado en columnas, sin importar
  // el largo de los nombres.
  Widget _matchRow(GroupMatchInfo m, int setColumns) {
    final played = m.status == "played" || m.status == "walkover";
    final wo = m.status == "walkover";
    final p1 = group.nameFor(m.player1Id);
    final p2 = group.nameFor(m.player2Id);

    // Puntos de cada set al lado de los sets, como un marcador: arriba los
    // del jugador 1, abajo los del 2, cada set en su columna (el que ganó
    // ese set en blanco y negrita).
    final sets = played && !wo ? m.setScores : const <(int, int)>[];
    Widget line(String name, int? setsWon, bool winner, bool first) {
      final dim = played && !winner;
      return Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 13,
                fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
                color: dim ? AppColors.scorifyTextMuted : AppColors.scorifyText,
              ),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              played && !wo ? "${setsWon ?? 0}" : "",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: winner ? AppColors.scorifyText : AppColors.scorifyTextFaint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (sets.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 16, color: AppColors.scorifyCardBorder),
            const SizedBox(width: 2),
            for (var k = 0; k < setColumns; k++)
              SizedBox(
                width: 24,
                child: k >= sets.length
                    ? null
                    : Text(
                  "${first ? sets[k].$1 : sets[k].$2}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 12.5,
                    fontWeight: (first ? sets[k].$1 > sets[k].$2 : sets[k].$2 > sets[k].$1) ? FontWeight.w700 : FontWeight.w500,
                    color: (first ? sets[k].$1 > sets[k].$2 : sets[k].$2 > sets[k].$1) ? AppColors.scorifyText : AppColors.scorifyTextFaint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ],
      );
    }

    final Widget status;
    if (wo) {
      status = const PanelChip(label: "W.O.", fontSize: 11);
    } else if (played) {
      status = const SizedBox.shrink();
    } else if (m.tableNumber != null) {
      status = PanelChip(label: "Mesa ${m.tableNumber}", color: AppColors.scorifyLive, fontSize: 11);
    } else {
      status = const Text(
        "Por jugar",
        style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextFaint),
      );
    }


    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                line(p1, m.setsPlayer1, played && m.winnerId == m.player1Id, true),
                const SizedBox(height: 4),
                line(p2, m.setsPlayer2, played && m.winnerId == m.player2Id, false),
              ],
            ),
          ),
          if (!played || wo) ...[
            const SizedBox(width: 12),
            SizedBox(width: 64, child: Align(alignment: Alignment.centerRight, child: status)),
          ],
        ],
      ),
    );
  }
}
