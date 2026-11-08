import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Estilo flat de toda la app (rediseño 2026-11): tarjetas gris oscuro
/// lisas con esquinas redondeadas, sin filete, sin líneas encendidas ni
/// degradados. Los nombres se mantienen del estilo "panel" anterior para no
/// tocar los call sites.
abstract final class Panel {
  static const double radius = 14;

  /// Filete (casi no se usa: las tarjetas van sin borde).
  static const edge = AppColors.scorifyCardBorder;
  static const edgeStrong = AppColors.scorifyCardBorderStrong;

  /// Antes era la línea encendida; ahora un separador apenas visible.
  static const topLine = Color(0x14FFFFFF);

  /// Antes la franja gris del título; ahora transparente (título suelto).
  static const titleStrip = Colors.transparent;

  static const gradient = AppColors.cardGradient;
  static const featuredGradient = AppColors.featuredGradient;

  /// Cajas de dato / campos de texto: un gris más claro que la tarjeta.
  static const field = AppColors.scorifySurface2;
  static const fieldBorder = Colors.transparent;

  static const double buttonRadius = 10;
  static const buttonBorder = Colors.transparent;

  /// Botón secundario: gris liso.
  static const buttonGradient = LinearGradient(colors: [Color(0x1FFFFFFF), Color(0x1FFFFFFF)]);

  /// "Elegido / activo" (pestaña, filtro, opción del menú): celeste muy
  /// tenue, liso. El botón principal NO usa esto: es celeste sólido.
  static const primaryButtonGradient = LinearGradient(colors: [Color(0xFF12293A), Color(0xFF12293A)]);
  static const primaryButtonBorder = Colors.transparent;

  /// Botón de peligro: rojo tenue, liso.
  static const dangerButtonGradient = LinearGradient(colors: [Color(0xFF3A1D20), Color(0xFF3A1D20)]);
  static const dangerButtonBorder = Colors.transparent;

  /// Ventanas emergentes y paneles que suben desde abajo.
  static const sheetColor = AppColors.scorifyDeep;
  static const ShapeBorder sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
  );
  static const dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
}

/// Antes: línea encendida bajo los títulos. En el estilo flat no se pinta
/// nada (se deja el widget para no tocar los call sites).
class PanelGlowLine extends StatelessWidget {
  const PanelGlowLine({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Título de tarjeta: ícono chico + nombre en gris claro, como las etiquetas
/// de las tarjetas de un dashboard ("Geo", "Demographic"). Acción a la
/// derecha.
class PanelTitleBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;
  const PanelTitleBar({super.key, required this.title, this.icon, this.iconColor = AppColors.scorifyTextMuted, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, trailing == null ? 14 : 8, trailing == null ? 16 : 8, 0),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: iconColor), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              _sentence(title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "ÚLTIMOS PARTIDOS" → "Últimos partidos" (los títulos viejos venían en
/// mayúsculas); si ya viene en minúsculas se deja igual.
String _sentence(String s) {
  if (s.isEmpty || s != s.toUpperCase()) return s;
  final lower = s.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Etiqueta de estado: fondo teñido del color, texto del color, sin borde,
/// esquinas redondeadas. El color sigue diciendo lo mismo (lima =
/// victoria/inscrito, ámbar = pendiente, rojo = derrota…); `null` = neutra.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.16) ?? Panel.field,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 2, color: fg), const SizedBox(width: 4)],
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

/// Caja de ícono / marcador: fondo teñido del color (o gris si no tiene).
/// Con `selected` lleva el celeste tenue de "elegido / ganado".
BoxDecoration panelBox({Color? color, bool selected = false, bool circle = false}) => BoxDecoration(
      color: selected ? null : (color?.withValues(alpha: 0.14) ?? Panel.field),
      gradient: selected ? Panel.primaryButtonGradient : null,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(Panel.buttonRadius),
    );
