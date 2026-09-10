import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/identicon.dart';

/// Panel "Próximo partido" con botón para ver el perfil del rival.
class SpinNextMatchPanel extends StatelessWidget {
  final String? opponentId;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SpinNextMatchPanel({
    super.key,
    this.opponentId,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.scorifyCardBorder),
      ),
      child: Row(
        children: [
          if (opponentId != null && opponentId!.isNotEmpty) ...[
            Identicon(seed: opponentId!, size: 44),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PRÓXIMO PARTIDO",
                  style: TextStyle(
                    color: AppColors.scorifyTextMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.scorifyText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
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
          const SizedBox(width: 12),
          Material(
            color: AppColors.scorifyMint,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "VER OPONENTE",
                      style: TextStyle(
                        color: AppColors.scorifyOnMint,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.person_rounded,
                      color: AppColors.scorifyOnMint,
                      size: 18,
                    ),
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
