import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';

/// Encabezado estándar para pantallas empujadas (detalle de torneo, partidos,
/// inscritos, perfil, etc.) — reemplaza el <code>AppBar</code> Material por
/// defecto que usan hoy 11 de las 16 pantallas de la app.
class TopHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  const TopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack && Navigator.canPop(context)) ...[
          HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.h1),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMuted.copyWith(fontSize: 11.5),
                ),
              ],
            ],
          ),
        ),
        if (actions != null) ...[
          const SizedBox(width: 10),
          ...actions!,
        ],
      ],
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HeaderIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.scorifyMint.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.scorifyCardBorder),
          ),
          child: Icon(icon, color: AppColors.scorifyText, size: 18),
        ),
      ),
    );
  }
}
