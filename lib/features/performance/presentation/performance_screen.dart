import 'package:flutter/material.dart';
import 'package:myttmi/core/ui/app_button.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/core/ui/page_skeleton.dart';
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
  // Esqueleto de la pestaña entera hasta que las estadísticas cargan la
  // primera vez (antes se veían el título y el selector y, abajo, el bloque
  // cargando por separado).
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    // El título y el selector van DENTRO del scroll de cada sub-pestaña (que
    // ya trae el padding de 16): suben junto con el contenido en vez de
    // quedarse fijos con la lista pasando por debajo.
    final header = Column(
      children: [
        const TopHeader(title: "Mi rendimiento", showBack: false),
        const SizedBox(height: 14),
        _SubTabSwitch(index: _sub, onChanged: (i) => setState(() => _sub = i)),
      ],
    );
    return Stack(
      children: [
        IndexedStack(
          index: _sub,
          // Estadísticas primero: el ranking global espera la tabla oficial
          // de puntos por nivel, y mientras tanto suele estar vacío.
          children: [
            StatsScreen(
              showHeader: false,
              header: header,
              onLoaded: () {
                if (!_ready && mounted) setState(() => _ready = true);
              },
            ),
            RankingScreen(showHeader: false, header: header),
          ],
        ),
        if (!_ready) const Positioned.fill(child: PageSkeleton()),
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
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(99)),
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
                        _labels[i].toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.display,
                          fontSize: 19,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.6,
                          height: 1.0,
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
