import "package:myttmi/core/ui/panel_style.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";

/// Una categoría para [CategoryFilterBar]: id (o la etiqueta, donde no hay
/// id) y el texto del chip.
typedef CategoryOption = ({String id, String label});

/// Selector de categoría del campeonato (Partidos, Jugadores, Mesas): se ve
/// una categoría a la vez — mezclar las de todas en una lista no se
/// entendía. Es UN botón compacto ("Libre ▾") que abre la lista, con
/// "Todas" al final; antes era una fila de chips que, sumada a las otras
/// filas de filtros, amontonaba la pantalla. [trailing] va a la derecha en
/// la misma línea (p. ej. el filtro Todos / Por jugar / Jugados).
/// Con una sola categoría solo se muestra [trailing].
class CategoryFilterBar extends StatelessWidget {
  final List<CategoryOption> options;
  /// null = "Todas".
  final String? selected;
  final ValueChanged<String?> onChanged;
  final Widget? trailing;
  const CategoryFilterBar({super.key, required this.options, required this.selected, required this.onChanged, this.trailing});

  /// Categoría inicial: la mía si estoy en alguna, si no la primera.
  static String? initial(List<CategoryOption> options, Iterable<String> mine) {
    if (options.isEmpty) return null;
    for (final o in options) {
      if (mine.contains(o.id)) return o.id;
    }
    return options.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final showCategory = options.length >= 2;
    if (!showCategory && trailing == null) return const SizedBox.shrink();
    final current = selected == null
        ? "Todas las categorías"
        : options.firstWhere((o) => o.id == selected, orElse: () => (id: "", label: "Categoría")).label;
    return Row(
      children: [
        if (showCategory)
          Flexible(
            child: FilterDropdown(
              icon: Icons.sell_outlined,
              label: current,
              onTap: () async {
                final picked = await showOptionsSheet<String?>(
                  context,
                  title: "Categoría",
                  options: [for (final o in options) (value: o.id, label: o.label), (value: null, label: "Todas")],
                  selected: selected,
                );
                if (picked != null) onChanged(picked.value);
              },
            ),
          ),
        // Con filtros a la derecha se reparten el ancho (en celulares chicos
        // el texto se corta con "…" en vez de desbordar la fila).
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!)),
        ] else
          const Spacer(),
      ],
    );
  }
}

/// Botón compacto de filtro: ícono + valor actual + ▾.
class FilterDropdown extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  const FilterDropdown({super.key, this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scorifySurface2,
      borderRadius: BorderRadius.circular(Panel.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Panel.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.scorifyMint),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.scorifyTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de opciones desde abajo; devuelve la elegida envuelta (así "Todas"
/// —valor null— se distingue de cerrar sin elegir).
Future<({T value})?> showOptionsSheet<T>(
  BuildContext context, {
  required String title,
  required List<({T value, String label})> options,
  required T selected,
}) {
  return showModalBottomSheet<({T value})>(
    context: context,
    backgroundColor: Panel.sheetColor,
    shape: Panel.sheetShape,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelTitleBar(title: title),
          const SizedBox(height: 6),
          for (final o in options)
            ListTile(
              title: Text(o.label,
                  style: TextStyle(
                    color: AppColors.scorifyText,
                    fontWeight: o.value == selected ? FontWeight.w700 : FontWeight.w500,
                  )),
              trailing: o.value == selected ? const Icon(Icons.check_rounded, color: AppColors.scorifyMint) : null,
              onTap: () => Navigator.pop(sheet, (value: o.value)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Opciones a partir de las categorías del campeonato. Si dos comparten
/// nombre (p. ej. "Todo competidor" masculino y femenino), se agrega el
/// género para distinguirlas.
List<CategoryOption> categoryOptions(List<TournamentCategory> cats) {
  final count = <String, int>{};
  for (final c in cats) {
    count[c.categoryLabel] = (count[c.categoryLabel] ?? 0) + 1;
  }
  String gender(String g) => switch (g) {
        "male" => "Masc.",
        "female" => "Fem.",
        _ => "Mixto",
      };
  return [
    for (final c in cats)
      (id: c.idCategory, label: (count[c.categoryLabel] ?? 0) > 1 ? "${c.categoryLabel} · ${gender(c.gender)}" : c.categoryLabel),
  ];
}
