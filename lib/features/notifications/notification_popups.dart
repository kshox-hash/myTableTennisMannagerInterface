import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/features/notifications/api/notifications_api.dart";

/// Número de notificaciones sin leer para la campana del Inicio, revisado
/// cada 20 s mientras la app está abierta (y al instante si llega un push).
///
/// Ya no muestra cuadros emergentes: el aviso de una notificación es la push
/// del teléfono (arriba). Con los dos salían dos avisos por lo mismo.
class NotificationPopups {
  NotificationPopups._();

  static const _poll = Duration(seconds: 20);

  static final _api = NotificationsApi();

  /// Sin leer, para el número de la campana del Inicio.
  static final ValueNotifier<int> unread = ValueNotifier(0);
  static Timer? _timer;
  static bool _checking = false;

  /// AppShell montado (hay sesión).
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_poll, (_) => checkNow());
    checkNow();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Revisar ya (al volver a la app, o llegó un push con la app abierta).
  static Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      unread.value = await _api.getUnreadCount();
    } catch (_) {
      // Sin señal: se reintenta en el próximo ciclo.
    } finally {
      _checking = false;
    }
  }
}
