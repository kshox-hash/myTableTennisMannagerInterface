import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/calendar/presentation/calendar_screen.dart";
import "package:myttmi/features/stats/presentation/stats_screen.dart";
import "package:myttmi/features/tournament/presentation/following_screen.dart";
import "package:myttmi/features/tournament/presentation/history_screen.dart";
import "package:myttmi/features/tournament/presentation/tournaments_screen.dart";

/// Sección de la barra de abajo con pestañas arriba (Todos / Míos / …):
/// un solo encabezado y debajo la pantalla de la pestaña elegida. Las
/// pestañas se construyen recién la primera vez que se abren y después
/// quedan vivas (no recargan al volver).
class SectionHub extends StatefulWidget {
  final String title;
  final List<(String, Widget)> tabs;
  /// Pestaña elegida; se puede cambiar desde afuera (p. ej. "Calendario"
  /// del Inicio abre Campeonatos en "Míos").
  final ValueNotifier<int> selected;
  const SectionHub({super.key, required this.title, required this.tabs, required this.selected});

  @override
  State<SectionHub> createState() => _SectionHubState();
}

class _SectionHubState extends State<SectionHub> {
  final Set<int> _built = {};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.selected,
      builder: (context, sel, _) {
        _built.add(sel);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TopHeader(title: widget.title, showBack: false),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HubTabs(
                labels: [for (final t in widget.tabs) t.$1],
                selected: sel,
                onTap: (i) => widget.selected.value = i,
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: sel,
                children: [
                  for (var i = 0; i < widget.tabs.length; i++)
                    _built.contains(i) ? widget.tabs[i].$2 : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pestañas de la sección: mismo estilo que los filtros (color de tarjeta,
/// filete fino; la elegida en blanco con la línea azul abajo).
class _HubTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;
  const _HubTabs({required this.labels, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, border: Border.all(color: AppColors.scorifyHairline)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) Container(width: 1, height: 20, color: AppColors.scorifyHairline),
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.scorifySelected : Colors.transparent,
                    border: i == selected ? Border(bottom: BorderSide(color: AppColors.scorifyMint, width: 2)) : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 13,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                      color: i == selected ? AppColors.scorifyInk : AppColors.scorifyTextMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Campeonatos: Todos (buscar e inscribirse) · Míos (antes "Calendario") ·
/// Siguiendo (antes "Campeonatos que sigo", con acceso a Partidos guardados).
class CompetitionsHub extends StatelessWidget {
  const CompetitionsHub({super.key});

  static final segment = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => SectionHub(
        title: "Campeonatos",
        selected: segment,
        tabs: const [
          ("Todos", TournamentsScreen(embedded: true)),
          ("Míos", CalendarScreen(embedded: true)),
          ("Siguiendo", FollowingScreen(embedded: true)),
        ],
      );
}

/// Mi juego: Rendimiento (antes "Mi rendimiento") · Historial (todos tus
/// partidos jugados; antes estaba aparte en el menú).
class MyGameHub extends StatelessWidget {
  const MyGameHub({super.key});

  static final segment = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => SectionHub(
        title: "Mi juego",
        selected: segment,
        tabs: const [
          ("Rendimiento", StatsScreen(showHeader: false)),
          ("Historial", HistoryScreen(embedded: true)),
        ],
      );
}
