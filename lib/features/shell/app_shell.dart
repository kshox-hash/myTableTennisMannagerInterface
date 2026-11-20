import "package:myttmi/features/shell/settings_screen.dart";
import "package:myttmi/features/referee/referee_scan_screen.dart";
import "package:myttmi/features/shell/section_hubs.dart";
import "package:myttmi/features/home/widget/ef_nav_bar.dart";
import 'package:flutter/foundation.dart';
import 'package:myttmi/core/app_update.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myttmi/core/constants/app_config.dart';
import 'package:myttmi/features/shell/splash_gate.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/confirm_dialog.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/routes/app_routes.dart';
import 'package:myttmi/features/shell/app_drawer.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/navigation/deep_links.dart';
import 'package:myttmi/core/push/push_service.dart';
import 'package:myttmi/features/notifications/notification_popups.dart';
import 'package:myttmi/core/ui/app_toast.dart';
import 'package:myttmi/core/ui/prism_background.dart';
import 'package:myttmi/features/home/presentation/home_screen.dart';
import 'package:myttmi/features/ranking/presentation/ranking_screen.dart';
import "package:myttmi/features/player/presentation/celebration_dialog.dart";
import 'package:myttmi/routes/cyber_page_route.dart';

/// Shell de navegación persistente: Inicio/Calendario/Mi rendimiento/
/// Campeonatos viven como pestañas de un mismo IndexedStack en vez de pushes
/// independientes — así la barra flotante no desaparece al cambiar de sección
/// y cada pestaña conserva su estado (scroll, filtros, mes elegido) al volver.
/// "Mi rendimiento" (estadísticas) y "Ranking" son pestañas separadas. Ranking
/// va al final del IndexedStack para no cambiar el índice de Campeonatos (3),
/// al que saltan los enlaces del Inicio.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Al volver a la app (desde WhatsApp, etc.): ¿terminó algún campeonato
  // mientras tanto? Se muestra la celebración sin tener que reiniciarla.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) Celebrations.check(context);
  }

  int _index = 0;
  // Pestañas ya abiertas al menos una vez. Antes las 5 se armaban al abrir
  // la app y todas pedían sus datos a la vez (~10 consultas extra que
  // competían con las del Inicio y lo hacían tardar). Ahora cada una carga
  // recién la primera vez que se visita y después queda viva (IndexedStack).
  final Set<int> _opened = {0};

  // Índices fijos (otras pantallas llaman switchTab(3) para Campeonatos):
  // 0 Inicio · 1 (antes Calendario: ahora redirige a Campeonatos › Míos) ·
  // 2 Mi juego · 3 Campeonatos · 4 Ranking.
  static const _tabs = [
    HomeScreen(),
    SizedBox.shrink(),
    MyGameHub(),
    CompetitionsHub(),
    RankingScreen(),
  ];

  /// Barra de abajo: Inicio · Campeonatos · Ranking · Mi juego.
  static const _navTabs = [0, 3, 4, 2];

  // Mismo lenguaje que CyberPageRoute (ver cyber_page_route.dart) pero para
  // un solo widget: el IndexedStack se apaga, en el punto más bajo se
  // cambia el índice (no se ve, así que no hay salto brusco) y se vuelve
  // a encender — en vez de un cambio instantáneo sin transición.
  static const _pulseDuration = Duration(milliseconds: 420);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  // Pestaña a la que vuelve la flecha ← cuando se llegó con un enlace
  // ("Ver estadísticas" en el Inicio). Tocando la barra de abajo no hay.
  int? _returnTab;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  /// Navegador de las pestañas: lo que se abre desde una pestaña (campeonato,
  /// perfil, partido…) va acá adentro, así la barra de abajo no desaparece.
  final _tabNav = GlobalKey<NavigatorState>();
  bool _nestedCanPop = false;
  late final _nestedObserver = _NestedObserver(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final can = _tabNav.currentState?.canPop() ?? false;
      if (can != _nestedCanPop) setState(() => _nestedCanPop = can);
    });
  });
  Future<void> _loadMe() async {
    try {
      CurrentUser.me.value = await ProfileApi().getMe();
    } catch (_) {}
  }

  Future<void> _openProfile() async {
    await _tabNav.currentState?.pushNamed(AppRoutes.profile);
    _loadMe();
  }

  /// Ajustes: pantalla con Arbitraje, Ayuda y Cuenta (antes una hoja).
  Future<void> _openSettings() async {
    await _tabNav.currentState?.push(CyberPageRoute(
      builder: (_) => SettingsScreen(
        versionLabel: AppUpdate.label,
        sections: [
          ("Arbitraje", [
            SettingsOption(
              icon: Icons.qr_code_scanner_rounded,
              title: "Arbitrar con QR",
              subtitle: "Escanea el código de la mesa para anotar el partido",
              onTap: () => _tabNav.currentState?.push(CyberPageRoute(builder: (_) => const RefereeScanScreen())),
            ),
          ]),
          ("Ayuda", [
            SettingsOption(
              icon: Icons.help_outline_rounded,
              title: "Ayuda y contacto",
              subtitle: "Reportar un problema o hacer una consulta",
              onTap: _contactSupport,
            ),
            SettingsOption(
              icon: Icons.privacy_tip_outlined,
              title: "Política de privacidad",
              external: true,
              onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication),
            ),
          ]),
          ("Cuenta", [
            SettingsOption(icon: Icons.logout_rounded, title: "Cerrar sesión", onTap: _logout),
            SettingsOption(icon: Icons.delete_forever_rounded, title: "Eliminar cuenta", danger: true, onTap: _deleteAccount),
          ]),
        ],
      ),
    ));
  }

  // Correo a soporte con la versión y el celular ya escritos (lo primero que
  // hay que saber para revisar un problema).
  Future<void> _contactSupport() async {
    final body = "\n\n—\nVersión de la app: ${AppUpdate.label}\nCelular: ${defaultTargetPlatform.name}";
    final uri = Uri(
      scheme: "mailto",
      path: AppConfig.supportEmail,
      query: "subject=${Uri.encodeComponent("Ayuda MyTTM")}&body=${Uri.encodeComponent(body)}",
    );
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      showToast(context, "Escríbenos a ${AppConfig.supportEmail}");
    }
  }

  // Exigido por Google Play: la cuenta se puede borrar desde la app. Doble
  // confirmación porque no se puede deshacer.
  Future<void> _deleteAccount() async {
    final ok = await confirmAction(
      context,
      title: "Eliminar cuenta",
      message:
          "Se borrarán tu nombre, email, foto y ficha de jugador. Tus resultados de partidos quedarán como \"Jugador eliminado\". Esto no se puede deshacer.",
      confirmLabel: "Continuar",
      danger: true,
    );
    if (!ok || !mounted) return;
    final sure = await confirmAction(
      context,
      title: "¿Seguro?",
      message: "Tu cuenta se eliminará ahora y no podrás recuperarla.",
      confirmLabel: "Eliminar mi cuenta",
      danger: true,
    );
    if (!sure) return;
    try {
      await ProfileApi().deleteAccount();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
      return;
    }
    await PushService.unregister();
    await SessionStorage().clearAll();
    if (!mounted) return;
    showToast(context, "Tu cuenta fue eliminada.");
    Navigator.pushAndRemoveUntil(context, CyberPageRoute(builder: (_) => const SplashGate()), (route) => false);
  }

  Future<void> _logout() async {
    final ok = await confirmAction(
      context,
      title: "Cerrar sesión",
      message: "¿Quieres cerrar sesión y volver al inicio de sesión?",
      confirmLabel: "Cerrar sesión",
      danger: true,
    );
    if (!ok) return;
    await PushService.unregister();
    await SessionStorage().clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, CyberPageRoute(builder: (_) => const SplashGate()), (route) => false);
  }

  void _switchTab(int index, {bool link = false}) {
    // "Calendario" ya no es pestaña propia: es "Míos" dentro de Campeonatos.
    if (index == 1) {
      CompetitionsHub.segment.value = 1;
      index = 3;
    }
    _tabNav.currentState?.popUntil((r) => r.isFirst);
    if (index == _index) return;
    final from = _index;
    // Al Inicio no se "vuelve": es la raíz.
    setState(() => _returnTab = link && index != 0 ? from : null);
    _pulse.forward(from: 0);
    final delay = Duration(
      milliseconds:
          (_pulseDuration.inMilliseconds * CyberTransition.crossoverAt).round(),
    );
    Future.delayed(delay, () {
      if (mounted) {
        setState(() {
          _opened.add(index);
          _index = index;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Link de campeonato que llegó antes de tener sesión (o con la app
    // cerrada): se abre ahora, encima de las pestañas.
    WidgetsBinding.instance.addPostFrameCallback((_) => DeepLinks.shellReady());
    // Con sesión: permiso de notificaciones y registro del celular. Después
    // (para no encimar ventanas), si hay una versión nueva publicada se
    // sugiere una vez.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushService.register();
      if (mounted) await AppUpdate.suggest(context);
    });
    // Avisos tipo Facebook de las notificaciones nuevas (abajo a la izquierda).
    NotificationPopups.start();
    // Posición final de un campeonato recién terminado (aparece sola).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Celebrations.check(context);
      });
    });
    _loadMe();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El toast sube por encima de la barra de abajo mientras esta ruta esté al frente.
    ToastLayout.shellRoute = ModalRoute.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    return PopScope(
      canPop: _index == 0 && !_nestedCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _tabNav.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          _switchTab(_returnTab ?? 0);
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scorifyBg,
      // Secciones en la barra de abajo; el menú (☰) queda para lo que no
      // es una sección: arbitrar, ajustes y cerrar sesión.
      drawer: AppDrawer(
        main: [
          DrawerItem(Icons.person_rounded, "Mi perfil", _openProfile),
          DrawerItem(Icons.settings_rounded, "Ajustes", _openSettings),
        ],
        more: const [],
        onLogout: _logout,
      ),
      bottomNavigationBar: EFBottomNav(
        currentIndex: _navTabs.contains(_index) ? _navTabs.indexOf(_index) : 0,
        onTap: (i) => _switchTab(_navTabs[i]),
        items: const [
          EFNavItem(label: "Inicio", icon: Icons.home_rounded),
          EFNavItem(label: "Campeonatos", icon: Icons.emoji_events_rounded),
          EFNavItem(label: "Ranking", icon: Icons.leaderboard_rounded),
          EFNavItem(label: "Mi juego", icon: Icons.trending_up_rounded),
        ],
      ),
      body: PrismBackground(
        // Inicio tiene su propio fondo; el resto de las pestañas, el general.
        asset: _index == 0 ? PrismBackground.homeAsset : null,
        // El Inicio con el fondo "normal"; las demás pestañas, más oscuro.
        bright: _index == 0,
        // Campeonatos (a donde lleva "Tu próximo desafío"): sin foto, degradado cobalto.
        gradientOnly: _index == 0 || _index == 3,
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
                        // La que se va baja un poco; la que entra sube desde abajo.
                        ? 14 * Curves.easeInCubic.transform(t / cut)
                        : 22 * (1 - CyberTransition.premium.transform((t - cut) / (1 - cut)));
                return Transform.translate(offset: Offset(0, dy), child: inner);
              },
              child: Stack(
                children: [
                  AppShellScope(
                    switchTab: _switchTab,
                    currentIndex: _index,
                    returnTab: _returnTab,
                    openMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    openProfile: _openProfile,
                    child: Navigator(
                      key: _tabNav,
                      observers: [_nestedObserver],
                      onGenerateRoute: (settings) {
                        if (settings.name == Navigator.defaultRouteName) {
                          return PageRouteBuilder(
                            settings: settings,
                            pageBuilder: (_, __, ___) => _TabsHost(tabs: _tabs, opened: _opened),
                          );
                        }
                        return AppRoutes.onGenerateRoute(settings);
                      },
                    ),
                  ),
                  CyberTransition.glowOverlay(glow),
                ],
              ),
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
/// Tu perfil, cargado una vez por el shell y compartido: el avatar del
/// encabezado (al lado de la campana) lo lee de acá en vez de pedirlo de
/// nuevo en cada pantalla.
class CurrentUser {
  CurrentUser._();
  static final me = ValueNotifier<UserProfile?>(null);
}

class AppShellScope extends InheritedWidget {
  final void Function(int index, {bool link}) switchTab;
  final int currentIndex;
  /// Pestaña de la que se vino con un enlace (para la flecha ←), o null.
  final int? returnTab;
  /// Abre el menú lateral (☰).
  final VoidCallback? openMenu;
  /// Abre tu perfil (avatar del encabezado) y al volver lo recarga.
  final VoidCallback? openProfile;

  const AppShellScope({
    super.key,
    required this.switchTab,
    required this.currentIndex,
    this.returnTab,
    this.openMenu,
    this.openProfile,
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

/// Raíz del navegador interno: las pestañas (vivas una vez abiertas). Lee la
/// pestaña activa de AppShellScope, así se redibuja al cambiar.
class _TabsHost extends StatelessWidget {
  final List<Widget> tabs;
  final Set<int> opened;
  const _TabsHost({required this.tabs, required this.opened});

  @override
  Widget build(BuildContext context) {
    final index = AppShellScope.of(context)?.currentIndex ?? 0;
    return IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < tabs.length; i++) opened.contains(i) ? tabs[i] : const SizedBox.shrink(),
      ],
    );
  }
}

/// Avisa al shell cuando se abre o cierra algo en el navegador interno
/// (para que "volver" sepa si cierra una pantalla o cambia de pestaña).
class _NestedObserver extends NavigatorObserver {
  final VoidCallback onChange;
  _NestedObserver(this.onChange);
  @override
  void didPush(Route route, Route? previousRoute) => onChange();
  @override
  void didPop(Route route, Route? previousRoute) => onChange();
  @override
  void didRemove(Route route, Route? previousRoute) => onChange();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => onChange();
}
