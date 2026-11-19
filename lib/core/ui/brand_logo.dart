import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Logo oficial MYTTM (el 3D metálico del login): la M y, opcionalmente, la
/// palabra "MyTTM" al lado. Un solo lugar para
/// la marca: antes cada pantalla dibujaba su propio ícono (bolt, raqueta) y
/// su propio texto ("SPINARENA", "myTTMI").
class BrandLogo extends StatelessWidget {
  final double markSize;
  final bool showWordmark;
  final double? wordmarkSize;
  final Color wordmarkColor;

  /// Versión monocromo (isotipo blanco + "TTM" azul hielo) para la paleta cobalto.
  final bool mono;

  const BrandLogo({
    super.key,
    this.markSize = 32,
    this.showWordmark = true,
    this.wordmarkSize,
    this.wordmarkColor = AppColors.scorifyText,
    this.mono = false, // M oficial (celeste + verde lima)
  });

  @override
  Widget build(BuildContext context) {
    // Logo oficial = el del login (3D metálico): la M y la palabra "MyTTM"
    // recortadas de assets/images/3.0x/logo-stacked.png y puestas en línea.
    final wordH = (wordmarkSize ?? markSize * 0.62) * 1.3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          "assets/images/logo-mark-3d.png",
          height: markSize * 1.1,
          filterQuality: FilterQuality.medium,
          isAntiAlias: true,
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.28),
          Image.asset(
            "assets/images/logo-word-3d.png",
            height: wordH,
            filterQuality: FilterQuality.medium,
            isAntiAlias: true,
            semanticLabel: "MyTTM",
          ),
        ],
      ],
    );
  }
}
