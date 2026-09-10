import "package:myttmi/core/helpers/json_parse.dart";

// Un partido de la cola/mesas — misma forma tanto si está en juego (mesa
// activa) como si está esperando turno en la cola de despacho.
class QueueMatch {
  final String idMatch;
  final String categoryType;
  final String categoryRange;
  final String? groupName;
  final int? round;
  final int matchNumber;
  final String? player1Name;
  final String? player2Name;

  QueueMatch({
    required this.idMatch,
    required this.categoryType,
    required this.categoryRange,
    this.groupName,
    this.round,
    required this.matchNumber,
    this.player1Name,
    this.player2Name,
  });

  String get categoryLabel => "$categoryType $categoryRange";

  String get matchLabel {
    if (groupName != null && groupName!.isNotEmpty) {
      return "$groupName · Partido $matchNumber";
    }
    if (round != null) return "Ronda $round · Partido $matchNumber";
    return "Partido $matchNumber";
  }

  factory QueueMatch.fromJson(Map<String, dynamic> json) {
    return QueueMatch(
      idMatch: (json["id_match"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      groupName: json["group_name"] as String?,
      round: json["round"] != null ? intOrDefault(json["round"]) : null,
      matchNumber: intOrDefault(json["match_number"]),
      player1Name: json["player1_name"] as String?,
      player2Name: json["player2_name"] as String?,
    );
  }
}

class TableSlot {
  final int tableNumber;
  final QueueMatch? match;

  TableSlot({required this.tableNumber, this.match});

  factory TableSlot.fromJson(Map<String, dynamic> json) {
    return TableSlot(
      tableNumber: intOrDefault(json["table_number"]),
      match: json["match"] != null
          ? QueueMatch.fromJson(json["match"] as Map<String, dynamic>)
          : null,
    );
  }
}

class TablesQueueBoard {
  final int numTables;
  final List<TableSlot> tables;
  final List<QueueMatch> nextMatches;

  TablesQueueBoard({
    required this.numTables,
    required this.tables,
    required this.nextMatches,
  });

  factory TablesQueueBoard.fromJson(Map<String, dynamic> json) {
    return TablesQueueBoard(
      numTables: intOrDefault(json["num_tables"]),
      tables: (json["tables"] as List? ?? [])
          .map((e) => TableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextMatches: (json["next_matches"] as List? ?? [])
          .map((e) => QueueMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
