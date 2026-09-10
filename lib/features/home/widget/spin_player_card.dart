import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/identicon.dart';

/// Tarjeta de jugador del home: solo datos reales del usuario (nombre,
/// categoría/club/edad si están disponibles) — sin OVR/nivel/atributos
/// inventados, el backend no tiene ese sistema de progresión. Toca para
/// ir al perfil.
class SpinPlayerCard extends StatelessWidget {
  final String? userId;
  final String playerName;
  final List<String> details;
  final VoidCallback? onTap;

  const SpinPlayerCard({
    super.key,
    this.userId,
    required this.playerName,
    this.details = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.scorifyCardBorder),
            gradient: AppColors.cardGradient,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userId == null || userId!.isEmpty
                  ? Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.scorifyMintDark.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.scorifyCardBorder),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.scorifyMint,
                        size: 24,
                      ),
                    )
                  : Identicon(seed: userId!, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.scorifyText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    for (final d in details) ...[
                      const SizedBox(height: 4),
                      Text(
                        d,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.scorifyTextMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.scorifyTextMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
