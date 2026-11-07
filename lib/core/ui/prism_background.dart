import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de la app: una imagen (por defecto assets/images/app_bg.jpg) con
/// una capa oscura encima para que tarjetas y textos mantengan contraste.
/// El login usa su propia imagen ([loginAsset]) con una capa más densa,
/// porque es más brillante. Estático: el RepaintBoundary lo aísla del
/// scroll. [image] se mantiene por compatibilidad y no hace nada.
class PrismBackground extends StatelessWidget {
  final Widget child;
  final bool image;

  /// Imagen de fondo; null = la de toda la app.
  final String? asset;

  /// Capa oscura propia (de arriba hacia abajo); null = la de la app.
  final List<Color>? scrim;

  /// true = capa liviana (el Inicio: el fondo se ve "normal"); false = la
  /// más oscura del resto de las pantallas, para que el contenido destaque.
  final bool bright;

  const PrismBackground({super.key, required this.child, this.image = false, this.asset, this.scrim, this.bright = false});

  /// Inicio: densa solo en la franja del encabezado (contraste del título),
  /// liviana en el medio para que se vea la imagen.
  static const homeScrim = [Color(0xCC000000), Color(0x99000000), Color(0x26000000), Color(0x59000000)];

  /// Resto de las pantallas: bastante más oscura en todo el alto.
  static const innerScrim = [Color(0xE6000000), Color(0xCC000000), Color(0x99000000), Color(0xB3000000)];

  /// Solo para el login: imagen propia y casi sin capa.
  const PrismBackground.login({super.key, required this.child})
      : image = false,
        bright = false,
        asset = loginAsset,
        // Casi sin capa: la imagen ya trae negro arriba y abajo, y la
        // tarjeta del formulario tiene su propio relleno para leerse.
        scrim = const [Color(0x00000000), Color(0x0F000000), Color(0x26000000)];

  static const color = AppColors.scorifyBg;
  static const appAsset = 'assets/images/app_bg.jpg';
  static const loginAsset = 'assets/images/login_bg.jpg';

  /// Solo la pestaña Inicio (AppShell la elige según la pestaña activa).
  static const homeAsset = 'assets/images/home_bg.jpg';

  /// Llamar una vez al iniciar (con un context ya montado) para que la
  /// primera pantalla no aparezca un instante sin el fondo.
  static Future<void> precache(BuildContext context) => Future.wait([
        precacheImage(const AssetImage(appAsset), context),
        precacheImage(const AssetImage(loginAsset), context),
        precacheImage(const AssetImage(homeAsset), context),
      ]);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: AssetImage(asset ?? appAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
                // Capa oscura. La general es más densa en la franja de
                // arriba, donde van el título y los botones del encabezado
                // (ahí la imagen tiene puntos y franjas claras que le
                // quitaban contraste a las letras); se aclara hacia el
                // medio y vuelve a oscurecerse un poco abajo.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: scrim != null
                        ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: scrim!)
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.14, 0.32, 1],
                            colors: bright ? homeScrim : innerScrim,
                          ),
                  ),
                ),
              ],
            ),
          ),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
