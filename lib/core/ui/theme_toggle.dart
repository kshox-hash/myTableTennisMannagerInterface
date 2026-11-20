import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Botón redondo ☀/🌙 para cambiar entre modo claro y oscuro. Va en el
/// encabezado de las secciones (junto a la campana) y en el login.
/// [onPhoto]: sobre la foto del login (fondo translúcido según el modo).
class ThemeToggleButton extends StatelessWidget {
  final bool onPhoto;
  final double size;
  const ThemeToggleButton({super.key, this.onPhoto = false, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.light,
      builder: (context, light, _) {
        final bg = onPhoto
            ? (light ? const Color(0xB3FFFFFF) : const Color(0x59000000))
            : AppColors.scorifyInput;
        final fg = onPhoto ? (light ? const Color(0xFF18181B) : Colors.white) : AppColors.scorifyText;
        return Semantics(
          button: true,
          label: light ? "Cambiar a modo oscuro" : "Cambiar a modo claro",
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => AppColors.setLight(!light),
              child: SizedBox(
                width: size,
                height: size,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  // En claro se muestra la luna (para pasar a oscuro) y al revés.
                  child: Icon(
                    light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    key: ValueKey(light),
                    size: 20,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
