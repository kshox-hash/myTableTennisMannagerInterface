import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'glass_card.dart';
import 'pill_button.dart';

class LoadingState extends StatelessWidget {
  final String? label;

  const LoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint),
          ),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(label!, style: AppTypography.bodyMuted),
          ],
        ],
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
