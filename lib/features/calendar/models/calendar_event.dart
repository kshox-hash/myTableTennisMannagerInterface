class CalendarEvent {
  final DateTime date; // solo fecha
  final String tournamentId;
  final String tournamentName;
  final String? location;

  final String categoryId;
  final String categoryName;
  final String gender;
  // Fase de la categoría: enrollment | groups | bracket | finished.
  final String phase;

  /// Ya empezó (grupos o llave), aunque la fecha agendada sea después.
  bool get finished => phase == "finished";

  bool get inProgress => phase == "groups" || phase == "bracket";

  CalendarEvent({
    required this.date,
    required this.tournamentId,
    required this.tournamentName,
    required this.location,
    required this.categoryId,
    required this.categoryName,
    required this.gender,
    this.phase = "enrollment",
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json["date"].toString()); // YYYY-MM-DD
    return CalendarEvent(
      date: DateTime(date.year, date.month, date.day),
      tournamentId: json["tournament_id"].toString(),
      tournamentName: json["tournament_name"].toString(),
      // El backend manda "address" y tipo/rango por separado; se aceptan
      // también los nombres anteriores.
      location: (json["address"] ?? json["location"])?.toString(),
      categoryId: json["category_id"].toString(),
      categoryName: json["category_name"]?.toString() ?? _categoryLabel(json),
      gender: json["gender"].toString(),
      phase: (json["phase"] ?? "enrollment").toString(),
    );
  }
}

String _categoryLabel(Map<String, dynamic> json) {
  final type = (json["category_type"] ?? "").toString();
  final range = (json["category_range"] ?? "").toString().trim();
  return range.isEmpty || range == "General" ? type : "$type $range";
}
