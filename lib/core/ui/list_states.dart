import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'glass_card.dart';
import 'pill_button.dart';

/// Carga tipo "skeleton": tarjetas grises con la forma del contenido que
/// late suave mientras llegan los datos (en vez de un spinner o la pelota).
class LoadingState extends StatefulWidget {
  final String? label;
  final int rows;

  const LoadingState({super.key, this.label, this.rows = 4});

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(2)),
        );
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          children: [
            for (var i = 0; i < widget.rows; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(2)),
                child: Row(
                  children: [
                    Container(width: 42, height: 42, decoration: const BoxDecoration(color: AppColors.scorifySurface2, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(i.isEven ? 170 : 130, 13),
                          const SizedBox(height: 8),
                          bar(i.isEven ? 110 : 150, 10),
                        ],
                      ),
                    ),
                    bar(34, 22),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, this.icon = Icons.inbox_rounded, required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, color: AppColors.scorifyTextFaint, size: 26),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

/// A diferencia de los `Text("Error: $e")` sueltos que hay hoy repartidos por
/// toda la app, siempre trae un botón para reintentar sin tener que salir y
/// volver a entrar a la pantalla.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.scorifyNegative, size: 26),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
          const SizedBox(height: 14),
          OutlinePillButton(label: "Reintentar", onTap: onRetry),
        ],
      ),
    );
  }
}
