import "package:myttmi/core/helpers/json_parse.dart";

class RankingEntry {
  final String idUser;
  final String name;
  final String? clubName;
  final int rankingPoints;
  final int rankingPosition;
  final int matchesPlayed;
  final int matchesWon;

  RankingEntry({
    required this.idUser,
    required this.name,
    this.clubName,
    required this.rankingPoints,
    required this.rankingPosition,
    required this.matchesPlayed,
    required this.matchesWon,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    final first = (json["first_name"] as String?)?.trim();
    final last = (json["last_name"] as String?)?.trim();
    final joined = [first, last].where((s) => s != null && s.isNotEmpty).join(" ");
    final name = joined.isNotEmpty ? joined : (json["email"] ?? "Jugador").toString();

    return RankingEntry(
      idUser: (json["id_user"] ?? "").toString(),
      name: name,
      clubName: json["club_name"] as String?,
      rankingPoints: intOrDefault(json["ranking_points"]),
      rankingPosition: intOrDefault(json["ranking_position"]),
      matchesPlayed: intOrDefault(json["matches_played"]),
      matchesWon: intOrDefault(json["matches_won"]),
    );
  }
}
