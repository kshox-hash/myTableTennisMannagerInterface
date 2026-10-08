import 'package:flutter/material.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:video_player/video_player.dart';

/// Video de fondo de Inicio: en silencio y en bucle, arriba de la pantalla
/// (donde iba la foto). Se desvanece hacia abajo y se funde con el fondo
/// general de la app (PrismBackground), sin borde recto.
///
/// Para no cargar la app:
///  - se pausa cuando Inicio no es la pestaña visible y cuando la app pasa a
///    segundo plano (vuelve a reproducirse al volver);
///  - mientras carga (o si falla) no se dibuja nada: se ve el fondo normal.
class HomeVideoBackground extends StatefulWidget {
  const HomeVideoBackground({super.key});

  @override
  State<HomeVideoBackground> createState() => _HomeVideoBackgroundState();
}

class _HomeVideoBackgroundState extends State<HomeVideoBackground>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _appActive = true;
  bool _tabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      "assets/videos/home_bg.mp4",
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.setLooping(true);
    _controller.setVolume(0);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _syncPlayback();
        })
        .catchError((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicio vive en un IndexedStack: sigue montado en las otras pestañas.
    final scope = AppShellScope.of(context);
    _tabVisible = scope == null || scope.currentIndex == 0;
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  void _syncPlayback() {
    if (!_ready) return;
    final shouldPlay = _appActive && _tabVisible;
    if (shouldPlay && !_controller.value.isPlaying) {
      _controller.play();
    } else if (!shouldPlay && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final videoSize = _controller.value.size;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size.width,
          height: size.height * 0.72,
          // Sin ShaderMask: en web no se aplica a los videos y quedaba un corte
          // recto abajo. La última capa funde hacia el color del fondo.
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoom sobre la copa (está chica arriba a la derecha en el
              // video): más grande y un poco más abajo, para que llene la
              // zona libre entre el encabezado y la tarjeta de Próximo partido.
              ClipRect(
                child: Transform(
                  alignment: const Alignment(0.46, -0.4),
                  transform: Matrix4.translationValues(0, size.height * 0.72 * 0.12, 0)
                    ..scaleByDouble(1.35, 1.35, 1, 1),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoSize.width,
                      height: videoSize.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
              // Arriba más oscuro: el encabezado se lee sobre el video.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000)],
                    stops: [0, 0.22],
                  ),
                ),
              ),
              // Oscurece la izquierda: el saludo se lee sobre el video.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0x00000000),
                    ],
                    stops: [0.1, 0.55, 1],
                  ),
                ),
              ),
              // Funde el borde inferior con el fondo general (sin corte recto).
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00060E12),
                      Color(0x00060E12),
                      Color(0xFF060E12),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
