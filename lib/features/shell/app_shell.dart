import 'package:myttmi/core/ui/panel_style.dart';
import 'package:flutter/foundation.dart';
import 'package:myttmi/core/app_update.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myttmi/core/constants/app_config.dart';
import 'package:myttmi/features/referee/referee_scan_screen.dart';
import 'package:myttmi/features/shell/splash_gate.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/confirm_dialog.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/favorites/favorites_screen.dart';
import 'package:myttmi/routes/app_routes.dart';
import 'package:myttmi/features/shell/app_drawer.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/navigation/deep_links.dart';
import 'package:myttmi/core/push/push_service.dart';
import 'package:myttmi/features/notifications/notification_popups.dart';
import 'package:myttmi/core/ui/app_toast.dart';
import 'package:myttmi/core/ui/prism_background.dart';
import 'package:myttmi/features/calendar/presentation/calendar_screen.dart';
import 'package:myttmi/features/home/presentation/home_screen.dart';
import 'package:myttmi/features/stats/presentation/stats_screen.dart';
import 'package:myttmi/features/ranking/presentation/ranking_screen.dart';
import 'package:myttmi/features/tournament/presentation/tournaments_screen.dart';
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

  static const _tabs = [
    HomeScreen(),
    CalendarScreen(),
    StatsScreen(),
    TournamentsScreen(),
    RankingScreen(),
  ];

  // Mismo lenguaje que CyberPageRoute (ver cyber_page_route.dart) pero para
  // un solo widget: el IndexedStack se apaga, en el punto más bajo se
  // cambia el índice (no se ve, así que no hay salto brusco) y se vuelve
  // a encender — en vez de un cambio instantáneo sin transición.
  static const _pulseDuration = Duration(milliseconds: 180);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  // Pestaña a la que vuelve la flecha ← cuando se llegó con un enlace
  // ("Ver estadísticas" en el Inicio). Tocando la barra de abajo no hay.
  int? _returnTab;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<void> _loadMe() async {
    try {
      CurrentUser.me.value = await ProfileApi().getMe();
    } catch (_) {}
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    _loadMe();
  }

  /// Ajustes: arbitrar con QR y sonidos.
  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.scorifyText),
              title: const Text("Arbitrar con QR", style: TextStyle(color: AppColors.scorifyText)),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(context, CyberPageRoute(builder: (_) => const RefereeScanScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.scorifyText),
              title: const Text("Política de privacidad", style: TextStyle(color: AppColors.scorifyText)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.scorifyTextMuted),
              onTap: () {
                Navigator.pop(sheet);
                launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: AppColors.scorifyText),
              title: const Text("Ayuda y contacto", style: TextStyle(color: AppColors.scorifyText)),
              subtitle: const Text("Reportar un problema o hacer una consulta", style: TextStyle(color: AppColors.scorifyTextMuted)),
              onTap: () {
                Navigator.pop(sheet);
                _contactSupport();
              },
            ),
            const Divider(height: 1, color: AppColors.scorifySurface2),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.scorifyNegative),
              title: const Text("Eliminar cuenta", style: TextStyle(color: AppColors.scorifyNegative)),
              onTap: () {
                Navigator.pop(sheet);
                _deleteAccount();
              },
            ),
            if (AppUpdate.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text("MyTTM ${AppUpdate.label}",
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.scorifyTextFaint, fontSize: 12)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _switchTab(_returnTab ?? 0);
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scorifyBg,
      // Menú lateral (☰) en vez de la barra de navegación de abajo.
      drawer: AppDrawer(
        main: [
          DrawerItem(Icons.home_rounded, "Inicio", () => _switchTab(0), selected: _index == 0),
          DrawerItem(Icons.calendar_month_rounded, "Calendario", () => _switchTab(1), selected: _index == 1),
          DrawerItem(Icons.trending_up_rounded, "Mi rendimiento", () => _switchTab(2), selected: _index == 2),
          DrawerItem(Icons.leaderboard_rounded, "Ranking", () => _switchTab(4), selected: _index == 4),
          DrawerItem(Icons.person_rounded, "Mi perfil", _openProfile),
          DrawerItem(Icons.emoji_events_rounded, "Campeonatos", () => _switchTab(3), selected: _index == 3),
        ],
        more: [
          DrawerItem(Icons.history_rounded, "Historial", () => Navigator.pushNamed(context, AppRoutes.history)),
          DrawerItem(Icons.favorite_border_rounded, "Partidos guardados",
              () => Navigator.push(context, CyberPageRoute(builder: (_) => const FavoritesScreen()))),
          DrawerItem(Icons.settings_rounded, "Ajustes", _openSettings),
        ],
        onLogout: _logout,
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
                    openMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    openProfile: _openProfile,
                    child: IndexedStack(
                      index: _index,
                      children: [
                        for (var i = 0; i < _tabs.length; i++) _opened.contains(i) ? _tabs[i] : const SizedBox.shrink(),
                      ],
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
