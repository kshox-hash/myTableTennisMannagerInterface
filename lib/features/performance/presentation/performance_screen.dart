import 'package:flutter/material.dart';
import 'package:myttmi/core/ui/app_button.dart';
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
            // Estadísticas primero: el ranking global espera la tabla oficial
            // de puntos por nivel, y mientras tanto suele estar vacío.
            children: const [
              StatsScreen(showHeader: false),
              RankingScreen(showHeader: false),
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

  static const _labels = ["Estadísticas", "Ranking"];

  @override
  Widget build(BuildContext context) {
    // Mismo selector tipo píldora que Partidos/Campeonatos.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.scorifyCardFill,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: selected ? appButtonGradient : null,
                borderRadius: BorderRadius.circular(99),
                border: selected ? Border.all(color: Colors.white.withValues(alpha: 0.35)) : null,
              ),
              child: Material(
              color: Colors.transparent,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(99))),
              child: InkWell(
                onTap: () {
                  onChanged(i);
                },
                customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(99))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.scorifyOnMint : AppColors.scorifyText,
                      ),
                    ),
                  ),
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
