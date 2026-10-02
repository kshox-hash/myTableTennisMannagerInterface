import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:myttmi/features/auth/presentation/login_screen.dart";
import "package:myttmi/features/shell/app_shell.dart";
import "package:myttmi/features/profile/api/profile_api.dart";

/// Al abrir la app: primero el logo al medio sobre negro (~1 s, aquí irá
/// su animación) y después, con un fundido, la pantalla de carga (estilo FIFA): la foto del jugador de
/// fondo y, en el espacio libre de arriba, el logo, el lema y una barra de
/// carga que avanza con los pasos reales (revisar la sesión, traer tus
/// datos). Se muestra al menos un instante para que no sea un parpadeo.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _minShown = Duration(milliseconds: 1600);
  static const _introLength = Duration(milliseconds: 1000);

  // Primera fase: logo al medio sobre negro. La carga real ya corre por
  // detrás; la pantalla de carga aparece al terminar esta fase.
  bool _intro = true;
  final _introDone = Completer<void>();
  static const _bg = AssetImage("assets/images/loading_bg.jpg");

  double _target = 0.08; // hasta dónde va la barra según el paso actual
  String _status = "PREPARANDO LA MESA…";

  // La foto ya está lista para mostrarse (el tiempo mínimo cuenta desde ahí).
  final _bgReady = Completer<void>();

  void _step(double target, String status) {
    if (!mounted) return;
    setState(() {
      _target = target;
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
    Future.delayed(_introLength, () async {
      // Que la foto ya esté lista al pasar a la pantalla de carga.
      await _bgReady.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      if (!mounted) return;
      setState(() => _intro = false);
      _shownAt = DateTime.now();
      _introDone.complete();
    });
    _route();
  }

  Future<void> _go(Widget screen, DateTime started) async {
    _step(1, "¡A JUGAR!");
    // El tiempo mínimo cuenta desde que aparece la pantalla de carga.
    await _introDone.future;
    started = _shownAt;
    final left = _minShown - DateTime.now().difference(started);
    await Future.delayed(left.isNegative ? const Duration(milliseconds: 350) : left);
    if (!mounted) return;
    Navigator.pushReplacement(context, CyberPageRoute(builder: (_) => screen));
  }

  DateTime _shownAt = DateTime.now();

  Future<void> _route() async {
    final started = DateTime.now();
    final storage = SessionStorage();
    _step(0.3, "AJUSTANDO LA RED…");
    final token = await storage.getToken();
    final role = await storage.getRole();

    if (!mounted) return;

    // Esta app es solo para jugadores — una sesión admin vieja (de antes de
    // sacar esas pantallas) no debe quedar atrapada acá.
    if (token == null || token.isEmpty || role != "player") {
      await storage.clear();
      await _go(const LoginScreen(), started);
      return;
    }

    // La sesión puede ser de un usuario que ya no existe (se borró la cuenta
    // o la base): el servidor responde 401 y se vuelve al login. Sin conexión
    // se sigue igual — no se echa al jugador por no tener señal.
    _step(0.7, "CALENTANDO…");
    try {
      await ProfileApi().getMe();
    } catch (e) {
      if (e.toString().contains("HTTP 401")) {
        await storage.clear();
        await _go(const LoginScreen(), started);
        return;
      }
    }
    await _go(const AppShell(), started);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _intro ? _logoIntro() : _loading(mq),
      ),
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
                  "TORNEOS DE TENIS DE MESA",
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
                  tween: Tween(end: _target),
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
                              borderRadius: BorderRadius.circular(99),
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
