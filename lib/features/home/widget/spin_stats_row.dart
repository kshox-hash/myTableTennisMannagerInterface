import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

class SpinStat {
  final String label;
  final String value;
  const SpinStat({required this.label, required this.value});
}

/// Fila de 4 números grandes (PJ / G / P / %).
class SpinStatsRow extends StatelessWidget {
  final List<SpinStat> stats;

  const SpinStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.scorifyCardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    stats[i].value,
                    style: const TextStyle(
                      color: AppColors.scorifyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stats[i].label,
                    style: TextStyle(
                      color: AppColors.scorifyTextMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
