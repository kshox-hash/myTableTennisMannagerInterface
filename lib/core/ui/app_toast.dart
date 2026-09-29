import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Aviso flotante igual al toast de la web: verde con ✓ para éxito, rojo con
/// ✕ para error, abajo al centro. Entra subiendo desde abajo y sale bajando
/// (el SnackBar de Flutter solo aparecía con un fundido). El de error dura
/// más porque hay que alcanzar a leerlo.
OverlayEntry? _current;

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
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + MediaQuery.paddingOf(context).bottom,
      child: SafeArea(
        top: false,
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
      ),
    );
  }
}
