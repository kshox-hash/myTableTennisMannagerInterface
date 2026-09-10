import "package:myttmi/core/helpers/json_parse.dart";
class TournamentCategory {
  final String idCategory;
  final String categoryType;
  final String categoryRange;
  final String gender;
  final int inscriptionPrice;
  final int? quotas; // null = cupos ilimitados
  final String status;
  final String phase; // enrollment | groups | bracket | finished
  final int qualifiersPerGroup;
  final int enrolledCount;
  final bool isEnrolled;

  TournamentCategory({
    required this.idCategory,
    required this.categoryType,
    required this.categoryRange,
    required this.gender,
    required this.inscriptionPrice,
    this.quotas,
    this.status = "active",
    this.phase = "enrollment",
    this.qualifiersPerGroup = 2,
    this.enrolledCount = 0,
    this.isEnrolled = false,
  });

  /// Label combinado para mostrar en UI — el backend nunca manda un
  /// "category_name" único, siempre separa tipo + rango.
  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
          ? categoryType
          : "$categoryType $categoryRange";

  factory TournamentCategory.fromJson(Map<String, dynamic> json) {
    return TournamentCategory(
      idCategory: (json["id_category"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      gender: (json["gender"] ?? "mixed").toString(),
      inscriptionPrice: intOrDefault(json["inscription_price"]),
      quotas: intOrNull(json["quotas"]),
      status: (json["status"] ?? "active").toString(),
      phase: (json["phase"] ?? "enrollment").toString(),
      qualifiersPerGroup: intOrDefault(json["qualifiers_per_group"], 2),
      enrolledCount: intOrDefault(json["enrolled_count"]),
      isEnrolled: json["is_enrolled"] == true,
    );
  }

  TournamentCategory copyWith({bool? isEnrolled}) {
    return TournamentCategory(
      idCategory: idCategory,
      categoryType: categoryType,
      categoryRange: categoryRange,
      gender: gender,
      inscriptionPrice: inscriptionPrice,
      quotas: quotas,
      status: status,
      phase: phase,
      qualifiersPerGroup: qualifiersPerGroup,
      enrolledCount: enrolledCount,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}

class Tournament {
  final String idTournament;
  final String tournamentName;
  final String? description;
  final String? address;
  final String? region;
  final String? eventDate; // YYYY-MM-DD
  final String? eventTime; // HH:mm
  final String createdBy;
  final String status; // active | cancelled
  final List<TournamentCategory> categories;

  Tournament({
    required this.idTournament,
    required this.tournamentName,
    this.description,
    this.address,
    this.region,
    this.eventDate,
    this.eventTime,
    required this.createdBy,
    this.status = "active",
    required this.categories,
  });

  bool get isCancelled => status == "cancelled";

  factory Tournament.fromJson(Map<String, dynamic> json) {
    final cats = (json["categories"] as List? ?? [])
        .map((e) => TournamentCategory.fromJson(e as Map<String, dynamic>))
        .toList();

    return Tournament(
      idTournament: (json["id_tournament"] ?? "").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      description: json["description"] as String?,
      address: json["address"] as String?,
      region: json["region"] as String?,
      eventDate: json["event_date"] as String?,
      eventTime: json["event_time"] as String?,
      createdBy: (json["created_by"] ?? "").toString(),
      status: (json["status"] ?? "active").toString(),
      categories: cats,
    );
  }
}
