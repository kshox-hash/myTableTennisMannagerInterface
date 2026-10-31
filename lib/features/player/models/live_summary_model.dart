import "package:flutter/widgets.dart";

/// "En vivo" del Inicio (GET /player/me/live-summary): en una categoría que
/// estoy jugando, quiénes van clasificados y quiénes quedaron eliminados.
class LivePerson {
  final String idUser;
  final String name;
  final bool isMe;
  // Eliminados: dónde quedaron ("Grupo 3", "Cuartos de final").
  final String? stage;

  const LivePerson({required this.idUser, required this.name, required this.isMe, this.stage});

  factory LivePerson.fromJson(Map<String, dynamic> j) => LivePerson(
        idUser: (j["id_user"] ?? "").toString(),
        name: (j["name"] ?? "").toString(),
        isMe: j["is_me"] == true,
        stage: j["stage"] as String?,
      );

  /// "Juan Pérez" → "Juan P."; yo, "Tú".
  String get short {
    if (isMe) return "Tú";
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length < 2) return name;
    return "${parts.first} ${parts[1].characters.first}.";
  }
}

class LiveSummary {
  final String idTournament;
  final String tournamentName;
  final String idCategory;
  final String categoryLabel;
  final bool inBracket;
  // Llave: la ronda que se está jugando ("Cuartos de final").
  final String? currentRound;
  final List<LivePerson> classified;
  final List<LivePerson> eliminated;
  // Formato Oro y Plata: el 3° de cada grupo sigue jugando en Plata, no es
  // un eliminado.
  final List<LivePerson> movedToSilver;

  const LiveSummary({
    required this.idTournament,
    required this.tournamentName,
    required this.idCategory,
    required this.categoryLabel,
    required this.inBracket,
    required this.currentRound,
    required this.classified,
    required this.eliminated,
    this.movedToSilver = const [],
  });

  factory LiveSummary.fromJson(Map<String, dynamic> j) {
    List<LivePerson> people(String key) => ((j[key] as List?) ?? const []).cast<Map<String, dynamic>>().map(LivePerson.fromJson).toList();
    const silverStage = "Pasó a Plata";
    final out = people("eliminated");
    return LiveSummary(
      idTournament: (j["id_tournament"] ?? "").toString(),
      tournamentName: (j["tournament_name"] ?? "").toString(),
      idCategory: (j["id_category"] ?? "").toString(),
      categoryLabel: (j["category_label"] ?? "").toString(),
      inBracket: j["phase"] == "bracket",
      currentRound: j["current_round"] as String?,
      classified: people("classified"),
      eliminated: out.where((p) => p.stage != silverStage).toList(),
      movedToSilver: out.where((p) => p.stage == silverStage).toList(),
    );
  }

  /// Título de la lista de los que siguen: en grupos, "Clasificados a la
  /// llave"; en la llave, "Siguen en carrera".
  String get aliveTitle => inBracket ? "Siguen en carrera" : "Clasificados a la llave";
}
