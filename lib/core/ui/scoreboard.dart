import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Marcador de un partido, estilo TV: cada jugador en su franja (la de
/// arriba un tono más clara que la de abajo, así se separan de un vistazo),
/// los sets ganados grandes a la derecha y, al lado, los puntos de cada set
/// en columnas. El ganador del partido en negrita; en cada set, quien lo
/// ganó en blanco y el otro en gris.
///
/// [setColumns] fija cuántas columnas de set dibujar (la del partido más
/// largo de la lista) para que varios marcadores queden alineados.
class Scoreboard extends StatelessWidget {
  final String player1;
  final String player2;
  final int? sets1;
  final int? sets2;
  /// 1 o 2 si ya hay ganador; null si no se jugó.
  final int? winner;
  final List<(int, int)> setScores;
  final int setColumns;
  /// Sin resultado (por jugar): solo los nombres, sin números.
  final bool showScore;
  final double nameSize;
  final double setsSize;
  /// A la derecha de las franjas (p. ej. "Mesa 3" o "Por jugar").
  final Widget? trailing;

  const Scoreboard({
    super.key,
    required this.player1,
    required this.player2,
    this.sets1,
    this.sets2,
    this.winner,
    this.setScores = const [],
    this.setColumns = 0,
    this.showScore = true,
    this.nameSize = 13,
    this.setsSize = 15,
    this.trailing,
  });

  // Franjas: arriba más clara, abajo más oscura (sobre la tarjeta).
  static const _bandTop = Color(0x17FFFFFF);
  static const _bandBottom = Color(0x08FFFFFF);

  @override
  Widget build(BuildContext context) {
    final cols = setColumns > setScores.length ? setColumns : setScores.length;
    Widget band(String name, int? sets, bool first) {
      final won = winner == (first ? 1 : 2);
      final lost = winner != null && !won;
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        color: first ? _bandTop : _bandBottom,
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: nameSize,
                  fontWeight: won ? FontWeight.w800 : FontWeight.w600,
                  color: lost ? AppColors.scorifyTextMuted : AppColors.scorifyText,
                ),
              ),
            ),
            if (showScore) ...[
              SizedBox(
                width: setsSize * 1.6,
                child: Text(
                  sets == null ? "" : "$sets",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: setsSize,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: won ? AppColors.scorifyMint : (lost ? AppColors.scorifyTextFaint : AppColors.scorifyText),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (cols > 0) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: nameSize + 4, color: const Color(0x1FFFFFFF)),
                const SizedBox(width: 2),
                for (var k = 0; k < cols; k++)
                  SizedBox(
                    width: nameSize * 1.9,
                    child: k >= setScores.length
                        ? null
                        : Builder(builder: (_) {
                            final mine = first ? setScores[k].$1 : setScores[k].$2;
                            final theirs = first ? setScores[k].$2 : setScores[k].$1;
                            final tookIt = mine > theirs;
                            return Text(
                              "$mine",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppTypography.body,
                                fontSize: nameSize - 0.5,
                                fontWeight: tookIt ? FontWeight.w700 : FontWeight.w500,
                                color: tookIt ? AppColors.scorifyText : AppColors.scorifyTextFaint,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            );
                          }),
                  ),
              ],
            ],
          ],
        ),
      );
    }

    final board = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [band(player1, sets1, true), band(player2, sets2, false)],
      ),
    );
    if (trailing == null) return board;
    return Row(
      children: [
        Expanded(child: board),
        const SizedBox(width: 10),
        SizedBox(width: 64, child: Align(alignment: Alignment.centerRight, child: trailing)),
      ],
    );
  }
}
