import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'glass_card.dart';
import 'identicon.dart';

/// Fila de partido tipo marcador (avatar vs. avatar + resultado) — compartida
/// por Historial, Perfil público y Mi categoría. Antes era una fila de
/// ícono G/P + nombre; ahora replica el formato "scoreboard" del resto de
/// la app (mismo lenguaje que la card de próximo partido del home).
class MatchHistoryRow extends StatelessWidget {
  final String opponentName;
  final String? opponentId;
  final String meta;
  final bool? won; // null = todavía no se jugó / no aplica
  final String? scoreText;
  final VoidCallback? onTap;

  const MatchHistoryRow({
    super.key,
    required this.opponentName,
    this.opponentId,
    required this.meta,
    this.won,
    this.scoreText,
    this.onTap,
  });

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == "—" || trimmed == "Vacante") return "?";
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = won == null
        ? AppColors.scorifyTextFaint
        : (won! ? AppColors.scorifyMint : AppColors.scorifyNegative);
    final played = scoreText != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        borderColor: won == null ? null : resultColor.withOpacity(0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ),
                if (won != null)
                  Text(
                    won! ? "GANASTE" : "PERDISTE",
                    style: AppTypography.caption.copyWith(color: resultColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const _ScoreAvatar(label: "TÚ", accent: AppColors.scorifyMint),
                Expanded(
                  child: Center(
                    child: played
                        ? Text(
                            scoreText!,
                            style: AppTypography.displayMd.copyWith(
                              fontSize: 26,
                            ),
                          )
                        : Text(
                            "VS",
                            style: AppTypography.displayMd.copyWith(
                              color: AppColors.scorifyTextFaint,
                            ),
                          ),
                  ),
                ),
                opponentId != null && opponentId!.isNotEmpty
                    ? Identicon(seed: opponentId!, size: 40)
                    : _ScoreAvatar(
                        label: _initials(opponentName),
                        accent: AppColors.scorifyTextFaint,
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Tú",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    opponentName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreAvatar extends StatelessWidget {
  final String label;
  final Color accent;
  const _ScoreAvatar({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w900,
          fontFamily: AppTypography.body,
          fontSize: 13,
        ),
      ),
    );
  }
}
