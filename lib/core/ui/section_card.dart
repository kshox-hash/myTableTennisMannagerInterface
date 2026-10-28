import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/card_border.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Tarjeta con título: ícono y nombre de la sección en mayúsculas de color ("SETS", "ÚLTIMOS PARTIDOS"),
/// opcionalmente con un ícono y una acción a la derecha ("Ver historial").
/// Se usa en toda la app para que las tarjetas con título se vean iguales.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fondo; por defecto el degradado tenue de tarjeta.
  final Gradient? gradient;

  /// El contenido ocupa todo el alto que le den a la tarjeta (centrado).
  final bool fill;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
    this.titleColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    this.fill = false,
  });

  static const _radius = Panel.radius;

  @override
  Widget build(BuildContext context) {
    // Estilo panel: franja de título gris en mayúsculas espaciadas, con la
    // línea encendida debajo; ícono de color y acción a la derecha.
    final color = titleColor ?? AppColors.scorifyMint;
    final header = PanelTitleBar(title: title, icon: icon, iconColor: color, trailing: trailing);
    final body = Padding(padding: padding, child: child);
    return CardBorder(
      radius: _radius,
      highlight: gradient == AppColors.featuredGradient,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient ?? AppColors.cardGradient),
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (fill) Expanded(child: Center(child: body)) else body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filas de una lista dentro de una tarjeta, separadas por una línea fina
/// (en vez de una tarjeta por fila).
List<Widget> dividedRows(Iterable<Widget> rows) {
  final out = <Widget>[];
  for (final r in rows) {
    if (out.isNotEmpty) out.add(const Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF)));
    out.add(r);
  }
  return out;
}

/// Título de sección suelto (sobre una lista): mismo estilo que el título de
/// las tarjetas — ícono + mayúsculas turquesa.
class SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionLabel(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: AppColors.scorifyMint), const SizedBox(width: 8)],
        Text(text,
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.scorifyText)),
      ],
    );
  }
}
