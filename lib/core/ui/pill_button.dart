import 'package:myttmi/core/ui/app_button.dart';
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

/// Botón pill sólido VERDE (como el primario de la web) — acción principal.
class SolidPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const SolidPillButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return _PopIn(child: AppButton(label: label, onPressed: onTap, icon: icon, expand: false));
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
    return _PopIn(child: AppButton.outline(label: label, onPressed: onTap, icon: icon, expand: false));
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

    switch (tone) {
      case ChipTone.neutral:
        fg = AppColors.scorifyTextMuted;
        bg = Colors.white.withOpacity(0.06);
        break;
      case ChipTone.positive:
        fg = AppColors.scorifyMint;
        bg = AppColors.scorifyMint.withOpacity(0.14);
        break;
      case ChipTone.negative:
        fg = AppColors.scorifyNegative;
        bg = AppColors.scorifyNegative.withOpacity(0.14);
        break;
      case ChipTone.pending:
        fg = AppColors.scorifyPending;
        bg = AppColors.scorifyPending.withOpacity(0.14);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: bg,

      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}
