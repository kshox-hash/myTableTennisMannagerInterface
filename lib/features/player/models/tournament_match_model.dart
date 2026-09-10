import "package:myttmi/core/helpers/json_parse.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";

class TournamentMatch {
  final String idMatch;
  final String matchType; // group | bracket
  final String idCategory;
  final String categoryType;
  final String categoryRange;
  final String? groupName;
  final int? round;
  final int? totalRounds;
  final int matchNumber;
  final String player1Id;
  final String player1Name;
  final String? player1Club;
  final String player2Id;
  final String player2Name;
  final String? player2Club;
  final String status;
  final int setsPlayer1;
  final int setsPlayer2;
  final String? winnerId;
  final String? playedAt;
  final int? tableNumber;
  final int? playedTableNumber;
  final int? nextRound;
  final int? nextMatchNumber;
  final int? nextMatchSlot;

  TournamentMatch({
    required this.idMatch,
    required this.matchType,
    required this.idCategory,
    required this.categoryType,
    required this.categoryRange,
    this.groupName,
    this.round,
    this.totalRounds,
    required this.matchNumber,
    required this.player1Id,
    required this.player1Name,
    this.player1Club,
    required this.player2Id,
    required this.player2Name,
    this.player2Club,
    required this.status,
    required this.setsPlayer1,
    required this.setsPlayer2,
    this.winnerId,
    this.playedAt,
    this.tableNumber,
    this.playedTableNumber,
    this.nextRound,
    this.nextMatchNumber,
    this.nextMatchSlot,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      idMatch: (json["id_match"] ?? "").toString(),
      matchType: (json["match_type"] ?? "group").toString(),
      idCategory: (json["id_category"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      groupName: json["group_name"] as String?,
      round: intOrNull(json["round"]),
      totalRounds: intOrNull(json["total_rounds"]),
      matchNumber: intOrDefault(json["match_number"]),
      player1Id: (json["player1_id"] ?? "").toString(),
      player1Name: (json["player1_name"] ?? "").toString(),
      player1Club: json["player1_club"] as String?,
      player2Id: (json["player2_id"] ?? "").toString(),
      player2Name: (json["player2_name"] ?? "").toString(),
      player2Club: json["player2_club"] as String?,
      status: (json["status"] ?? "scheduled").toString(),
      setsPlayer1: intOrDefault(json["sets_player1"]),
      setsPlayer2: intOrDefault(json["sets_player2"]),
      winnerId: json["winner_id"] as String?,
      playedAt: json["played_at"] as String?,
      tableNumber: intOrNull(json["table_number"]),
      playedTableNumber: intOrNull(json["played_table_number"]),
      nextRound: intOrNull(json["next_round"]),
      nextMatchNumber: intOrNull(json["next_match_number"]),
      nextMatchSlot: intOrNull(json["next_match_slot"]),
    );
  }
}

class MatchDetail {
  final String idMatch;
  final String matchType;
  final String tournamentName;
  final String categoryType;
  final String categoryRange;
  final String? groupName;
  final int? round;
  final int? totalRounds;
  final int matchNumber;
  final int bestOfSets;
  final String? player1Id;
  final String player1Name;
  final String? player1Club;
  final String? player2Id;
  final String player2Name;
  final String? player2Club;
  final String? winnerId;
  final int setsPlayer1;
  final int setsPlayer2;
  final List<SetScore>? setScores;
  final String status;
  final String? playedAt;
  final int? tableNumber;
  final int? playedTableNumber;
  final String? refereeName;
  final int? player1Seed;
  final int? player2Seed;

  MatchDetail({
    required this.idMatch,
    required this.matchType,
    required this.tournamentName,
    required this.categoryType,
    required this.categoryRange,
    this.groupName,
    this.round,
    this.totalRounds,
    required this.matchNumber,
    required this.bestOfSets,
    this.player1Id,
    required this.player1Name,
    this.player1Club,
    this.player2Id,
    required this.player2Name,
    this.player2Club,
    this.winnerId,
    required this.setsPlayer1,
    required this.setsPlayer2,
    this.setScores,
    required this.status,
    this.playedAt,
    this.tableNumber,
    this.playedTableNumber,
    this.refereeName,
    this.player1Seed,
    this.player2Seed,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    return MatchDetail(
      idMatch: (json["id_match"] ?? "").toString(),
      matchType: (json["match_type"] ?? "group").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      groupName: json["group_name"] as String?,
      round: intOrNull(json["round"]),
      totalRounds: intOrNull(json["total_rounds"]),
      matchNumber: intOrDefault(json["match_number"]),
      bestOfSets: intOrDefault(json["best_of_sets"], 5),
      player1Id: json["player1_id"] as String?,
      player1Name: (json["player1_name"] ?? "Vacante").toString(),
      player1Club: json["player1_club"] as String?,
      player2Id: json["player2_id"] as String?,
      player2Name: (json["player2_name"] ?? "Vacante").toString(),
      player2Club: json["player2_club"] as String?,
      winnerId: json["winner_id"] as String?,
      setsPlayer1: intOrDefault(json["sets_player1"]),
      setsPlayer2: intOrDefault(json["sets_player2"]),
      setScores: setScoresFromJson(json["set_scores"]),
      status: (json["status"] ?? "").toString(),
      playedAt: json["played_at"] as String?,
      tableNumber: intOrNull(json["table_number"]),
      playedTableNumber: intOrNull(json["played_table_number"]),
      refereeName: json["referee_name"] as String?,
      player1Seed: intOrNull(json["seed1"]),
      player2Seed: intOrNull(json["seed2"]),
    );
  }
}

class PlayerMatchHistoryItem {
  final String idMatch;
  final String matchType;
  final String tournamentName;
  final String categoryType;
  final String categoryRange;
  final String? groupName;
  final int? round;
  final int? totalRounds;
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;
  final String? opponentClub;
  final String status;
  final int setsPlayer1;
  final int setsPlayer2;
  final String? winnerId;
  final String? playedAt;

  PlayerMatchHistoryItem({
    required this.idMatch,
    required this.matchType,
    required this.tournamentName,
    required this.categoryType,
    required this.categoryRange,
    this.groupName,
    this.round,
    this.totalRounds,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    this.opponentClub,
    required this.status,
    required this.setsPlayer1,
    required this.setsPlayer2,
    this.winnerId,
    this.playedAt,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  factory PlayerMatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return PlayerMatchHistoryItem(
      idMatch: (json["id_match"] ?? "").toString(),
      matchType: (json["match_type"] ?? "group").toString(),
      tournamentName: (json["tournament_name"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
      groupName: json["group_name"] as String?,
      round: intOrNull(json["round"]),
      totalRounds: intOrNull(json["total_rounds"]),
      player1Id: (json["player1_id"] ?? "").toString(),
      player1Name: (json["player1_name"] ?? "").toString(),
      player2Id: (json["player2_id"] ?? "").toString(),
      player2Name: (json["player2_name"] ?? "").toString(),
      opponentClub: json["opponent_club"] as String?,
      status: (json["status"] ?? "").toString(),
      setsPlayer1: intOrDefault(json["sets_player1"]),
      setsPlayer2: intOrDefault(json["sets_player2"]),
      winnerId: json["winner_id"] as String?,
      playedAt: json["played_at"] as String?,
    );
  }
}
