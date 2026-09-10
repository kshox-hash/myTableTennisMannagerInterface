import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/player/models/achievement_model.dart";

/// Fila de un logro (medalla + torneo/categoría + puesto) — compartida por
/// Perfil propio y perfil público de otro jugador.
class AchievementRow extends StatelessWidget {
  final PlayerAchievement achievement;
  const AchievementRow({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final color = achievement.position == 1
        ? AppColors.scorifyMint
        : AppColors.scorifyTextMuted;
    return Row(
      children: [
        Text(achievement.medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.tournamentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(achievement.categoryLabel, style: AppTypography.bodyMuted),
            ],
          ),
        ),
        Text(
          achievement.positionLabel,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Card completa de "Logros" — medallero de un jugador, oculta sola si no
/// tiene ninguna categoría finalizada en el podio todavía.
class AchievementsCard extends StatelessWidget {
  final List<PlayerAchievement> achievements;
  const AchievementsCard({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.scorifyMint.withOpacity(0.35)),
          gradient: AppColors.cardGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.scorifyMint,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text("Logros", style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < achievements.length; i++) ...[
              if (i > 0)
                Divider(height: 20, color: Colors.white.withOpacity(0.06)),
              AchievementRow(achievement: achievements[i]),
            ],
          ],
        ),
      ),
    );
  }
}
