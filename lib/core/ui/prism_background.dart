import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de toda la app: azul marino liso. Sin degradados a propósito —
/// prioridad a la fluidez del scroll (el diseño se retoma después).
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(color: AppColors.scorifyBg, child: child);
}
