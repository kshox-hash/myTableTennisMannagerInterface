import 'package:flutter/material.dart';
import 'package:myttmi/core/ui/panel_style.dart';
import 'package:myttmi/core/constants/app_colors.dart';

class EFNavItem {
  final String label;
  final IconData icon;

  const EFNavItem({
    required this.label,
    required this.icon,
  });
}

/// Barra de navegación inferior plana — ícono + etiqueta, sin badge
/// elevado ni textura, con un indicador fino arriba de la pestaña activa.
class EFBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<EFNavItem> items;

  final Color? backgroundColor;
  final double height;

  const EFBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.height = 62,
  });

  @override
  Widget build(BuildContext context) {
    // Estilo panel: fondo del panel (casi negro verdoso) con la línea
    // encendida verde azulado arriba, como el borde superior de las tarjetas.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: backgroundColor == null
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E1D20), Color(0xFF080D0F)],
              )
            : null,
        border: const Border(top: BorderSide(color: Panel.topLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Expanded(
                child: _NavTab(
                  item: item,
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final EFNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.scorifyMint : AppColors.scorifyText.withOpacity(0.45);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 2,
            width: 22,
            margin: const EdgeInsets.only(bottom: 6),
            color: isActive ? AppColors.scorifyMint : Colors.transparent,
          ),
          Icon(item.icon, size: 21, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
