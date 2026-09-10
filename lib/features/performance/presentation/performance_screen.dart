import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/features/ranking/presentation/ranking_screen.dart';
import 'package:myttmi/features/stats/presentation/stats_screen.dart';

/// Fusiona "Ranking" y "Estadísticas" en una sola pestaña del shell con
/// sub-navegación interna — antes eran 2 de las 5 pestañas del bottom nav
/// por separado, pero ambas responden a la misma pregunta ("¿cómo me está
/// yendo?"), así que competían por espacio en una barra ya cargada.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    // Solo el header y el switcher llevan el padding estándar de 16 — el
    // contenido de cada sub-pestaña ya trae el suyo (RankingScreen y
    // StatsScreen se usaban antes como pestañas completas del shell), así
    // que envolverlo de nuevo acá duplicaría el margen.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              const TopHeader(title: "Mi rendimiento", showBack: false),
              const SizedBox(height: 14),
              _SubTabSwitch(
                index: _sub,
                onChanged: (i) => setState(() => _sub = i),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _sub,
            children: const [
              RankingScreen(showHeader: false),
              StatsScreen(showHeader: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubTabSwitch extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SubTabSwitch({required this.index, required this.onChanged});

  static const _labels = ["Ranking", "Estadísticas"];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.scorifyCardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.scorifyCardBorder),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.scorifyMint.withOpacity(0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: selected
                      ? Border.all(
                          color: AppColors.scorifyMint.withOpacity(0.5),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: AppTypography.bodyText.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? AppColors.scorifyMint
                        : AppColors.scorifyTextMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
