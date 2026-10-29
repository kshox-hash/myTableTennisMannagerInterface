import "package:myttmi/core/ui/avatar_cache.dart";
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
    AvatarCache.rememberRow(json);
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

/// Un ranking que el jugador puede elegir aparte del general: el de un
/// organizador (solo sus campeonatos puntuables).
class RankingScope {
  final String organizerId;
  final String name;
  final int tournaments;
  RankingScope({required this.organizerId, required this.name, required this.tournaments});

  factory RankingScope.fromJson(Map<String, dynamic> json) => RankingScope(
        organizerId: (json["id_organizer"] ?? "").toString(),
        name: (json["name"] ?? "Organizador").toString(),
        tournaments: intOrDefault(json["tournaments"]),
      );
}

/// Campeonato que forma parte de un ranking.
class RankingTournament {
  final String id;
  final String name;
  final String? eventDate;
  final String level;
  RankingTournament({required this.id, required this.name, this.eventDate, required this.level});

  factory RankingTournament.fromJson(Map<String, dynamic> json) => RankingTournament(
        id: (json["id_tournament"] ?? "").toString(),
        name: (json["tournament_name"] ?? "Campeonato").toString(),
        eventDate: json["event_date"] as String?,
        level: (json["ranking_level"] ?? "local").toString(),
      );
}

/// Lo que sacó un jugador en un campeonato: ronda alcanzada y puntos.
class RankingResult {
  final String tournamentName;
  final String? eventDate;
  final String level;
  final String category;
  final int points;
  final String round;
  RankingResult({
    required this.tournamentName,
    this.eventDate,
    required this.level,
    required this.category,
    required this.points,
    required this.round,
  });

  factory RankingResult.fromJson(Map<String, dynamic> json) => RankingResult(
        tournamentName: (json["tournament_name"] ?? "Campeonato").toString(),
        eventDate: json["event_date"] as String?,
        level: (json["ranking_level"] ?? "local").toString(),
        category: (json["category"] ?? "").toString(),
        points: intOrDefault(json["points"]),
        round: (json["round"] ?? "").toString(),
      );
}
