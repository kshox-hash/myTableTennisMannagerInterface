import "package:flutter/widgets.dart";

/// "En vivo" del Inicio: las novedades de una categoría que estoy jugando
/// (GET /player/me/live-summary), por ronda de la llave y por grupo.
class LivePerson {
  final String idUser;
  final String name;
  final bool isMe;
  // Puesto en el grupo (solo en "pasan" de un grupo terminado).
  final int? position;

  const LivePerson({required this.idUser, required this.name, required this.isMe, this.position});

  factory LivePerson.fromJson(Map<String, dynamic> j) => LivePerson(
        idUser: (j["id_user"] ?? "").toString(),
        name: (j["name"] ?? "").toString(),
        isMe: j["is_me"] == true,
        position: (j["position"] as num?)?.toInt(),
      );

  /// "Juan Pérez" → "Juan P." (para las listas cortas).
  String get short {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length < 2) return name;
    return "${parts.first} ${parts[1].characters.first}.";
  }
}

/// Una ronda de la llave o un grupo.
class LiveBlock {
  final bool isRound;
  final String label; // "Cuartos de final" / "Grupo 3"
  final int played;
  final int total;
  final bool finished;
  final List<LivePerson> passed;
  final List<LivePerson> out;
  // Grupo en juego: los que pasarían si terminara ahora (cambia con cada
  // resultado).
  final List<LivePerson> passing;
  final List<LivePerson> playing; // ronda en juego: los que faltan (de a pares)
  // Último partido terminado: "Juan P. 2-0 Ana R." (ganador primero).
  final ({LivePerson winner, LivePerson loser, int setsWinner, int setsLoser})? lastResult;

  const LiveBlock({
    required this.isRound,
    required this.label,
    required this.played,
    required this.total,
    required this.finished,
    required this.passed,
    required this.out,
    required this.passing,
    required this.playing,
    required this.lastResult,
  });

  factory LiveBlock.fromJson(Map<String, dynamic> j) {
    List<LivePerson> people(String key) => ((j[key] as List?) ?? const []).cast<Map<String, dynamic>>().map(LivePerson.fromJson).toList();
    final last = j["last_result"] as Map<String, dynamic>?;
    return LiveBlock(
      isRound: j["kind"] == "round",
      label: (j["label"] ?? "").toString(),
      played: (j["played"] as num?)?.toInt() ?? 0,
      total: (j["total"] as num?)?.toInt() ?? 0,
      finished: j["finished"] == true,
      passed: people("passed"),
      out: people("out"),
      passing: people("passing"),
      playing: people("playing"),
      lastResult: last == null
          ? null
          : (
              winner: LivePerson.fromJson(last["winner"] as Map<String, dynamic>),
              loser: LivePerson.fromJson(last["loser"] as Map<String, dynamic>),
              setsWinner: (last["sets_winner"] as num?)?.toInt() ?? 0,
              setsLoser: (last["sets_loser"] as num?)?.toInt() ?? 0,
            ),
    );
  }
}

class LiveSummary {
  final String idTournament;
  final String tournamentName;
  final String idCategory;
  final String categoryLabel;
  final bool inBracket;
  final List<LiveBlock> blocks;

  const LiveSummary({
    required this.idTournament,
    required this.tournamentName,
    required this.idCategory,
    required this.categoryLabel,
    required this.inBracket,
    required this.blocks,
  });

  factory LiveSummary.fromJson(Map<String, dynamic> j) => LiveSummary(
        idTournament: (j["id_tournament"] ?? "").toString(),
        tournamentName: (j["tournament_name"] ?? "").toString(),
        idCategory: (j["id_category"] ?? "").toString(),
        categoryLabel: (j["category_label"] ?? "").toString(),
        inBracket: j["phase"] == "bracket",
        blocks: ((j["blocks"] as List?) ?? const []).cast<Map<String, dynamic>>().map(LiveBlock.fromJson).toList(),
      );
}
