import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/app_update.dart";
import "package:flutter/foundation.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/core/monitoring.dart";
import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_button.dart";
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
  static const _minShown = Duration(milliseconds: 500);
  static const _introLength = Duration(milliseconds: 500);
  static const _maxWait = Duration(seconds: 8); // sin señal: se entra igual

  // Fase 1: logo al medio sobre el fondo degradado.
  late bool _intro = !widget.afterLogin;
  final _introDone = Completer<void>();
  DateTime _shownAt = DateTime.now();

  // La app armada por debajo, y la pantalla de carga desvaneciéndose/quitada.
  bool _shell = false;
  bool _fading = false;
  bool _gone = false;

  String _status = "PREPARANDO LA MESA…";
  double _base = 0.08; // avance propio (sesión); el resto lo aporta el Inicio

  void _step(double target, String status) {
    if (!mounted) return;
    setState(() {
      _base = target;
      _status = status;
    });
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
      Future.delayed(_introLength, () {
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

  // Solo desarrollo: entra solo con la cuenta que se pase al levantar la
  // app (nunca queda en el código ni en el APK de producción):
  //   flutter run -d chrome --dart-define=DEV_EMAIL=tu@mail.com --dart-define=DEV_PASSWORD=tuclave
  static const _devEmail = String.fromEnvironment("DEV_EMAIL");
  static const _devPassword = String.fromEnvironment("DEV_PASSWORD");

  Future<bool> _devAutoLogin() async {
    if (!kDebugMode || _devEmail.isEmpty || _devPassword.isEmpty) return false;
    try {
      final resp = await AuthApi().login(email: _devEmail, password: _devPassword);
      await SessionStorage().saveSession(token: resp.token, role: "player", userId: resp.user.idUser, email: resp.user.email);
      if (!mounted) return true;
      Navigator.pushReplacement(context, CyberPageRoute(waitForData: false, builder: (_) => const SplashGate(afterLogin: true)));
      return true;
    } catch (e) {
      debugPrint("[dev] auto-login falló: $e");
      return false;
    }
  }

  Future<void> _toLogin() async {
    if (await _devAutoLogin()) return;
    _step(1, "¡A JUGAR!");
    await _waitMinShown();
    if (!mounted) return;
    Navigator.pushReplacement(context, CyberPageRoute(waitForData: false, builder: (_) => const LoginScreen()));
  }

  // Versión de la app frente a la mínima del servidor: se consulta en
  // paralelo con la intro y, si ya no es compatible, la app no sigue.
  final Future<void> _updateCheck = AppUpdate.check();

  Future<void> _route() async {
    await _updateCheck;
    if (AppUpdate.mustUpdate) {
      await _waitMinShown();
      if (!mounted) return;
      Navigator.pushReplacement(context, CyberPageRoute(waitForData: false, builder: (_) => const ForceUpdateScreen()));
      return;
    }
    final storage = SessionStorage();
    if (!widget.afterLogin) {
      _step(0.15, "PREPARANDO LA MESA…");
      final token = await storage.getToken();
      final role = await storage.getRole();
      Monitoring.setUser(await storage.getUserId());
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
      // Se verifica EN PARALELO con el armado de la app (antes se esperaba
      // esta respuesta y recién ahí arrancaba el Inicio: un viaje de red
      // entero sumado a la carga).
      final me = ProfileApi().getMe().then((_) => true, onError: (e) => !e.toString().contains("HTTP 401"));
      _step(0.35, "AJUSTANDO LA RED…");
      setState(() => _shell = true);
      if (!await me) {
        await storage.clear();
        if (mounted) await _toLogin();
        return;
      }
      if (!mounted) return;
    } else {
      // Se arma la app por debajo; el Inicio empieza a traer sus datos.
      _step(0.35, "AJUSTANDO LA RED…");
      setState(() => _shell = true);
    }
    await ShellPreload.ready.timeout(_maxWait, onTimeout: () {});
    _step(1, "¡A JUGAR!");
    await _waitMinShown();
    await Future.delayed(const Duration(milliseconds: 100)); // que se vea el 100 %
    if (!mounted) return;
    // Se quita la pantalla de carga: el Inicio ya está completo debajo.
    setState(() => _fading = true);
    ShellPreload.revealed.value = true;
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _gone = true);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final overlay = Material(
      color: AppColors.scorifyBg,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: overlay,
            ),
          ),
      ],
    );
  }

  // Azules del borde de arriba y de abajo de la imagen de carga: rellenan
  // lo que queda libre arriba y abajo.
  static const _splashFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0057B7), Color(0xFF096EA7)],
  );

  /// Imagen de carga (logo y "My Table Tennis Manager" ya vienen en ella).
  /// Va al ancho de la pantalla para que el texto no se corte; arriba y abajo
  /// queda el mismo azul, y los bordes de la imagen se funden en él.
  Widget _splashImage(MediaQueryData mq) => DecoratedBox(
        decoration: const BoxDecoration(gradient: _splashFill),
        child: Center(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.12, 0.88, 1],
            ).createShader(r),
            child: Image(
              image: ResizeImage(
                const AssetImage("assets/images/loading_bg.jpg"),
                width: (mq.size.width * mq.devicePixelRatio).round().clamp(360, 1024),
              ),
              width: mq.size.width,
              fit: BoxFit.fitWidth,
              gaplessPlayback: true,
            ),
          ),
        ),
      );

  /// Fase 1: la imagen de carga sola.
  Widget _logoIntro() => KeyedSubtree(
        key: const ValueKey("intro"),
        child: _splashImage(MediaQuery.of(context)),
      );

  /// Fase 2: la misma imagen con la barra de carga abajo.
  Widget _loading(MediaQueryData mq) {
    return Stack(
        key: const ValueKey("loading"),
        fit: StackFit.expand,
        children: [
          _splashImage(mq),
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
                          borderRadius: BorderRadius.circular(Panel.buttonRadius),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: appButtonGradient,
                              borderRadius: BorderRadius.circular(Panel.radius),
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

  static const TextStyle _small = TextStyle(
    fontFamily: AppTypography.body,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    color: AppColors.scorifyTextMuted,
  );
}
