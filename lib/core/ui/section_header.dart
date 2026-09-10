import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Título de sección: barra de acento + texto en mayúsculas, con link
/// opcional "Ver todo" — mismo lenguaje visual que "Modos de juego" en el
/// home, formalizado para el resto de la app.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 13, color: AppColors.scorifyMint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.scorifyTextMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.scorifyMint,
              ),
            ),
          ),
      ],
    );
  }
}
