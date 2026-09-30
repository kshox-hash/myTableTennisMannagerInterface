import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/features/player/models/player_dashboard_model.dart';
import 'package:myttmi/routes/app_routes.dart';

/// Mientras la app está abierta, revisa cada 30 s si al jugador le
/// asignaron mesa. Cuando pasa, muestra a pantalla completa "¡Partido
/// listo!" con el rival y el número de mesa — el mismo aviso que la web
/// muestra como ventana, que la app no tenía. Cada partido se anuncia una
/// sola vez (se recuerda en el teléfono).
///
/// No reemplaza a las notificaciones push (llegan con la app cerrada, ver
/// push.ts en el backend): esto cubre la app abierta, sin configurar nada.
class MatchReadyWatcher extends StatefulWidget {
  final Widget child;
  const MatchReadyWatcher({super.key, required this.child});

  /// Revisar ya (llegó el push de mesa asignada con la app abierta): así se
  /// muestra este banner con el número de mesa, en vez de un segundo aviso.
  static void checkNow() => _MatchReadyWatcherState._instance?._check();

  @override
  State<MatchReadyWatcher> createState() => _MatchReadyWatcherState();
}

class _MatchReadyWatcherState extends State<MatchReadyWatcher> with WidgetsBindingObserver {
  static const _interval = Duration(seconds: 30);
  static const _prefsKey = "myttm:announced_matches";

  final _api = PlayerApi();
  Timer? _timer;
  bool _showing = false;
  static _MatchReadyWatcherState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    WidgetsBinding.instance.addObserver(this);
    // Primera revisión apenas se abre la app, después cada 30 s.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  @override
  void dispose() {
    if (_instance == this) _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Al volver a la app (desde otra app o con la pantalla bloqueada), revisar
  // al tiro en vez de esperar al próximo ciclo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_showing || !mounted) return;
    try {
      final dash = await _api.getDashboard();
      final matches = [if (dash.nextMatch != null) dash.nextMatch!, ...dash.otherNextMatches];
      final ready = matches.where((m) => m.tableNumber != null).toList();
      if (ready.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_prefsKey) ?? const [];
      final fresh = ready.firstWhere((m) => !seen.contains(m.idMatch), orElse: () => ready.first);
      if (seen.contains(fresh.idMatch) || !mounted) return;
      // Se guarda antes de mostrar: aunque la app se cierre con el aviso
      // abierto, no vuelve a saltar por el mismo partido.
      await prefs.setStringList(_prefsKey, [...seen.skip(seen.length > 40 ? seen.length - 40 : 0), fresh.idMatch]);
      _showing = true;
      if (!mounted) return;
      // Aviso tipo notificación que baja desde arriba: no bloquea la pantalla
      // ni pide tocar nada (el jugador puede estar ya yendo a la mesa); se
      // va solo y, si lo tocan, abre el partido.
      final navigator = Navigator.of(context);
      final overlay = Overlay.of(context, rootOverlay: true);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _MatchReadyBanner(
          match: fresh,
          onOpen: () => navigator.pushNamed(
            AppRoutes.matchDetail,
            arguments: {"matchType": fresh.matchType, "matchId": fresh.idMatch},
          ),
          onDone: () {
            if (entry.mounted) entry.remove();
          },
        ),
      );
      overlay.insert(entry);
    } catch (_) {
      // Sin conexión o sesión vencida: se reintenta en el próximo ciclo.
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MatchReadyBanner extends StatefulWidget {
  final PlayerNextMatch match;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  const _MatchReadyBanner({required this.match, required this.onOpen, required this.onDone});

  @override
  State<_MatchReadyBanner> createState() => _MatchReadyBannerState();
}

class _MatchReadyBannerState extends State<_MatchReadyBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(seconds: 8), _dismiss);
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
    final m = widget.match;
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SlideTransition(
                position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(curve),
                child: Dismissible(
                  key: ValueKey(m.idMatch),
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
                        widget.onOpen();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: AppColors.scorifyButterfly, width: 4)),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.scorifyButterfly, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("MESA",
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.scorifyOnButterfly)),
                                  Text("${m.tableNumber}",
                                      style: const TextStyle(fontSize: 19, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.scorifyOnButterfly)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("¡Te toca! Ve a la mesa ${m.tableNumber}",
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "vs ${m.opponentName ?? "Por definir"} · ${m.categoryDisplay}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.scorifyTextMuted),
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
      ),
    );
  }
}
