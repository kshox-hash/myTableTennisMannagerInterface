import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Isotipo oficial MYTTM (assets/images/logo-mark.png, el mismo PNG que usa
/// la web) + opcionalmente el wordmark "MYTTM" al lado. Un solo lugar para
/// la marca: antes cada pantalla dibujaba su propio ícono (bolt, raqueta) y
/// su propio texto ("SPINARENA", "myTTMI").
class BrandLogo extends StatelessWidget {
  final double markSize;
  final bool showWordmark;
  final double? wordmarkSize;
  final Color wordmarkColor;

  const BrandLogo({
    super.key,
    this.markSize = 32,
    this.showWordmark = true,
    this.wordmarkSize,
    this.wordmarkColor = AppColors.scorifyText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // La M nueva tiene fondo transparente y llega casi al borde: sin
        // recorte redondeado (le comía las puntas) y escalado en alta
        // calidad para que no se vea serruchada al achicarla.
        Image.asset(
          'assets/images/logo-mark.png',
          width: markSize,
          height: markSize,
          // "medium" (mipmaps) y no "high": en web "high" no promedia al
          // achicar mucho (512 → ~30 px) y deja los bordes dentados.
          filterQuality: FilterQuality.medium,
          isAntiAlias: true,
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.32),
          Text(
            'MYTTM',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: wordmarkSize ?? markSize * 0.62,
              letterSpacing: 0.5,
              color: wordmarkColor,
            ),
          ),
        ],
      ],
    );
  }
}
