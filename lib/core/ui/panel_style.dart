import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Estilo "panel" de toda la app (medido de la referencia que eligió el
/// usuario): esquinas casi rectas, filete verde azulado oscuro, línea
/// encendida de 1 px en el borde superior, franja de título gris neutra con
/// una línea debajo que se enciende al centro, y botones con degradado
/// vertical de casi negro a verde azulado.
abstract final class Panel {
  static const double radius = 4;

  /// Filete de la tarjeta.
  static const edge = Color(0xFF125450);

  /// Filete de la tarjeta destacada (la principal de la pantalla).
  static const edgeStrong = Color(0xFF1C7F79);

  /// Línea encendida del borde superior.
  static const topLine = Color(0xFF31817D);

  /// Franja del título.
  static const titleStrip = Color(0xFF212628);

  /// Cuerpo: verde azulado casi negro arriba, apenas más claro abajo.
  static const gradient = AppColors.cardGradient;

  /// Cuerpo de la tarjeta destacada: un paso más claro.
  static const featuredGradient = AppColors.featuredGradient;

  /// Cajas de dato / campos de texto: gris casi negro liso.
  static const field = Color(0xFF1A1D1D);
  static const fieldBorder = Color(0xFF3E4A4E);

  static const double buttonRadius = 3;
  static const buttonBorder = Color(0xFF4F6166);

  /// Botón secundario: casi negro arriba → verde azulado abajo.
  static const buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.45, 0.85, 1],
    colors: [Color(0xFF171A1A), Color(0xFF1B2121), Color(0xFF173332), Color(0xFF1A4442)],
  );

  /// Botón principal: misma estructura, el fondo tira al celeste de marca.
  static const primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.45, 0.85, 1],
    colors: [Color(0xFF151A1C), Color(0xFF16242A), Color(0xFF0E3B47), Color(0xFF0F5263)],
  );
  static const primaryButtonBorder = Color(0xA600B3D6);

  /// Botón de peligro: igual, el fondo tira a rojo.
  static const dangerButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.45, 0.85, 1],
    colors: [Color(0xFF1C1616), Color(0xFF2A1A1B), Color(0xFF4A1F22), Color(0xFF632629)],
  );
  static const dangerButtonBorder = Color(0xCCFF5C5C);

  /// Ventanas emergentes y paneles que suben desde abajo: fondo del panel
  /// (opaco) con su filete; el título va en PanelTitleBar.
  static const sheetColor = Color(0xFF0E1D20);
  static const sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    side: BorderSide(color: edge),
  );
  static const dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    side: BorderSide(color: edge),
  );
}

/// Línea bajo el título: gris en las puntas, encendida al centro, con un
/// halo de 2 px debajo.
class PanelGlowLine extends StatelessWidget {
  const PanelGlowLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0, 0.22, 0.45, 0.62, 0.8, 1],
              colors: [Color(0xFF3F4243), Color(0xFF365252), Color(0xFF12A39A), Color(0xFF237671), Color(0xFF3F4243), Color(0xFF3F4243)],
            ),
          ),
          child: SizedBox(height: 1),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0, 0.25, 0.45, 0.65, 1],
              colors: [Color(0x0012A39A), Color(0x1A12A39A), Color(0x5912A39A), Color(0x1A12A39A), Color(0x0012A39A)],
            ),
          ),
          child: SizedBox(height: 2),
        ),
      ],
    );
  }
}

/// Franja de título de panel: gris neutro, mayúsculas espaciadas, acción a
/// la derecha y la línea encendida debajo.
class PanelTitleBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;
  const PanelTitleBar({super.key, required this.title, this.icon, this.iconColor = AppColors.scorifyMint, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Panel.titleStrip,
          padding: EdgeInsets.fromLTRB(14, trailing == null ? 10 : 6, trailing == null ? 14 : 8, trailing == null ? 10 : 6),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: iconColor), const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: AppColors.scorifyText),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const PanelGlowLine(),
      ],
    );
  }
}

/// Etiqueta de estado (estilo panel): fondo gris casi negro, filete de 1 px
/// del color y texto del color, esquinas de 3 px. Reemplaza a las píldoras
/// redondas con fondo teñido o sólido. El color sigue diciendo lo mismo
/// (lima = victoria/inscrito, ámbar = pendiente, rojo = derrota…); `null`
/// = neutra (texto apagado, filete gris).
class PanelChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final double fontSize;
  const PanelChip({super.key, required this.label, this.color, this.icon, this.fontSize = 12});

  /// Para las etiquetas viejas que venían como (fondo, texto): si el texto
  /// es oscuro (iba sobre un fondo sólido) el color es el del fondo; si el
  /// fondo era neutro, queda neutra.
  factory PanelChip.fromColors({Key? key, required String label, required Color bg, required Color fg, IconData? icon}) {
    final Color? c;
    final fgLum = fg.computeLuminance();
    // Fondo sólido de color (no el gris de superficie): el color es el fondo
    // cuando el texto era oscuro o blanco puesto encima.
    final bgSolid = bg.a > 0.5 && bg != AppColors.scorifySurface2 && bg != AppColors.scorifyInput;
    if (bgSolid && (fgLum < 0.08 || fgLum > 0.85)) {
      c = bg.withValues(alpha: 1);
    } else if (fg == AppColors.scorifyTextMuted || fg == AppColors.scorifyTextFaint || fg == AppColors.scorifyText || fgLum > 0.85) {
      c = null;
    } else {
      c = fg;
    }
    return PanelChip(key: key, label: label, color: c, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.scorifyTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Panel.field,
        borderRadius: BorderRadius.circular(Panel.buttonRadius),
        border: Border.all(color: color?.withValues(alpha: 0.6) ?? Panel.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 2, color: fg), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: AppTypography.body, fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja de ícono / marcador (estilo panel): en vez de un bloque de color
/// sólido, gris casi negro con filete del color. Con `selected` lleva el
/// degradado del botón principal (marca "elegido / ganado").
BoxDecoration panelBox({Color? color, bool selected = false, bool circle = false}) => BoxDecoration(
      color: selected ? null : Panel.field,
      gradient: selected ? Panel.primaryButtonGradient : null,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(Panel.buttonRadius),
      border: Border.all(
        color: selected ? Panel.primaryButtonBorder : (color?.withValues(alpha: 0.6) ?? Panel.fieldBorder),
      ),
    );
