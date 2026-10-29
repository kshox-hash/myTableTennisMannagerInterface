import 'package:myttmi/core/ui/ui_sound.dart';
import 'package:flutter/material.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/ui/brand_logo.dart';
import 'package:myttmi/core/favorites/favorite_matches.dart';
import 'package:myttmi/core/ui/top_header.dart';

/// Topbar del home: logo + notificaciones + ajustes.
class SpinHeader extends StatelessWidget {
  final int notificationsCount;
  final VoidCallback onNotifications;
  final VoidCallback? onSettings;
  /// Corazón: "Partidos guardados" (seguir partidos en vivo).
  final VoidCallback? onFavorites;

  const SpinHeader({
    super.key,
    this.onFavorites,
    required this.onNotifications,
    this.onSettings,
    this.notificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.zero, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          if (AppShellScope.of(context)?.openMenu != null) ...[
            _IconButton(icon: Icons.menu_rounded, onTap: AppShellScope.of(context)!.openMenu!),
            const SizedBox(width: 10),
          ],
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
          const SizedBox(width: 8),
          // Tu foto: abre tu perfil (antes estaba en el menú lateral).
          const MyAvatarButton(size: 42),
          if (onSettings != null) ...[const SizedBox(width: 8), _IconButton(icon: Icons.settings_rounded, onTap: onSettings!)],
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
            onTap: () {
              UiSound.tap();
              onTap();
            },
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
                borderRadius: BorderRadius.circular(99), // contador redondo, igual que en las demás pantallas
                border: Border.all(color: AppColors.scorifyCardFill, width: 2),
              ),
              child: Text(
                count > 9 ? "9+" : "$count",
                style: const TextStyle(
                  fontFamily: AppTypography.body,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
