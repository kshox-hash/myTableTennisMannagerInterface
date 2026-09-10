import "package:myttmi/core/helpers/json_parse.dart";

class SetScore {
  final int p1;
  final int p2;

  SetScore({required this.p1, required this.p2});

  factory SetScore.fromJson(Map<String, dynamic> json) {
    return SetScore(p1: intOrDefault(json["p1"]), p2: intOrDefault(json["p2"]));
  }
}

List<SetScore>? setScoresFromJson(dynamic json) {
  if (json is! List) return null;
  return json.map((e) => SetScore.fromJson(e as Map<String, dynamic>)).toList();
}

class PlayerStanding {
  final String idUser;
  final String playerName;
  final String? clubName;
  final int played;
  final int won;
  final int lost;
  final int setsFor;
  final int setsAgainst;
  final int pointsFor;
  final int pointsAgainst;
  final int? position;
  final bool qualifiedToBracket;

  PlayerStanding({
    required this.idUser,
    required this.playerName,
    this.clubName,
    required this.played,
    required this.won,
    required this.lost,
    required this.setsFor,
    required this.setsAgainst,
    required this.pointsFor,
    required this.pointsAgainst,
    this.position,
    required this.qualifiedToBracket,
  });

  factory PlayerStanding.fromJson(Map<String, dynamic> json) {
    return PlayerStanding(
      idUser: (json["id_user"] ?? "").toString(),
      playerName: (json["player_name"] ?? "").toString(),
      clubName: json["club_name"] as String?,
      played: intOrDefault(json["played"]),
      won: intOrDefault(json["won"]),
      lost: intOrDefault(json["lost"]),
      setsFor: intOrDefault(json["sets_for"]),
      setsAgainst: intOrDefault(json["sets_against"]),
      pointsFor: intOrDefault(json["points_for"]),
      pointsAgainst: intOrDefault(json["points_against"]),
      position: intOrNull(json["position"]),
      qualifiedToBracket: json["qualified_to_bracket"] == true,
    );
  }
}

class PlayerMatch {
  final String idMatch;
  final int matchNumber;
  final int? round;
  final String status;
  final int bestOfSets;
  final int setsPlayer1;
  final int setsPlayer2;
  final String? winnerId;
  final List<SetScore>? setScores;
  final int? tableNumber;
  final int? playedTableNumber;
  final String? player1Id;
  final String? player2Id;
  final String? opponentName;
  final String? opponentClub;
  final String mySlot; // player1 | player2
  final String? refereeName;

  PlayerMatch({
    required this.idMatch,
    required this.matchNumber,
    this.round,
    required this.status,
    required this.bestOfSets,
    required this.setsPlayer1,
    required this.setsPlayer2,
    this.winnerId,
    this.setScores,
    this.tableNumber,
    this.playedTableNumber,
    this.player1Id,
    this.player2Id,
    this.opponentName,
    this.opponentClub,
    required this.mySlot,
    this.refereeName,
  });

  String? get opponentId => mySlot == "player1" ? player2Id : player1Id;

  factory PlayerMatch.fromJson(Map<String, dynamic> json) {
    return PlayerMatch(
      idMatch: (json["id_match"] ?? "").toString(),
      matchNumber: intOrDefault(json["match_number"]),
      round: intOrNull(json["round"]),
      status: (json["status"] ?? "scheduled").toString(),
      bestOfSets: intOrDefault(json["best_of_sets"], 5),
      setsPlayer1: intOrDefault(json["sets_player1"]),
      setsPlayer2: intOrDefault(json["sets_player2"]),
      winnerId: json["winner_id"] as String?,
      setScores: setScoresFromJson(json["set_scores"]),
      tableNumber: intOrNull(json["table_number"]),
      playedTableNumber: intOrNull(json["played_table_number"]),
      player1Id: json["player1_id"] as String?,
      player2Id: json["player2_id"] as String?,
      opponentName: json["opponent_name"] as String?,
      opponentClub: json["opponent_club"] as String?,
      mySlot: json["my_slot"] == "player2" ? "player2" : "player1",
      refereeName: json["referee_name"] as String?,
    );
  }
}

class PlayerCategoryView {
  final String phase;
  final String? myGroupId;
  final String? myGroupName;
  final List<PlayerStanding> standings;
  final List<PlayerMatch> myGroupMatches;
  final List<PlayerMatch> myBracketMatches;
  final int? bracketTotalRounds;

  PlayerCategoryView({
    required this.phase,
    this.myGroupId,
    this.myGroupName,
    required this.standings,
    required this.myGroupMatches,
    required this.myBracketMatches,
    this.bracketTotalRounds,
  });

  factory PlayerCategoryView.fromJson(Map<String, dynamic> json) {
    final myGroup = json["my_group"] as Map<String, dynamic>?;
    return PlayerCategoryView(
      phase: (json["phase"] ?? "enrollment").toString(),
      myGroupId: myGroup?["id_group"] as String?,
      myGroupName: myGroup?["group_name"] as String?,
      standings: (json["standings"] as List? ?? [])
          .map((e) => PlayerStanding.fromJson(e as Map<String, dynamic>))
          .toList(),
      myGroupMatches: (json["my_group_matches"] as List? ?? [])
          .map((e) => PlayerMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      myBracketMatches: (json["my_bracket_matches"] as List? ?? [])
          .map((e) => PlayerMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      bracketTotalRounds: intOrNull(json["bracket_total_rounds"]),
    );
  }
}

class CategoryParticipant {
  final String idUser;
  final String playerName;
  final String? clubName;
  final String? gender;
  final String enrolledAt;

  CategoryParticipant({
    required this.idUser,
    required this.playerName,
    this.clubName,
    this.gender,
    required this.enrolledAt,
  });

  factory CategoryParticipant.fromJson(Map<String, dynamic> json) {
    return CategoryParticipant(
      idUser: (json["id_user"] ?? "").toString(),
      playerName: (json["player_name"] ?? "").toString(),
      clubName: json["club_name"] as String?,
      gender: json["gender"] as String?,
      enrolledAt: (json["enrolled_at"] ?? "").toString(),
    );
  }
}

class CategoryStandingRow {
  final int position;
  final String idUser;
  final String playerName;
  final String? clubName;

  CategoryStandingRow({
    required this.position,
    required this.idUser,
    required this.playerName,
    this.clubName,
  });

  factory CategoryStandingRow.fromJson(Map<String, dynamic> json) {
    return CategoryStandingRow(
      position: intOrDefault(json["position"]),
      idUser: (json["id_user"] ?? "").toString(),
      playerName: (json["player_name"] ?? "").toString(),
      clubName: json["club_name"] as String?,
    );
  }
}

class CategoryStandings {
  final String source; // bracket | group | none
  final List<CategoryStandingRow> standings;

  CategoryStandings({required this.source, required this.standings});

  factory CategoryStandings.fromJson(Map<String, dynamic> json) {
    final s = json["source"];
    return CategoryStandings(
      source: (s == "group" || s == "bracket") ? s : "none",
      standings: (json["standings"] as List? ?? [])
          .map((e) => CategoryStandingRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TournamentParticipant extends CategoryParticipant {
  final String idCategory;
  final String categoryType;
  final String categoryRange;

  TournamentParticipant({
    required super.idUser,
    required super.playerName,
    super.clubName,
    super.gender,
    required super.enrolledAt,
    required this.idCategory,
    required this.categoryType,
    required this.categoryRange,
  });

  String get categoryLabel =>
      categoryRange.trim().isEmpty || categoryRange == "General"
      ? categoryType
      : "$categoryType $categoryRange";

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      idUser: (json["id_user"] ?? "").toString(),
      playerName: (json["player_name"] ?? "").toString(),
      clubName: json["club_name"] as String?,
      gender: json["gender"] as String?,
      enrolledAt: (json["enrolled_at"] ?? "").toString(),
      idCategory: (json["id_category"] ?? "").toString(),
      categoryType: (json["category_type"] ?? "").toString(),
      categoryRange: (json["category_range"] ?? "").toString(),
    );
  }
}
