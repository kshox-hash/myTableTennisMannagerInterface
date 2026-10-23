import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de toda la app: azul marino liso (sin degradados ni resplandores,
/// a pedido — ver AppColors). Se deja el widget para no tocar a las
/// pantallas que lo envuelven.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(color: AppColors.scorifyBg, child: child);
}
