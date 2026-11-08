import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/features/auth/presentation/login_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Presentación de la primera vez (antes del login): un carrusel corto con
/// lo que hace la app — no un recorrido guiado. Se desliza o se avanza con
/// "Siguiente"; "Saltar" va directo al login. Se muestra una sola vez (se
/// puede volver a ver desde Ajustes).
class OnboardingScreen extends StatefulWidget {
  /// true: se abrió desde Ajustes (al terminar vuelve atrás, no al login).
  final bool fromSettings;
  const OnboardingScreen({super.key, this.fromSettings = false});

  static const _key = "onboarding_seen_v1";

  static Future<bool> seen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return true; // ante cualquier problema, no bloquear la entrada
    }
  }

  static Future<void> markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static final _slides = <_Slide>[
    const _Slide(
      eyebrow: "BIENVENIDO A MyTTM",
      title: "Tus campeonatos de tenis de mesa, en un solo lugar",
      text: "Inscríbete, mira tu grupo, tu rival y tu mesa, y sigue cada resultado desde el celular.",
      art: _ArtWelcome(),
    ),
    const _Slide(
      eyebrow: "SIGUE UN CAMPEONATO",
      title: "¿No juegas? Síguelo igual",
      text: "Familia, amigos o compañeros de club: toca \"Seguir\" en cualquier campeonato y te avisamos cuando empiece cada categoría, salga la llave y haya campeones. Sin inscribirte.",
      art: _ArtFollow(),
    ),
    const _Slide(
      eyebrow: "EN VIVO",
      title: "Resultados al instante",
      text: "Grupos con quién va clasificando, la llave completa, las mesas en juego y el podio de cada categoría.",
      art: _ArtLive(),
    ),
    const _Slide(
      eyebrow: "SI JUEGAS",
      title: "Te avisamos cuando te toca",
      text: "Tu mesa, tu próximo rival, cada resultado y cómo terminaste. Además, tus estadísticas, tu racha y el ranking.",
      art: _ArtPlayer(),
    ),
  ];

  bool get _last => _page == _slides.length - 1;

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, CyberPageRoute(waitForData: false, builder: (_) => const LoginScreen()));
    }
  }

  void _next() {
    if (_last) {
      _finish();
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: TextButton(
                      onPressed: _last ? null : _finish,
                      child: const Text("Saltar", style: TextStyle(fontFamily: AppTypography.body, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              // Puntos de avance.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.scorifyMint : AppColors.scorifySurface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: AppButton(label: _last ? "Empezar" : "Siguiente", onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final String eyebrow;
  final String title;
  final String text;
  final Widget art;
  const _Slide({required this.eyebrow, required this.title, required this.text, required this.art});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SizedBox(height: 230, child: Center(child: slide.art))),
              const SizedBox(height: 28),
              Text(
                slide.eyebrow,
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: AppColors.scorifyMint),
              ),
              const SizedBox(height: 10),
              Text(
                slide.title,
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 25, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.scorifyText),
              ),
              const SizedBox(height: 12),
              Text(slide.text, style: AppTypography.bodyMuted.copyWith(fontSize: 15, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Ilustraciones: piezas de la propia app en miniatura -------------------

/// Un aviso como los que llegan al celular.
class _MockNotif extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final bool faded;
  const _MockNotif(this.emoji, this.title, this.body, {this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: Container(
        width: 290,
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(Panel.radius)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(10)),
              child: Text(emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyText)),
                  const SizedBox(height: 2),
                  Text(body, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, color: AppColors.scorifyTextMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtWelcome extends StatelessWidget {
  const _ArtWelcome();

  @override
  Widget build(BuildContext context) => const Image(
        image: AssetImage("assets/images/logo-stacked.png"),
        width: 220,
        filterQuality: FilterQuality.medium,
      );
}

class _ArtFollow extends StatelessWidget {
  const _ArtFollow();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // El botón "Seguir" tal como se ve en la ficha del campeonato.
        Container(
          width: 290,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.scorifyCardFill,
            borderRadius: BorderRadius.circular(Panel.radius),
            border: Border.all(color: AppColors.scorifyMint.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.scorifyMint, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("Copa Primavera",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.scorifyText)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.scorifyMint, borderRadius: BorderRadius.circular(Panel.buttonRadius)),
                child: const Text("Seguir",
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.scorifyOnMint)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _MockNotif("👀", "Empezó Todo Competidor", "Ya están los grupos. Sigue los resultados en vivo."),
        const SizedBox(height: 8),
        const _MockNotif("🏆", "Campeón de Todo Competidor", "Diego Vásquez ganó la categoría.", faded: true),
      ],
    );
  }
}

class _ArtLive extends StatelessWidget {
  const _ArtLive();

  @override
  Widget build(BuildContext context) {
    Widget row(int pos, String name, String g, Color? zone) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(width: 3, height: 22, decoration: BoxDecoration(color: zone ?? Colors.transparent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                child: Text("$pos",
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: zone ?? AppColors.scorifyTextMuted)),
              ),
              Expanded(
                child: Text(name, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
              ),
              Text(g, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
            ],
          ),
        );
    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(Panel.radius)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Grupo 3",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyTextMuted)),
              const Spacer(),
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.scorifyLive, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text("Mesa 4",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.scorifyLive)),
            ],
          ),
          const SizedBox(height: 6),
          row(1, "Camila Rojas", "3", AppColors.scorifyMint),
          row(2, "Tomás Fuentes", "2", AppColors.scorifyMint),
          row(3, "Ignacio Vera", "1", const Color(0xFFB8C4CC)),
          row(4, "Martín Soto", "0", null),
        ],
      ),
    );
  }
}

class _ArtPlayer extends StatelessWidget {
  const _ArtPlayer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MockNotif("🏓", "Te toca en la mesa 3", "Contra Tomás Fuentes · ¡suerte!"),
        SizedBox(height: 8),
        _MockNotif("✅", "Ganaste tu partido", "3 - 1 · Sigues primero en tu grupo"),
        SizedBox(height: 8),
        _MockNotif("🥉", "¡Tercer lugar!", "Queda guardado en tu perfil.", faded: true),
      ],
    );
  }
}
