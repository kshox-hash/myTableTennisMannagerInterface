import "dart:async";

import "package:flutter/widgets.dart";
import "package:myttmi/features/shell/app_shell.dart";

/// Actualización automática de las pantallas que cambian durante un torneo
/// (próximo partido, tablas, resultados, inscritos, mesas…), sin tener que
/// deslizar para recargar:
///  - cada 30 s,
///  - al instante cuando llega una notificación nueva (algo cambió),
///  - al volver a la app.
/// Solo recarga la pantalla que se está viendo (la de arriba y, si es una
/// pestaña del Inicio, la pestaña activa) y sin mostrar el esqueleto de
/// carga: los datos se reemplazan cuando llegan los nuevos.
class LiveRefresh {
  LiveRefresh._();

  static final ValueNotifier<int> tick = ValueNotifier(0);
  static Timer? _timer;

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => bump());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pedir una actualización ya (llegó algo nuevo, se volvió a la app).
  static void bump() => tick.value++;
}

mixin LiveRefreshMixin<T extends StatefulWidget> on State<T> {
  /// Recarga silenciosa de los datos de la pantalla.
  void onLiveRefresh();

  /// Si la pantalla es una pestaña de AppShell, su índice (para recargar
  /// solo la pestaña visible). null = pantalla normal.
  int? get liveTabIndex => null;

  @override
  void initState() {
    super.initState();
    LiveRefresh.tick.addListener(_onTick);
  }

  @override
  void dispose() {
    LiveRefresh.tick.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final tab = liveTabIndex;
    if (tab != null) {
      final current = context.getInheritedWidgetOfExactType<AppShellScope>()?.currentIndex;
      if (current != null && current != tab) return;
    }
    onLiveRefresh();
  }
}
