import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
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
};

class NotificationPopups {
  NotificationPopups._();

  static const _poll = Duration(seconds: 20);
  static const _lifetime = Duration(seconds: 8);
  static const _maxVisible = 4;

  static final _api = NotificationsApi();

  /// Sin leer, para el número de la campana del Inicio: se actualiza en cada
  /// revisión (antes solo al recargar el Inicio, así que llegaban avisos y el
  /// número no subía). Baja solo al marcar leídas, no al cerrarse el cuadro.
  static final ValueNotifier<int> unread = ValueNotifier(0);
  static final ValueNotifier<List<AppNotification>> _items = ValueNotifier(const []);
  static final Set<String> _shown = {};
  // Solo lo que llega después de abrir la app: al entrar no se muestran de
  // golpe todas las notificaciones viejas sin leer.
  static DateTime _since = DateTime.now();
  static int? _lastCount;
  static Timer? _timer;
  static OverlayEntry? _host;
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
    _items.value = const [];
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
      // Mesa asignada: ya lo avisa el banner "¡Te toca! Ve a la mesa N".
      if (n.type == "match_on_table") return false;
      // Solo lo importante (el resto queda en la campana, sin aviso).
      if (!importantTypes.contains(n.type)) return false;
      final at = DateTime.tryParse(n.createdAt);
      return at == null || !at.isBefore(_since);
    }).toList().reversed.toList(); // la lista viene de la más nueva a la más vieja
    if (fresh.isEmpty) return;
    // El Overlay del Navigator, directo: Overlay.maybeOf(overlay.context)
    // devolvía null (busca hacia arriba y el Overlay no es su propio ancestro).
    final overlay = DeepLinks.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    if (_host == null || !_host!.mounted) {
      _host = OverlayEntry(builder: (_) => const _PopupStack());
      overlay.insert(_host!);
    }
    for (final n in fresh) {
      _shown.add(n.idNotification);
      Timer(_lifetime, () => _dismiss(n.idNotification));
    }
    final all = [..._items.value, ...fresh];
    _items.value = all.length > _maxVisible ? all.sublist(all.length - _maxVisible) : all;
  }

  static final ValueNotifier<Set<String>> _leaving = ValueNotifier(const {});
  static const _exit = Duration(milliseconds: 320);

  static void _dismiss(String id) {
    if (_leaving.value.contains(id) || !_items.value.any((n) => n.idNotification == id)) return;
    _leaving.value = {..._leaving.value, id};
    Timer(_exit, () {
      _items.value = _items.value.where((n) => n.idNotification != id).toList();
      _leaving.value = {..._leaving.value}..remove(id);
    });
  }

  static Future<void> _open(AppNotification n) async {
    _dismiss(n.idNotification);
    final nav = DeepLinks.navigatorKey.currentState;
    if (nav != null) openNotification(nav, n);
    try {
      await _api.markRead(n.idNotification);
      if (_lastCount != null && _lastCount! > 0) _lastCount = _lastCount! - 1;
      if (unread.value > 0) unread.value = unread.value - 1;
    } catch (_) {}
  }
}

class _PopupStack extends StatelessWidget {
  const _PopupStack();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final onShell = ToastLayout.shellRoute?.isCurrent ?? false;
    final bottom = mq.padding.bottom + (onShell ? ToastLayout.navBarHeight + 10 : 16);
    final width = (mq.size.width - 32).clamp(0.0, 340.0);
    return Positioned(
      left: 16,
      bottom: bottom,
      width: width,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: NotificationPopups._leaving,
        builder: (_, leaving, __) => ValueListenableBuilder<List<AppNotification>>(
        valueListenable: NotificationPopups._items,
        builder: (_, list, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La más nueva queda abajo (más cerca del dedo); las anteriores
            // se apilan hacia arriba.
            for (final n in list)
              Padding(
                key: ValueKey(n.idNotification),
                padding: const EdgeInsets.only(top: 8),
                child: _Popup(
                  n: n,
                  leaving: leaving.contains(n.idNotification),
                  onTap: () => NotificationPopups._open(n),
                  onClose: () => NotificationPopups._dismiss(n.idNotification),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Popup extends StatefulWidget {
  final AppNotification n;
  final bool leaving;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _Popup({required this.n, required this.leaving, required this.onTap, required this.onClose});

  @override
  State<_Popup> createState() => _PopupState();
}

class _PopupState extends State<_Popup> with SingleTickerProviderStateMixin {
  // Entrada: entra desde la izquierda con un pequeño rebote, crece y
  // aparece. Salida (se va solo, ×, o al tocarlo): se desliza a la
  // izquierda desvaneciéndose y el hueco se cierra suave (los de arriba
  // bajan en vez de saltar).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void didUpdateWidget(covariant _Popup old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;
    final slide = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut), reverseCurve: Curves.easeIn);
    final size = CurvedAnimation(parent: _c, curve: const Interval(0, 0.5, curve: Curves.easeOut), reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn));
    return SizeTransition(
      sizeFactor: size,
      axisAlignment: 1,
      child: SlideTransition(
      position: Tween(begin: const Offset(-1.15, 0), end: Offset.zero).animate(slide),
      child: ScaleTransition(
      scale: Tween(begin: 0.92, end: 1.0).animate(fade),
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: fade,
        // Más claro que las tarjetas y con borde fino, para que se note que
        // flota encima (igual que el cuadro de la web).
        child: Material(
          color: AppColors.scorifySurface2,
          elevation: 12,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.scorifyDeep, borderRadius: BorderRadius.circular(10)),
                    child: Text(notificationIcon(n.type), style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, height: 1.3, color: AppColors.scorifyTextMuted),
                        ),
                      ],
                    ),
                  ),
                  InkResponse(
                    onTap: widget.onClose,
                    radius: 16,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: AppColors.scorifyTextMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }
}
