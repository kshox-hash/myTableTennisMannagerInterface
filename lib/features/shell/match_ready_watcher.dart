import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/app_toast.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/routes/app_routes.dart';

/// Mientras la app está abierta, revisa cada 30 s si al jugador le
/// asignaron mesa. Cuando pasa, muestra el aviso "¡Te toca! Ve a la mesa N"
/// con el rival (el mismo cuadro de los demás avisos, destacado en verde)
/// y lo abre al tocarlo. Cada partido se anuncia una
/// sola vez (se recuerda en el teléfono).
///
/// No reemplaza a las notificaciones push (llegan con la app cerrada, ver
/// push.ts en el backend): esto cubre la app abierta, sin configurar nada.
class MatchReadyWatcher extends StatefulWidget {
  final Widget child;
  const MatchReadyWatcher({super.key, required this.child});

  /// Revisar ya (llegó el push de mesa asignada con la app abierta): así se
  /// muestra este aviso con el número de mesa, en vez de un segundo aviso.
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
      // El mismo cuadro de los demás avisos (abajo a la izquierda), destacado
      // en verde y con el número de mesa: no bloquea la pantalla ni pide
      // tocar nada; se va solo y, si lo tocan, abre el partido.
      final navigator = Navigator.of(context);
      PopupStack.show(
        context: context,
        title: "¡Te toca! Ve a la mesa ${fresh.tableNumber}",
        body: "vs ${fresh.opponentName ?? "Por definir"} · ${fresh.categoryDisplay}",
        tone: PopupTone.good,
        highlight: true,
        lifetime: const Duration(seconds: 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.scorifyButterfly, borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("MESA",
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.scorifyOnButterfly)),
              Text("${fresh.tableNumber}",
                  style: const TextStyle(fontSize: 17, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.scorifyOnButterfly)),
            ],
          ),
        ),
        onTap: () => navigator.pushNamed(
          AppRoutes.matchDetail,
          arguments: {"matchType": fresh.matchType, "matchId": fresh.idMatch},
        ),
      );
    } catch (_) {
      // Sin conexión o sesión vencida: se reintenta en el próximo ciclo.
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

