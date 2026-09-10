import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';

/// Campo de texto compartido entre Login y Registro — misma decoración
/// oscura/glass en las dos pantallas en vez de dos formularios Material por
/// defecto sin relación con el resto de la app.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMuted,
        prefixIcon: Icon(icon, color: AppColors.scorifyTextMuted, size: 20),
        filled: true,
        fillColor: AppColors.scorifyCardFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.4),
        ),
      ),
    );
  }
}
