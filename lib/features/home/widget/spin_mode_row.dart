import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fila de "Modos de juego" (Campeonatos / Mis partidos / Rendimiento /
/// Tienda): barra de acento a la izquierda, ícono, título + subtítulo,
/// chevron.
class SpinModeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const SpinModeRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          border: Border.all(color: AppColors.scorifyCardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: accent),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.scorifyText,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.scorifyTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.scorifyTextMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
