import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/navigation/deep_links.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/features/notifications/api/notifications_api.dart";
import "package:myttmi/features/notifications/models/notification_model.dart";
import "package:myttmi/features/notifications/notification_nav.dart";

/// Avisos de notificación tipo Facebook (igual que en la web): cada
/// notificación NUEVA aparece como un cuadro abajo a la izquierda, sobre la
/// barra de navegación, con su ícono, título y texto. Si llegan varias se
/// apilan (máx. 4, la más nueva abajo). Se van solas a los 8 s, con la × o al
/// tocarlas (que marca leída y lleva a donde corresponde).
///
/// Se enteran de lo nuevo revisando la campana cada 20 s mientras la app está
/// abierta (y al instante si llega un push con la app abierta).
/// Tipos que se avisan (push y cuadro emergente). Mismo listado que el
/// servidor (PUSH_TYPES en notifications_repository.ts) y la web.
const importantTypes = {
  "groups_started",
  "match_up_soon",
  "match_on_table",
  "groups_ending",
  "group_outcome",
  "final_position",
  "tournament_cancelled",
  "tournament_updated",
  "enrollment_removed",
  "match_result_corrected",
  "group_changed",
  "bracket_changed",
  "club_join_request",
  "club_join_approved",
  "club_join_rejected",
  "referee_assigned",
  "tournament_finished",
};

class NotificationPopups {
  NotificationPopups._();

  static const _poll = Duration(seconds: 20);

  static final _api = NotificationsApi();

  /// Sin leer, para el número de la campana del Inicio: se actualiza en cada
  /// revisión (antes solo al recargar el Inicio, así que llegaban avisos y el
  /// número no subía). Baja solo al marcar leídas, no al cerrarse el cuadro.
  static final ValueNotifier<int> unread = ValueNotifier(0);
  static final Set<String> _shown = {};
  // Solo lo que llega después de abrir la app: al entrar no se muestran de
  // golpe todas las notificaciones viejas sin leer.
  static DateTime _since = DateTime.now();
  static int? _lastCount;
  static Timer? _timer;
  static bool _checking = false;

  /// AppShell montado (hay sesión).
  static void start() {
    _since = DateTime.now().subtract(const Duration(seconds: 5));
    _lastCount = null;
    _timer?.cancel();
    _timer = Timer.periodic(_poll, (_) => checkNow());
    checkNow();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    PopupStack.clear();
  }

  /// Revisar ya (al volver a la app, o llegó un push con la app abierta).
  static Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final count = await _api.getUnreadCount();
      unread.value = count;
      final prev = _lastCount;
      _lastCount = count;
      // El primer conteo solo fija la base; después, si subió, se piden las
      // últimas y se muestran las nuevas.
      if (prev == null && count == 0) return;
      if (prev != null && count <= prev) return;
      final snap = await _api.list();
      _push(snap.items);
    } catch (_) {
      // Sin señal: se reintenta en el próximo ciclo.
    } finally {
      _checking = false;
    }
  }

  static void _push(List<AppNotification> items) {
    final fresh = items.where((n) {
      if (n.isRead || _shown.contains(n.idNotification)) return false;
      // Mesa asignada: lo avisa MatchReadyWatcher, con el número de mesa.
      if (n.type == "match_on_table") return false;
      // Solo lo importante (el resto queda en la campana, sin aviso).
      if (!importantTypes.contains(n.type)) return false;
      final at = DateTime.tryParse(n.createdAt);
      return at == null || !at.isBefore(_since);
    }).toList().reversed.toList(); // la lista viene de la más nueva a la más vieja
    for (final n in fresh) {
      _shown.add(n.idNotification);
      PopupStack.show(
        title: n.title,
        body: n.message,
        emoji: notificationIcon(n.type),
        onTap: () => _open(n),
      );
    }
  }

  static Future<void> _open(AppNotification n) async {
    final nav = DeepLinks.navigatorKey.currentState;
    if (nav != null) openNotification(nav, n);
    try {
      await _api.markRead(n.idNotification);
      if (_lastCount != null && _lastCount! > 0) _lastCount = _lastCount! - 1;
      if (unread.value > 0) unread.value = unread.value - 1;
    } catch (_) {}
  }
}
