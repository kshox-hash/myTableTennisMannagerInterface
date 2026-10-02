import 'package:myttmi/core/ui/card_border.dart';
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/ui/brand_logo.dart';
import 'package:myttmi/core/favorites/favorite_matches.dart';

/// Topbar del home: logo + notificaciones + ajustes.
class SpinHeader extends StatelessWidget {
  final int notificationsCount;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  /// Corazón: "Partidos guardados" (seguir partidos en vivo).
  final VoidCallback? onFavorites;

  const SpinHeader({
    super.key,
    this.onFavorites,
    required this.onNotifications,
    required this.onSettings,
    this.notificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CardBorder(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scorifyDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.scorifyCardBorder),
      ),
      child: Row(
        children: [
          const BrandLogo(markSize: 26, wordmarkSize: 17),
          const Spacer(),
          if (onFavorites != null) ...[
            ValueListenableBuilder<List<FavoriteMatch>>(
              valueListenable: FavoriteMatches.items,
              builder: (_, favs, __) => _IconButton(
                icon: favs.isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                count: favs.length,
                onTap: onFavorites!,
              ),
            ),
            const SizedBox(width: 10),
          ],
          _IconButton(
            icon: Icons.notifications_none_rounded,
            count: notificationsCount,
            onTap: onNotifications,
          ),
          const SizedBox(width: 10),
          _IconButton(icon: Icons.settings_outlined, onTap: onSettings),
        ],
      ),
    ));
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int count;

  const _IconButton({required this.icon, required this.onTap, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Fondo propio (antes era del mismo color que la barra y el botón
        // no se distinguía) e ícono más grande.
        Material(
          color: AppColors.scorifyInput,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: AppColors.scorifyText, size: 22),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.scorifyBadge,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.scorifyCardFill, width: 2),
              ),
              child: Text(
                count > 9 ? "9+" : "$count",
                style: const TextStyle(
                  fontFamily: AppTypography.body,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
