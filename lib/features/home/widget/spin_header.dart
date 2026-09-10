import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/brand_logo.dart';

/// Topbar del home: logo + notificaciones + ajustes.
class SpinHeader extends StatelessWidget {
  final int notificationsCount;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  const SpinHeader({
    super.key,
    required this.onNotifications,
    required this.onSettings,
    this.notificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _IconButton(
            icon: Icons.notifications_none_rounded,
            count: notificationsCount,
            onTap: onNotifications,
          ),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.settings_outlined, onTap: onSettings),
        ],
      ),
    );
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
        Material(
          color: AppColors.scorifyCardFill,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.scorifyCardBorder),
              ),
              child: Icon(
                icon,
                color: AppColors.scorifyText.withOpacity(0.85),
                size: 18,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.scorifyBadge,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? "9+" : "$count",
                style: const TextStyle(
                  color: AppColors.scorifyText,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
