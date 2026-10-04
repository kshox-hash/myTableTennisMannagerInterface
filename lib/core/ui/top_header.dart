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
  /// Volver propio (p. ej. a la pestaña de la que vino); se muestra siempre.
  final VoidCallback? onBack;

  const TopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null || (showBack && Navigator.canPop(context))) ...[
          BackCircleButton(onTap: onBack ?? () => Navigator.pop(context)),
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

/// Botón de volver: círculo con borde fino y flecha ‹, sin relleno.
class BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const BackCircleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.scorifyText.withValues(alpha: 0.75), width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.chevron_left_rounded, color: AppColors.scorifyText, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Botón para pasar de página dentro de una tarjeta (‹ ›): cuadradito
/// oscuro con borde; distinto al de volver.
class PagerButton extends StatelessWidget {
  final bool next;
  final VoidCallback? onTap;
  const PagerButton({super.key, required this.next, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 20, color: AppColors.scorifyText.withValues(alpha: enabled ? 0.9 : 0.25)),
        ),
      ),
    );
  }
}
