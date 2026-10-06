import "package:flutter/material.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/brand_logo.dart";

/// Opción del menú lateral.
class DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  DrawerItem(this.icon, this.label, this.onTap, {this.selected = false});
}

/// Menú lateral (☰): reemplaza la barra de navegación de abajo. Arriba las
/// secciones principales (la actual destacada con el degradado) y, bajo una
/// línea, los accesos secundarios.
class AppDrawer extends StatelessWidget {
  final List<DrawerItem> main;
  final List<DrawerItem> more;
  /// Tu perfil arriba (foto, nombre, "Ver perfil").
  final String? name;
  final String? userId;
  final String? avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  const AppDrawer({
    super.key,
    required this.main,
    required this.more,
    this.name,
    this.userId,
    this.avatarUrl,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(DrawerItem it) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                it.onTap();
              },
              borderRadius: BorderRadius.circular(99),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: it.selected ? appButtonGradient : null,
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Icon(it.icon, size: 22, color: it.selected ? AppColors.scorifyOnMint : AppColors.scorifyText),
                    const SizedBox(width: 14),
                    Text(
                      it.label,
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 15,
                        fontWeight: it.selected ? FontWeight.w700 : FontWeight.w500,
                        color: it.selected ? AppColors.scorifyOnMint : AppColors.scorifyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Drawer(
      backgroundColor: AppColors.scorifyDeep,
      width: 290,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 14),
              child: Align(alignment: Alignment.centerLeft, child: BrandLogo(markSize: 28, wordmarkSize: 19)),
            ),
            // Tu perfil.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    onProfile();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: appButtonGradient),
                          child: UserAvatar(userId: userId, url: avatarUrl, size: 44),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name ?? "Mi perfil",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                              const Text("Ver perfil",
                                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.scorifyMint)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final it in main) tile(it),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Divider(height: 1, color: Color(0x1FFFFFFF)),
            ),
            for (final it in more) tile(it),
            const Spacer(),
            tile(DrawerItem(Icons.logout_rounded, "Cerrar sesión", onLogout)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
