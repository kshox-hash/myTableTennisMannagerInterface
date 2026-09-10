import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/helpers/json_parse.dart";

class PlayerNextMatch {
  final String idMatch;
  final String matchType; // group | bracket
  final String idCategory;
  final String idTournament;
  final String tournamentName;
  final String categoryDisplay;
  final String? opponentId;
  final String? opponentName;
  final int? tableNumber;
  final String status;
  final String? groupName;
  final int? round;
  // Cola de mesa: cuando todavía no hay mesa asignada, esto le dice al
  // jugador si le toca esperar por su rival (queueBlocked) o cuántos
  // partidos le faltan para que le toque (queuePosition/queueTotal) — mismo
  // dato que ya usa la versión web, no estaba conectado acá.
  final int? queuePosition;
  final int? queueTotal;
  final bool queueBlocked;
  final bool selfPending;
  final int? blockingTableNumber;

  PlayerNextMatch({
    required this.idMatch,
    required this.matchType,
    required this.idCategory,
    required this.idTournament,
    required this.tournamentName,
    required this.categoryDisplay,
    this.opponentId,
    this.opponentName,
    this.tableNumber,
    required this.status,
    this.groupName,
    this.round,
    this.queuePosition,
    this.queueTotal,
    this.queueBlocked = false,
    this.selfPending = false,
    this.blockingTableNumber,
  });

  factory PlayerNextMatch.fromJson(Map<String, dynamic> json) {
    return PlayerNextMatch(
      idMatch: (json["id_match"] ?? "").toString(),
      matchType: (json["match_type"] ?? "group").toString(),
      idCategory: (json["id_category"] ?? "").toString(),
      idTournament: (json["id_tournament"] ?? "").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      categoryDisplay: (json["category_display"] ?? "").toString(),
      opponentId: json["opponent_id"] as String?,
      opponentName: json["opponent_name"] as String?,
      tableNumber: intOrNull(json["table_number"]),
      status: (json["status"] ?? "").toString(),
      groupName: json["group_name"] as String?,
      round: intOrNull(json["round"]),
      queuePosition: intOrNull(json["queue_position"]),
      queueTotal: intOrNull(json["queue_total"]),
      queueBlocked: json["queue_blocked"] == true,
      selfPending: json["self_pending"] == true,
      blockingTableNumber: intOrNull(json["blocking_table_number"]),
    );
  }

  /// Mismo texto de "cómo vas con la mesa" que ya usa la versión web —
  /// mesa asignada, esperando al rival, posición en la cola, o el estado
  /// crudo del partido si no aplica ninguno de esos casos.
  String get queueLabel {
    if (tableNumber != null) return "🏓 Mesa $tableNumber";
    if (queueBlocked) {
      return blockingTableNumber != null
          ? "Tu rival está jugando en la mesa $blockingTableNumber — te toca cuando termine"
          : "Esperando que tu rival termine su partido actual";
    }
    if (queuePosition != null) {
      return queuePosition == 1
          ? "Sos el siguiente en la cola"
          : "Vas $queuePosition° en la cola de $queueTotal";
    }
    if (selfPending) {
      return "Debes completar tu otro partido pendiente antes de que te toque este";
    }
    return matchStatusLabel[status] ?? "Mesa sin asignar";
  }
}

class PlayerStats {
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int setsWon;
  final int setsLost;

  PlayerStats({
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.setsWon,
    required this.setsLost,
  });

  factory PlayerStats.fromJson(Map<String, dynamic>? json) {
    return PlayerStats(
      matchesPlayed: intOrDefault(json?["matches_played"]),
      matchesWon: intOrDefault(json?["matches_won"]),
      matchesLost: intOrDefault(json?["matches_lost"]),
      setsWon: intOrDefault(json?["sets_won"]),
      setsLost: intOrDefault(json?["sets_lost"]),
    );
  }

  double get winRate => matchesPlayed == 0 ? 0 : matchesWon / matchesPlayed;
}

class PlayerDashboard {
  final PlayerNextMatch? nextMatch;
  final List<PlayerNextMatch> otherNextMatches;
  final int activeEnrollments;
  final PlayerStats stats;

  PlayerDashboard({
    this.nextMatch,
    required this.otherNextMatches,
    required this.activeEnrollments,
    required this.stats,
  });

  factory PlayerDashboard.fromJson(Map<String, dynamic> json) {
    return PlayerDashboard(
      nextMatch: json["next_match"] != null
          ? PlayerNextMatch.fromJson(json["next_match"])
          : null,
      otherNextMatches: (json["other_next_matches"] as List? ?? [])
          .map((e) => PlayerNextMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeEnrollments: intOrDefault(json["active_enrollments"]),
      stats: PlayerStats.fromJson(json["stats"] as Map<String, dynamic>?),
    );
  }
}

class PlayerEnrollment {
  final String idTournament;
  final String tournamentName;
  final String? eventDate;
  final String? address;
  final String? region;
  final String idCategory;
  final String categoryType;
  final String categoryRange;
  final String gender;
  final String phase;

  PlayerEnrollment({
    required this.idTournament,
    required this.tournamentName,
    this.eventDate,
    this.address,
    this.region,
    required this.idCategory,
    required this.categoryType,
    required this.categoryRange,
    required this.gender,
    required this.phase,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  factory PlayerEnrollment.fromJson(Map<String, dynamic> json) {
    return PlayerEnrollment(
      idTournament: (json["id_tournament"] ?? "").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      eventDate: json["event_date"] as String?,
      address: json["address"] as String?,
      region: json["region"] as String?,
      idCategory: (json["id_category"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      gender: (json["gender"] ?? "mixed").toString(),
      phase: (json["phase"] ?? "enrollment").toString(),
    );
  }
}
