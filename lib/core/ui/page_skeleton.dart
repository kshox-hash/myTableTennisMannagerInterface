import "package:myttmi/core/ui/panel_style.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/ui/top_header.dart";

/// Cortina de carga de una pantalla entera (la usa CyberPageRoute).
///
/// Antes cada pantalla mostraba al instante sus partes fijas (título,
/// filtros, botones) y el esqueleto solo en el bloque que esperaba datos:
/// se veía armándose por pedazos. Ahora la pantalla real se arma por debajo
/// —y pide sus datos— mientras encima se ve un esqueleto de página completa;
/// cuando no queda ningún pedido en curso (ApiActivity.settle) el esqueleto
/// se desvanece y aparece todo junto. Tope de espera: [maxWait] (sin señal,
/// la pantalla entra igual con lo que tenga).
class LoadingCurtain extends StatefulWidget {
  final Widget child;
  final Duration maxWait;
  const LoadingCurtain({super.key, required this.child, this.maxWait = const Duration(seconds: 12)});

  @override
  State<LoadingCurtain> createState() => _LoadingCurtainState();
}

class _LoadingCurtainState extends State<LoadingCurtain> {
  bool _ready = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    ApiActivity.settle(max: widget.maxWait).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_gone)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _ready,
              child: AnimatedOpacity(
                opacity: _ready ? 0 : 1,
                duration: const Duration(milliseconds: 90),
                onEnd: () {
                  if (_ready && mounted) setState(() => _gone = true);
                },
                child: const PageSkeleton(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Esqueleto genérico de una pantalla: encabezado (con el botón volver, que
/// funciona) y bloques con la forma típica — tarjeta principal, fila de
/// accesos y lista — con un brillo suave que los cruza en diagonal (antes
/// latían enteros). Sobre el mismo degradado de las pantallas, para que no
/// haya salto de fondo al aparecer la pantalla real.
class PageSkeleton extends StatefulWidget {
  const PageSkeleton({super.key});

  @override
  State<PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<PageSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _block(double height, {double? width, double radius = 14, Color color = AppColors.scorifyCardFill}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      );

  Widget _bar(double width, double height) => _block(height, width: width, radius: 6, color: AppColors.scorifySurface2);

  Widget _row() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(Panel.radius)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.scorifySurface2, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_bar(150, 12), const SizedBox(height: 8), _bar(100, 10)],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.scorifyBg, gradient: AppColors.appBackground),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop) ...[
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                  ],
                  _shimmer(_bar(160, 20)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _shimmer(
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _block(150),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _block(64)),
                            const SizedBox(width: 10),
                            Expanded(child: _block(64)),
                            const SizedBox(width: 10),
                            Expanded(child: _block(64)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _bar(120, 14),
                        const SizedBox(height: 12),
                        for (var i = 0; i < 4; i++) _row(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Brillo: una franja clara y tenue que cruza los bloques en diagonal, solo
  /// donde hay bloque (srcATop), de izquierda a derecha y vuelta a empezar.
  Widget _shimmer(Widget child) => AnimatedBuilder(
        animation: _c,
        child: child,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          final x = -1.6 + t * 3.2; // de bien a la izquierda a bien a la derecha
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment(x - 0.6, -0.3),
              end: Alignment(x + 0.6, 0.3),
              colors: const [Color(0x00FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
            ).createShader(rect),
            child: child,
          );
        },
      );
}
