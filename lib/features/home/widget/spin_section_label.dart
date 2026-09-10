import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Encabezado de sección chico: barra vertical mint + texto en mayúsculas.
class SpinSectionLabel extends StatelessWidget {
  final String text;
  const SpinSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 13, color: AppColors.scorifyMint),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: AppColors.scorifyTextMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
