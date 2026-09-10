import "package:myttmi/core/helpers/json_parse.dart";

/// Podio (1°, 2° o 3° lugar) de un jugador en una categoría ya finalizada.
class PlayerAchievement {
  final String idTournament;
  final String tournamentName;
  final String? eventDate;
  final String idCategory;
  final String categoryType;
  final String categoryRange;
  final int position;

  PlayerAchievement({
    required this.idTournament,
    required this.tournamentName,
    this.eventDate,
    required this.idCategory,
    required this.categoryType,
    required this.categoryRange,
    required this.position,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  String get medal {
    switch (position) {
      case 1:
        return "🥇";
      case 2:
        return "🥈";
      default:
        return "🥉";
    }
  }

  String get positionLabel {
    switch (position) {
      case 1:
        return "Campeón";
      case 2:
        return "2do lugar";
      default:
        return "3er lugar";
    }
  }

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) {
    return PlayerAchievement(
      idTournament: (json["id_tournament"] ?? "").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      eventDate: json["event_date"] as String?,
      idCategory: (json["id_category"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      position: intOrDefault(json["position"]),
    );
  }
}
