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
        ClipRRect(
          borderRadius: BorderRadius.circular(markSize * 0.22),
          child: Image.asset(
            'assets/images/logo-mark.png',
            width: markSize,
            height: markSize,
            filterQuality: FilterQuality.medium,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.32),
          Text(
            'MYTTM',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
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
