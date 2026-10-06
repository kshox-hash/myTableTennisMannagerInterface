import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Fila compacta de un partido: puntito verde (ganó) o rojo (perdió),
/// "vs. rival", fecha · campeonato · fase, marcador en blanco y ›.
/// Se usa en el Historial y en el perfil de otros jugadores.
class CompactMatchRow extends StatelessWidget {
  final bool? won; // null = no aplica
  final String opponent;
  final String meta;
  final String score;
  final VoidCallback? onTap;
  const CompactMatchRow({super.key, this.won, required this.opponent, required this.meta, required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: won == null ? AppColors.scorifyTextFaint : (won! ? AppColors.scorifyButterfly : AppColors.scorifyNegative),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("vs. $opponent",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                  const SizedBox(height: 2),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, color: AppColors.scorifyTextMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(score, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.scorifyTextFaint),
          ],
        ),
      ),
    );
  }
}

const _monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
const _monthShort = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

/// Partidos agrupados por mes: una tarjeta por mes ("SEPTIEMBRE 2026") con
/// filas compactas, desde el punto de vista de [ownerId] (quien es dueño del
/// historial: tú, u otro jugador en su perfil).
List<Widget> matchesByMonth(BuildContext context, List<PlayerMatchHistoryItem> items, String? ownerId) {
  final groups = <String, List<PlayerMatchHistoryItem>>{};
  for (final m in items) {
    final d = DateTime.tryParse(m.playedAt ?? "")?.toLocal();
    final key = d == null ? "Sin fecha" : "${_monthNames[d.month - 1]} ${d.year}";
    groups.putIfAbsent(key, () => []).add(m);
  }
  final out = <Widget>[];
  groups.forEach((month, list) {
    if (out.isNotEmpty) out.add(const SizedBox(height: 12));
    out.add(SectionCard(
      title: month,
      icon: Icons.calendar_month_rounded,
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text("${list.length} ${list.length == 1 ? "partido" : "partidos"}",
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, color: AppColors.scorifyTextMuted)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        children: dividedRows([
          for (final m in list)
            () {
              final isP1 = m.player1Id == ownerId;
              final d = DateTime.tryParse(m.playedAt ?? "")?.toLocal();
              final phase = m.groupName != null
                  ? "Grupo ${m.groupName}"
                  : m.round != null
                      ? matchRoundLabel(m.round!)
                      : (matchStatusLabel[m.status] ?? "");
              return CompactMatchRow(
                won: m.winnerId == null ? null : m.winnerId == ownerId,
                opponent: isP1 ? m.player2Name : m.player1Name,
                meta: [
                  if (d != null) "${d.day} ${_monthShort[d.month - 1]}",
                  m.tournamentName,
                  if (phase.isNotEmpty) phase,
                ].join(" · "),
                score: "${isP1 ? m.setsPlayer1 : m.setsPlayer2} - ${isP1 ? m.setsPlayer2 : m.setsPlayer1}",
                onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
              );
            }(),
        ]),
      ),
    ));
  });
  return out;
}
