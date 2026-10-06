import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:myttmi/features/auth/presentation/login_screen.dart";
import "package:myttmi/features/shell/app_shell.dart";
import "package:myttmi/features/shell/shell_preload.dart";
import "package:myttmi/features/profile/api/profile_api.dart";

/// Al abrir la app: primero el logo al medio sobre negro (~1 s, aquí irá su
/// animación) y después, con un fundido, la pantalla de carga (estilo FIFA):
/// la foto del jugador, el logo arriba y la barra abajo.
///
/// La app (AppShell) se arma POR DEBAJO de la pantalla de carga, y esta se
/// quita recién cuando el Inicio terminó de traer todos sus datos: así el
/// Inicio aparece completo, sin bloques que se cargan después. La barra
/// sigue esa carga real. Al iniciar sesión se usa lo mismo, sin el logo.
class SplashGate extends StatefulWidget {
  /// Viene del login/registro: ya hay sesión, sin la fase del logo.
  final bool afterLogin;
  const SplashGate({super.key, this.afterLogin = false});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _minShown = Duration(milliseconds: 1200);
  static const _introLength = Duration(milliseconds: 1000);
  static const _maxWait = Duration(seconds: 8); // sin señal: se entra igual
  static const _bg = AssetImage("assets/images/loading_bg.jpg");

  // Fase 1: logo al medio sobre negro.
  late bool _intro = !widget.afterLogin;
  final _introDone = Completer<void>();
  DateTime _shownAt = DateTime.now();

  // La app armada por debajo, y la pantalla de carga desvaneciéndose/quitada.
  bool _shell = false;
  bool _fading = false;
  bool _gone = false;

  String _status = "PREPARANDO LA MESA…";
  double _base = 0.08; // avance propio (sesión); el resto lo aporta el Inicio

  final _bgReady = Completer<void>();

  void _step(double target, String status) {
    if (!mounted) return;
    setState(() {
      _base = target;
      _status = status;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bgReady.isCompleted) {
      precacheImage(_bg, context).whenComplete(() {
        if (!_bgReady.isCompleted) _bgReady.complete();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ShellPreload.reset();
    ShellPreload.progress.addListener(_onProgress);
    if (widget.afterLogin) {
      _shownAt = DateTime.now();
      _introDone.complete();
    } else {
      Future.delayed(_introLength, () async {
        await _bgReady.future.timeout(const Duration(seconds: 2), onTimeout: () {});
        if (!mounted) return;
        setState(() => _intro = false);
        _shownAt = DateTime.now();
        _introDone.complete();
      });
    }
    _route();
  }

  @override
  void dispose() {
    ShellPreload.progress.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    final p = ShellPreload.progress.value;
    if (p >= 1) {
      _step(1, "¡A JUGAR!");
    } else if (p >= 0.6) {
      _step(0.35 + p * 0.6, "CALENTANDO…");
    } else if (p > 0) {
      _step(0.35 + p * 0.6, "AJUSTANDO LA RED…");
    }
  }

  Future<void> _waitMinShown() async {
    await _introDone.future;
    final left = _minShown - DateTime.now().difference(_shownAt);
    if (!left.isNegative) await Future.delayed(left);
  }

  Future<void> _toLogin() async {
    _step(1, "¡A JUGAR!");
    await _waitMinShown();
    if (!mounted) return;
    Navigator.pushReplacement(context, CyberPageRoute(waitForData: false, builder: (_) => const LoginScreen()));
  }

  Future<void> _route() async {
    final storage = SessionStorage();
    if (!widget.afterLogin) {
      _step(0.15, "PREPARANDO LA MESA…");
      final token = await storage.getToken();
      final role = await storage.getRole();
      if (!mounted) return;

      // Esta app es solo para jugadores — una sesión admin vieja (de antes de
      // sacar esas pantallas) no debe quedar atrapada acá.
      if (token == null || token.isEmpty || role != "player") {
        await storage.clear();
        await _toLogin();
        return;
      }

      // La sesión puede ser de un usuario que ya no existe (se borró la
      // cuenta o la base): el servidor responde 401 y se vuelve al login.
      // Sin conexión se sigue igual — no se echa al jugador por no tener señal.
      try {
        await ProfileApi().getMe();
      } catch (e) {
        if (e.toString().contains("HTTP 401")) {
          await storage.clear();
          await _toLogin();
          return;
        }
      }
      if (!mounted) return;
    }

    // Se arma la app por debajo; el Inicio empieza a traer sus datos.
    _step(0.35, "AJUSTANDO LA RED…");
    setState(() => _shell = true);
    await ShellPreload.ready.timeout(_maxWait, onTimeout: () {});
    _step(1, "¡A JUGAR!");
    await _waitMinShown();
    await Future.delayed(const Duration(milliseconds: 250)); // que se vea el 100 %
    if (!mounted) return;
    // Se quita la pantalla de carga: el Inicio ya está completo debajo.
    setState(() => _fading = true);
    ShellPreload.revealed.value = true;
    await Future.delayed(const Duration(milliseconds: 380));
    if (mounted) setState(() => _gone = true);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final overlay = Material(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _intro ? _logoIntro() : _loading(mq),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_shell) const AppShell(),
        if (!_gone)
          IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: overlay,
            ),
          ),
      ],
    );
  }

  /// Fase 1: logo al medio sobre negro (aquí irá la animación del logo).
  Widget _logoIntro() => const ColoredBox(
        key: ValueKey("intro"),
        color: Colors.black,
        child: Center(child: BrandLogo(markSize: 96, showWordmark: false)),
      );

  /// Fase 2: la foto con el logo arriba y la barra de carga abajo.
  Widget _loading(MediaQueryData mq) {
    return Stack(
        key: const ValueKey("loading"),
        fit: StackFit.expand,
        children: [
          // Foto: el jugador abajo; arriba queda el espacio libre del texto.
          const Image(image: _bg, fit: BoxFit.cover, alignment: Alignment(-0.6, 1)),
          Positioned(
            left: 28,
            right: 28,
            top: mq.padding.top + mq.size.height * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(markSize: 46, wordmarkSize: 34),
                const SizedBox(height: 6),
                Text(
                  "CAMPEONATOS DE TENIS DE MESA",
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          // Barra de carga abajo.
          Positioned(
            left: 28,
            right: 28,
            bottom: mq.padding.bottom + 36,
            child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _base),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(_status, style: _small)),
                          Text("Cargando ${(v * 100).round()} %", style: _small),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Barra: fondo oscuro translúcido, avance en degradado.
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: appButtonGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
    );
  }

  static final TextStyle _small = TextStyle(
    fontFamily: AppTypography.body,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    color: Colors.white.withValues(alpha: 0.9),
    // Sombra solo en el texto: se lee sobre la pierna o el fondo claro.
    shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
  );
}
