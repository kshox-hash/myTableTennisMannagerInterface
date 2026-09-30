import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Aviso flotante igual al toast de la web: verde con ✓ para éxito, rojo con
/// ✕ para error, abajo al centro. Entra subiendo desde abajo y sale bajando
/// (el SnackBar de Flutter solo aparecía con un fundido). El de error dura
/// más porque hay que alcanzar a leerlo.
OverlayEntry? _current;

/// Dónde está la barra de navegación de abajo: AppShell se registra acá y el
/// toast sube por encima de ella mientras sus pestañas estén al frente (antes
/// quedaba encima de Inicio/Calendario/… tapándolos).
class ToastLayout {
  ToastLayout._();
  static ModalRoute<dynamic>? shellRoute;
  static const double navBarHeight = 62;
}

void showToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _current?.remove();
  _current = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message.replaceFirst("Exception: ", ""),
      error: error,
      onDone: () {
        if (_current == entry) _current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  final String message;
  final bool error;
  final VoidCallback onDone;

  const _Toast({required this.message, required this.error, required this.onDone});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(Duration(milliseconds: widget.error ? 3500 : 2000), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.error ? Colors.white : AppColors.scorifyOnButterfly;
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    // Con teclado abierto, justo encima del teclado (antes quedaba escondido
    // detrás, p. ej. un error al iniciar sesión). Si no, encima de la barra
    // de navegación cuando está visible, o a 16 px del borde. El margen del
    // sistema se suma una sola vez (antes también lo agregaba un SafeArea).
    final mq = MediaQuery.of(context);
    final onShell = ToastLayout.shellRoute?.isCurrent ?? false;
    final bottom = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom + 12
        : mq.padding.bottom + (onShell ? ToastLayout.navBarHeight + 12 : 16);
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 1.2), end: Offset.zero).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: Material(
                  color: widget.error ? AppColors.scorifyNegative : AppColors.scorifyButterfly,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(widget.error ? Icons.cancel_outlined : Icons.check_circle_outline_rounded, color: fg, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w700, color: fg),
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
      ),
    );
  }
}

// ── Aviso de notificación (push que llega con la app abierta) ────────────
// Baja desde arriba, oscuro y con la campana — distinto del toast verde de
// "guardado", que es para confirmar acciones. Se va solo, se descarta
// deslizando hacia arriba y, si lo tocan, ejecuta onTap. Uno a la vez.
// Se apilan (como los avisos de Facebook): el más nuevo arriba, máximo 3
// a la vista; cada uno se va solo a los 6 s. Antes uno reemplazaba al otro
// y si llegaban dos seguidas la primera ni se alcanzaba a leer.
class _NoticeData {
  final int id;
  final String title;
  final String? body;
  final VoidCallback? onTap;
  _NoticeData(this.id, this.title, this.body, this.onTap);
}

final ValueNotifier<List<_NoticeData>> _notices = ValueNotifier(const []);
OverlayEntry? _noticeHost;
int _noticeSeq = 0;

void _removeNotice(int id) {
  _notices.value = _notices.value.where((n) => n.id != id).toList();
}

void showNotice(BuildContext context, {required String title, String? body, VoidCallback? onTap}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (_noticeHost == null || !_noticeHost!.mounted) {
    _noticeHost = OverlayEntry(builder: (_) => const _NoticeStack());
    overlay.insert(_noticeHost!);
  }
  _notices.value = [_NoticeData(++_noticeSeq, title, body, onTap), ..._notices.value].take(3).toList();
}

class _NoticeStack extends StatelessWidget {
  const _NoticeStack();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 12,
      right: 12,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ValueListenableBuilder<List<_NoticeData>>(
            valueListenable: _notices,
            builder: (_, list, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in list)
                  Padding(
                    key: ValueKey(n.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Notice(
                      title: n.title,
                      body: n.body,
                      onTap: n.onTap,
                      onDone: () => _removeNotice(n.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatefulWidget {
  final String title;
  final String? body;
  final VoidCallback? onTap;
  final VoidCallback onDone;
  const _Notice({required this.title, this.body, this.onTap, required this.onDone});

  @override
  State<_Notice> createState() => _NoticeState();
}

class _NoticeState extends State<_Notice> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(seconds: 6), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final body = (widget.body ?? "").trim();
    return SlideTransition(
            position: Tween(begin: const Offset(0, -1.6), end: Offset.zero).animate(curve),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDone(),
              child: Material(
                color: AppColors.scorifyDeep,
                elevation: 12,
                shadowColor: Colors.black,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    _dismiss();
                    widget.onTap?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.scorifyMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.notifications_rounded, color: AppColors.scorifyMint, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypography.body,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.scorifyText,
                                ),
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.body,
                                    fontSize: 13,
                                    color: AppColors.scorifyTextMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
