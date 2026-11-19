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
        // Mismo título de sección que el resto de la app (mayúsculas azul hielo, sin barrita).
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.scorifyMint,
              ),
            ),
          ),
      ],
    );
  }
}
