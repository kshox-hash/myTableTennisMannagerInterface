import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/clubs/club_crests.dart";
import "package:myttmi/core/ui/player_actions.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/core/ui/scoreboard.dart";
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

  static const _silver = Color(0xFFC0C7CF); // Plata (igual que la web)
  static Color get _gold => AppColors.scorifyButterfly; // clasifica: lima de la web

  // "GR-3" → "Grupo 3"
  static String _label(String name) {
    final m = RegExp(r"^GR-?(\w+)$", caseSensitive: false).firstMatch(name.trim());
    return "Grupo ${m != null ? m.group(1) : name}";
  }

  static TextStyle get _num => TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyText);
  static TextStyle get _numMuted => TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted);
  static TextStyle get _numStrong => TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.scorifyText);
  static TextStyle get _head => TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: AppColors.scorifyTextFaint);

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

    Widget stat(String v, {double w = 28, TextStyle? style}) =>
        SizedBox(width: w, child: Text(v, textAlign: TextAlign.center, style: style ?? _num));
    // Los botones de cada jugador (ver recorrido) solo existen dentro de
    // "Partidos": fuera de ahí la columna no se reserva. Antes el encabezado
    // guardaba 24 px aunque los botones no estuvieran y PJ/G/P quedaban
    // corridos respecto de los números.
    // Sin el trofeo por fila (ensuciaba la tabla): tocar al jugador abre su perfil.
    const hasActions = false;

    return SectionCard(
      title: isMyGroup ? "${_label(group.groupName)} · Tu grupo" : _label(group.groupName),
      icon: Icons.groups_rounded,
      titleColor: isMyGroup ? AppColors.scorifyMint : null,
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text("${members.length} ${members.length == 1 ? "jugador" : "jugadores"}",
            style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
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
                const SizedBox(width: 22 + 8 + 26 + 10),
                Expanded(child: Text("Jugador", style: _head)),
                stat("PJ", style: _head),
                stat("G", style: _head),
                stat("P", style: _head),
                if (hasActions) const SizedBox(width: _actionsW),
              ],
            ),
          ),
          for (var i = 0; i < members.length; i++) _memberRow(context, members[i], i, standing[members[i].idUser], anyPlayed, stat, hasActions),
          // Leyenda chica bajo la tabla (secundaria): lima = clasifica, plateado = Plata.
          if (qualifiers != null && qualifiers! > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _ruleChip(_gold, hasSilver ? "Clasifica a Oro" : "Clasifica a la llave"),
                  if (hasSilver) _ruleChip(_silver, "Clasifica a Plata"),
                ],
              ),
            ),
          if (qualifiers == null && group.standings.any((s) => s.qualifiedToBracket)) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _ruleChip(_gold, "Clasifica a la llave"),
            ),
          ],
          // Resultados plegados: lo principal es la tabla; los partidos se abren al tocar.
          if (matches.isNotEmpty)
            _FoldedResults(
              count: matches.length,
              played: matches.where((m) => m.winnerId != null).length,
              // Todos con la misma cantidad de columnas de set (la del partido más largo).
              rows: [for (final m in matches) _matchRow(m, matches.fold<int>(0, (n, x) => x.setScores.length > n ? x.setScores.length : n))],
            ),
        ],
      ),
    );
  }

  static const double _actionsW = 28;

  static Widget _ruleChip(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.scorifyTextFaint)),
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
    final zone = inGold ? _gold : (inSilver ? _silver : null);
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
              // Posición en círculo (como la web): lima clasifica, plateado Plata.
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: zone ?? Colors.transparent, shape: BoxShape.circle),
                child: Text("${s?.position ?? i + 1}",
                    style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: zone != null ? const Color(0xFF16210A) : AppColors.scorifyTextMuted)),
              ),
              UserAvatar(userId: m.idUser, size: 26, name: m.displayName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me ? "${m.displayName} (tú)" : m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Jerarquía: quien clasifica (o soy yo) en blanco fuerte; el resto, apagado.
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13.5,
                        fontWeight: zone != null || me ? FontWeight.w700 : FontWeight.w500,
                        color: zone != null || me ? AppColors.scorifyText : AppColors.scorifyTextMuted,
                      ),
                    ),
                    // Club con su escudo (como en la web).
                    ClubLine(
                      idUser: m.idUser,
                      club: m.clubName,
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextMuted),
                    ),
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

  // Un partido como marcador (ver Scoreboard): cada jugador en su franja,
  // arriba más clara y abajo más oscura, sets grandes y los puntos de cada
  // set al lado. Sin jugar: los nombres y, a la derecha, "Mesa N" (en vivo)
  // o "Por jugar"; W.O. con su etiqueta.
  Widget _matchRow(GroupMatchInfo m, int setColumns) {
    final played = m.status == "played" || m.status == "walkover";
    final wo = m.status == "walkover";
    final winner = !played ? null : (m.winnerId == m.player1Id ? 1 : (m.winnerId == m.player2Id ? 2 : null));
    Widget? trailing;
    if (wo) {
      trailing = const PanelChip(label: "W.O.", fontSize: 11);
    } else if (!played && m.tableNumber != null) {
      trailing = PanelChip(label: "Mesa ${m.tableNumber}", color: AppColors.scorifyLive, fontSize: 11);
    } else if (!played) {
      trailing = Text(
        "Por jugar",
        style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextFaint),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 5),
      child: Scoreboard(
        player1: group.nameFor(m.player1Id),
        player2: group.nameFor(m.player2Id),
        sets1: played && !wo ? m.setsPlayer1 : null,
        sets2: played && !wo ? m.setsPlayer2 : null,
        winner: winner,
        setScores: played && !wo ? m.setScores : const [],
        setColumns: played && !wo ? setColumns : 0,
        showScore: played && !wo,
        trailing: trailing,
      ),
    );
  }
}

/// "Resultados · 6 de 6 jugados  Ver ▾": plegado por defecto, se abre al tocar.
class _FoldedResults extends StatefulWidget {
  final int count;
  final int played;
  final List<Widget> rows;
  const _FoldedResults({required this.count, required this.played, required this.rows});

  @override
  State<_FoldedResults> createState() => _FoldedResultsState();
}

class _FoldedResultsState extends State<_FoldedResults> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: AppColors.scorifySurface2,
            child: Row(
              children: [
                Icon(Icons.sports_tennis_rounded, size: 15, color: AppColors.scorifyTextMuted),
                const SizedBox(width: 8),
                Text("Resultados", style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.scorifyText)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text("${widget.played} de ${widget.count} jugados",
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, color: AppColors.scorifyTextMuted)),
                ),
                Text(_open ? "Ocultar" : "Ver",
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.scorifyMint)),
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: AppColors.scorifyMint),
              ],
            ),
          ),
        ),
        if (_open) ...[const SizedBox(height: 4), ...widget.rows],
      ],
    );
  }
}
