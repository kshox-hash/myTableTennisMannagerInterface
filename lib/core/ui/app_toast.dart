import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/navigation/deep_links.dart";

/// Aviso de confirmación (✓ verde) o error (✕ rojo) de una acción: un
/// cuadro que entra desde la izquierda, abajo, sobre la barra de navegación,
/// y se apila si hay varios (el más nuevo abajo). Las notificaciones no usan
/// esto: su aviso es la push del teléfono.

/// Dónde está la barra de navegación de abajo: AppShell se registra acá y los
/// avisos suben por encima de ella mientras sus pestañas estén al frente.
class ToastLayout {
  ToastLayout._();
  static ModalRoute<dynamic>? shellRoute;
  static const double navBarHeight = 0; // sin barra de abajo (menú ☰)
}

enum PopupTone { good, bad, info, time }

class PopupItem {
  final int id;
  final String title;
  final String? body;
  final IconData? icon;
  final String? emoji;
  final Widget? leading;
  final PopupTone tone;
  final bool highlight;
  final VoidCallback? onTap;
  PopupItem._(this.id, this.title, this.body, this.icon, this.emoji, this.leading, this.tone, this.highlight, this.onTap);
}

class PopupStack {
  PopupStack._();

  static const _maxVisible = 4;
  static const _exit = Duration(milliseconds: 320);
  static final ValueNotifier<List<PopupItem>> _items = ValueNotifier(const []);
  static final ValueNotifier<Set<int>> _leaving = ValueNotifier(const {});
  static OverlayEntry? _host;
  static int _seq = 0;

  // El contexto puede ser el del propio Overlay (DeepLinks.overlayContext):
  // ahí Overlay.maybeOf no lo encuentra, porque busca solo hacia arriba. Si
  // no hay contexto, el Overlay del Navigator.
  static OverlayState? _overlay(BuildContext? context) {
    if (context != null) {
      if (context is StatefulElement && context.state is OverlayState) return context.state as OverlayState;
      final o = Overlay.maybeOf(context, rootOverlay: true);
      if (o != null) return o;
    }
    return DeepLinks.navigatorKey.currentState?.overlay;
  }

  static void show({
    BuildContext? context,
    required String title,
    String? body,
    IconData? icon,
    String? emoji,
    Widget? leading,
    PopupTone tone = PopupTone.info,
    bool highlight = false,
    VoidCallback? onTap,
    Duration lifetime = const Duration(seconds: 8),
  }) {
    final overlay = _overlay(context);
    if (overlay == null) return;
    if (_host == null || !_host!.mounted) {
      _host = OverlayEntry(builder: (_) => _PopupStackView()); // sin const: markNeedsBuild debe reconstruirlo
      overlay.insert(_host!);
    } else {
      // Recalcular la altura: el contenedor pudo crearse en otra pantalla
      // (p. ej. el login, sin barra de navegación).
      _host!.markNeedsBuild();
    }
    final item = PopupItem._(++_seq, title, body, icon, emoji, leading, tone, highlight, onTap);
    final all = [..._items.value, item];
    _items.value = all.length > _maxVisible ? all.sublist(all.length - _maxVisible) : all;
    Timer(lifetime, () => dismiss(item.id));
  }

  static void dismiss(int id) {
    if (_leaving.value.contains(id) || !_items.value.any((n) => n.id == id)) return;
    _leaving.value = {..._leaving.value, id};
    Timer(_exit, () {
      _items.value = _items.value.where((n) => n.id != id).toList();
      _leaving.value = {..._leaving.value}..remove(id);
    });
  }

  static void clear() {
    _items.value = const [];
    _leaving.value = const {};
  }
}

/// Confirmación de una acción ("Perfil guardado", "Quedaste inscrito…") o
/// error: el mismo cuadro que las notificaciones, con ✓ verde / ✕ rojo y más
/// breve (el error dura más porque hay que alcanzar a leerlo).
void showToast(BuildContext context, String message, {bool error = false}) {
  PopupStack.show(
    context: context,
    title: message.replaceFirst("Exception: ", ""),
    icon: error ? Icons.close_rounded : Icons.check_rounded,
    tone: error ? PopupTone.bad : PopupTone.good,
    lifetime: Duration(milliseconds: error ? 4500 : 2800),
  );
}

class _PopupStackView extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _PopupStackView();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final onShell = ToastLayout.shellRoute?.isCurrent ?? false;
    // Con teclado abierto, justo encima del teclado (si no, un error al
    // iniciar sesión quedaba escondido); si no, sobre la barra de
    // navegación cuando está visible, o a 16 px del borde.
    final bottom = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom + 12
        : mq.padding.bottom + (onShell ? ToastLayout.navBarHeight + 10 : 16);
    final width = (mq.size.width - 32).clamp(0.0, 360.0);
    return Positioned(
      left: 16,
      bottom: bottom,
      width: width,
      child: ValueListenableBuilder<Set<int>>(
        valueListenable: PopupStack._leaving,
        builder: (_, leaving, __) => ValueListenableBuilder<List<PopupItem>>(
          valueListenable: PopupStack._items,
          builder: (_, list, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El más nuevo queda abajo (más cerca del dedo).
              for (final n in list)
                Padding(
                  key: ValueKey(n.id),
                  padding: const EdgeInsets.only(top: 8),
                  child: _Popup(item: n, leaving: leaving.contains(n.id)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Popup extends StatefulWidget {
  final PopupItem item;
  final bool leaving;
  const _Popup({required this.item, required this.leaving});

  @override
  State<_Popup> createState() => _PopupState();
}

class _PopupState extends State<_Popup> with SingleTickerProviderStateMixin {
  // Entra desde la izquierda con un pequeño rebote y crece; sale
  // deslizándose a la izquierda y el hueco se cierra suave (los de arriba
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

  static Color _color(PopupTone t) => switch (t) {
        PopupTone.good => AppColors.scorifyButterfly,
        PopupTone.bad => AppColors.scorifyNegative,
        PopupTone.time => AppColors.scorifyPending,
        PopupTone.info => AppColors.scorifyMint,
      };

  @override
  Widget build(BuildContext context) {
    final n = widget.item;
    final slide = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut), reverseCurve: Curves.easeIn);
    final size = CurvedAnimation(parent: _c, curve: const Interval(0, 0.5, curve: Curves.easeOut), reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn));
    final fg = _color(n.tone);
    final body = (n.body ?? "").trim();
    final Widget leading = n.leading ??
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: n.emoji != null ? AppColors.scorifyDeep : fg.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(2),
          ),
          child: n.emoji != null
              ? Text(n.emoji!, style: const TextStyle(fontSize: 17))
              : Icon(n.icon ?? Icons.notifications_rounded, color: fg, size: 20),
        );
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
            // Más claro que las tarjetas y con borde fino, para que se note
            // que flota encima; los destacados llevan el borde de su color.
            child: Material(
              color: AppColors.scorifySurface2,
              elevation: 12,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
                side: n.highlight ? BorderSide(color: fg, width: 1.5) : const BorderSide(color: Color(0x26FFFFFF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  PopupStack.dismiss(n.id);
                  n.onTap?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                  child: Row(
                    crossAxisAlignment: body.isEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              maxLines: body.isEmpty ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.body,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: n.highlight ? fg : AppColors.scorifyText,
                              ),
                            ),
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, height: 1.3, color: AppColors.scorifyTextMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      InkResponse(
                        onTap: () => PopupStack.dismiss(n.id),
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
