import "package:myttmi/core/ui/ui_sound.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
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
  // Sin bloque de perfil arriba (con la foto ponía lento el menú): tu
  // perfil se abre desde "Mi perfil" o desde tu avatar en el encabezado.
  final VoidCallback onLogout;
  const AppDrawer({
    super.key,
    required this.main,
    required this.more,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(DrawerItem it) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Panel.buttonRadius),
            child: InkWell(
              onTap: () {
                UiSound.tap();
                Navigator.pop(context);
                it.onTap();
              },
              borderRadius: BorderRadius.circular(Panel.buttonRadius),
              child: Ink(
                // Estilo panel: el elegido con el degradado del botón principal.
                decoration: BoxDecoration(
                  gradient: it.selected ? Panel.primaryButtonGradient : null,
                  borderRadius: BorderRadius.circular(Panel.buttonRadius),
                  border: it.selected ? Border.all(color: Panel.primaryButtonBorder) : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Icon(it.icon, size: 22, color: it.selected ? AppColors.scorifyMint : AppColors.scorifyText),
                    const SizedBox(width: 14),
                    Text(
                      it.label,
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 15,
                        fontWeight: it.selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.scorifyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Drawer(
      backgroundColor: Panel.sheetColor,
      width: 290,
      // Sin bordes alrededor (se veía como un cuadrado): solo el filete del
      // lado que da hacia el centro de la app, con la línea encendida.
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Panel.topLine))),
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 14),
              child: Align(alignment: Alignment.centerLeft, child: BrandLogo(markSize: 28, wordmarkSize: 19)),
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
      ),
    );
  }
}
