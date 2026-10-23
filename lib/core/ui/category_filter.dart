import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";

/// Una categoría para [CategoryFilterBar]: id (o la etiqueta, donde no hay
/// id) y el texto del chip.
typedef CategoryOption = ({String id, String label});

/// Barra de categorías del campeonato (Partidos, Jugadores, Mesas): se ve
/// una categoría a la vez — mezclar las de todas en una lista no se
/// entendía. "Todas" al final, para quien quiera ver el torneo completo.
/// Con una sola categoría no se muestra.
class CategoryFilterBar extends StatelessWidget {
  final List<CategoryOption> options;
  /// null = "Todas".
  final String? selected;
  final ValueChanged<String?> onChanged;
  const CategoryFilterBar({super.key, required this.options, required this.selected, required this.onChanged});

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
    if (options.length < 2) return const SizedBox.shrink();
    Widget chip(String label, String? id) {
      final on = selected == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: on ? AppColors.scorifyMint : AppColors.scorifySurface2,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => onChanged(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.scorifyOnMint : AppColors.scorifyText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final o in options) chip(o.label, o.id),
          chip("Todas", null),
        ],
      ),
    );
  }
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
