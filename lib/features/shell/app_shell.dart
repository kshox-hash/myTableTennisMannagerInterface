import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/navigation/deep_links.dart';
import 'package:myttmi/core/push/push_service.dart';
import 'package:myttmi/features/notifications/notification_popups.dart';
import 'package:myttmi/core/ui/app_toast.dart';
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
  static const _pulseDuration = Duration(milliseconds: 280);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  // Pestaña a la que vuelve la flecha ← cuando se llegó con un enlace
  // ("Ver estadísticas" en el Inicio). Tocando la barra de abajo no hay.
  int? _returnTab;

  void _switchTab(int index, {bool link = false}) {
    if (index == _index) return;
    final from = _index;
    setState(() => _returnTab = link ? from : null);
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
  void initState() {
    super.initState();
    // Link de campeonato que llegó antes de tener sesión (o con la app
    // cerrada): se abre ahora, encima de las pestañas.
    WidgetsBinding.instance.addPostFrameCallback((_) => DeepLinks.shellReady());
    // Con sesión: permiso de notificaciones y registro del celular.
    PushService.register();
    // Avisos tipo Facebook de las notificaciones nuevas (abajo a la izquierda).
    NotificationPopups.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El toast sube por encima de la barra de abajo mientras esta ruta esté al frente.
    ToastLayout.shellRoute = ModalRoute.of(context);
  }

  @override
  void dispose() {
    if (ToastLayout.shellRoute == ModalRoute.of(context)) ToastLayout.shellRoute = null;
    DeepLinks.shellGone();
    NotificationPopups.stop();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = CyberTransition.contentOpacity(_pulse);
    final glow = CyberTransition.glow(_pulse);

    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      bottomNavigationBar: EFBottomNav(
        currentIndex: _index,
        onTap: _switchTab,
        items: const [
          EFNavItem(label: "Inicio", icon: Icons.home_rounded),
          EFNavItem(label: "Calendario", icon: Icons.calendar_month_rounded),
          EFNavItem(label: "Mi rendimiento", icon: Icons.trending_up_rounded),
          EFNavItem(label: "Campeonatos", icon: Icons.emoji_events_outlined),
        ],
      ),
      body: PrismBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: opacity,
            // La pestaña que se va sube un poco al apagarse; la que entra
            // llega desde abajo y se asienta (mismo lenguaje que las rutas).
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, inner) {
                const cut = CyberTransition.crossoverAt;
                final t = _pulse.value;
                final dy = t == 0 || t == 1
                    ? 0.0
                    : t < cut
                        ? -8 * Curves.easeIn.transform(t / cut)
                        : 18 * (1 - Curves.easeOutCubic.transform((t - cut) / (1 - cut)));
                return Transform.translate(offset: Offset(0, dy), child: inner);
              },
              child: Stack(
                children: [
                  AppShellScope(
                    switchTab: _switchTab,
                    currentIndex: _index,
                    returnTab: _returnTab,
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
  final void Function(int index, {bool link}) switchTab;
  final int currentIndex;
  /// Pestaña de la que se vino con un enlace (para la flecha ←), o null.
  final int? returnTab;

  const AppShellScope({
    super.key,
    required this.switchTab,
    required this.currentIndex,
    this.returnTab,
    required super.child,
  });

  static AppShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      switchTab != oldWidget.switchTab ||
      currentIndex != oldWidget.currentIndex ||
      returnTab != oldWidget.returnTab;
}
