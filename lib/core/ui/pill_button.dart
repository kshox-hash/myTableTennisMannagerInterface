import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';

/// Animación de entrada "pop" (escala con rebote + fade-in) — se dispara una
/// sola vez cuando el botón aparece en pantalla (al cargar la pantalla, o al
/// entrar a la lista), no en cada rebuild.
class _PopIn extends StatelessWidget {
  final Widget child;

  const _PopIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: child,
    );
  }
}

/// Botón pill sólido (mint) — acción principal ("VER", "Suscribirme", "Confirmar").
class SolidPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const SolidPillButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return _PopIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(color: AppColors.scorifyMint, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppColors.scorifyOnMint),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTypography.button.copyWith(color: AppColors.scorifyOnMint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón pill con borde — acción secundaria ("Cancelar", "Reintentar").
class OutlinePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const OutlinePillButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return _PopIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.scorifyCardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppColors.scorifyText),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTypography.button.copyWith(color: AppColors.scorifyText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ChipTone { neutral, positive, negative, pending }

/// Chip informativo chico (grupo/ronda/mesa/estado). El tono semántico es
/// independiente del acento de marca: mint = positivo, no "el color de la app".
class InfoChip extends StatelessWidget {
  final String label;
  final ChipTone tone;

  const InfoChip({super.key, required this.label, this.tone = ChipTone.neutral});

  @override
  Widget build(BuildContext context) {
    late final Color fg;
    late final Color bg;
    late final Color border;

    switch (tone) {
      case ChipTone.neutral:
        fg = AppColors.scorifyTextMuted;
        bg = Colors.white.withOpacity(0.06);
        border = Colors.white.withOpacity(0.10);
        break;
      case ChipTone.positive:
        fg = AppColors.scorifyMint;
        bg = AppColors.scorifyMint.withOpacity(0.14);
        border = AppColors.scorifyCardBorder;
        break;
      case ChipTone.negative:
        fg = AppColors.scorifyNegative;
        bg = AppColors.scorifyNegative.withOpacity(0.14);
        border = AppColors.scorifyNegative.withOpacity(0.35);
        break;
      case ChipTone.pending:
        fg = AppColors.scorifyPending;
        bg = AppColors.scorifyPending.withOpacity(0.14);
        border = AppColors.scorifyPending.withOpacity(0.35);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}
