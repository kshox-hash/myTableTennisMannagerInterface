import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/card_border.dart";

/// Tarjeta con cabecera: una franja un poco más clara arriba con el nombre
/// de la sección en mayúsculas y letra fina ("SETS", "ÚLTIMOS PARTIDOS"),
/// y opcionalmente una acción a la derecha ("Ver historial").
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    return CardBorder(
      radius: _radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: ColoredBox(
          color: AppColors.scorifyCardFill,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF17303B),
                padding: EdgeInsets.fromLTRB(16, trailing == null ? 11 : 4, trailing == null ? 16 : 6, trailing == null ? 11 : 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTypography.body,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: AppColors.scorifyText,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              Padding(padding: padding, child: child),
            ],
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
