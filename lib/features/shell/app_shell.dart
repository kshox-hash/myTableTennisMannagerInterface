import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/prism_background.dart';
import 'package:myttmi/features/calendar/presentation/calendar_screen.dart';
import 'package:myttmi/features/home/presentation/home_screen.dart';
import 'package:myttmi/features/home/widget/ef_nav_bar.dart';
import 'package:myttmi/features/performance/presentation/performance_screen.dart';
import 'package:myttmi/features/tournament/presentation/tournaments_screen.dart';
import 'package:myttmi/routes/cyber_page_route.dart';

/// Shell de navegación persistente: Inicio/Calendario/Mi rendimiento/
/// Campeonatos viven como pestañas de un mismo IndexedStack en vez de pushes
/// independientes — así la barra flotante no desaparece al cambiar de sección
/// y cada pestaña conserva su estado (scroll, filtros, mes elegido) al volver.
/// "Mi rendimiento" fusiona Ranking + Estadísticas (antes 2 pestañas propias)
/// con sub-navegación interna, ver PerformanceScreen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    CalendarScreen(),
    PerformanceScreen(),
    TournamentsScreen(),
  ];

  // Mismo lenguaje que CyberPageRoute (ver cyber_page_route.dart) pero para
  // un solo widget: el IndexedStack se apaga, en el punto más bajo se
  // cambia el índice (no se ve, así que no hay salto brusco) y se vuelve
  // a encender — en vez de un cambio instantáneo sin transición.
  static const _pulseDuration = Duration(milliseconds: 480);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  void _switchTab(int index) {
    if (index == _index) return;
    _pulse.forward(from: 0);
    final delay = Duration(
      milliseconds:
          (_pulseDuration.inMilliseconds * CyberTransition.crossoverAt).round(),
    );
    Future.delayed(delay, () {
      if (mounted) setState(() => _index = index);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = CyberTransition.contentOpacity(_pulse);
    final scale = CyberTransition.contentScale(_pulse);
    final glow = CyberTransition.glow(_pulse);

    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      bottomNavigationBar: EFBottomNav(
        currentIndex: _index,
        onTap: _switchTab,
        items: const [
          EFNavItem(label: "Inicio", icon: Icons.home_rounded),
          EFNavItem(label: "Calendario", icon: Icons.calendar_month_rounded),
          EFNavItem(label: "Mi rendimiento", icon: Icons.emoji_events_rounded),
          EFNavItem(label: "Campeonatos", icon: Icons.sports_tennis_rounded),
        ],
      ),
      body: PrismBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: Stack(
                children: [
                  AppShellScope(
                    switchTab: _switchTab,
                    currentIndex: _index,
                    child: IndexedStack(index: _index, children: _tabs),
                  ),
                  CyberTransition.glowOverlay(glow),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Permite que cualquier pestaña (p.ej. el botón "Ver todos" del banner de
/// campeonatos en Home) le pida al shell que cambie de pestaña sin tener que
/// empujar una segunda instancia de esa pantalla por encima. También expone
/// qué pestaña está activa — como el IndexedStack mantiene todas las
/// pestañas vivas (no las recrea al volver), esto es lo que le permite a
/// cada una recargar sus datos sola cuando el usuario vuelve a ella, en vez
/// de necesitar un botón de actualizar manual.
class AppShellScope extends InheritedWidget {
  final void Function(int index) switchTab;
  final int currentIndex;

  const AppShellScope({
    super.key,
    required this.switchTab,
    required this.currentIndex,
    required super.child,
  });

  static AppShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      switchTab != oldWidget.switchTab ||
      currentIndex != oldWidget.currentIndex;
}
