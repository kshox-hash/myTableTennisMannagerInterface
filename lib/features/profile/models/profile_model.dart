import "package:myttmi/core/helpers/json_parse.dart";
class UserProfile {
  final String idUser;
  final String email;
  final String role; // "admin" | "player"
  final DateTime? createdAt;
  final String? firstName;
  final String? lastName;
  final String? gender; // "male" | "female" | "other"
  final String? club;
  final DateTime? birthDate;
  final String? country;
  final String? idDocument;
  final String? category;

  UserProfile({
    required this.idUser,
    required this.email,
    required this.role,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.gender,
    this.club,
    this.birthDate,
    this.country,
    this.idDocument,
    this.category,
  });

  String get displayName {
    final joined = [firstName, lastName].where((s) => (s ?? "").trim().isNotEmpty).join(" ");
    return joined.isNotEmpty ? joined : email;
  }

  int? get age {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) years--;
    return years;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return UserProfile(
      idUser: (json["id_user"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      role: (json["role"] ?? "player").toString().toLowerCase(),
      createdAt: parseDate(json["created_at"]),
      firstName: json["first_name"] as String?,
      lastName: json["last_name"] as String?,
      gender: json["gender"] as String?,
      club: json["club_name"] as String?,
      birthDate: parseDate(json["birth_date"]),
      country: json["country"] as String?,
      idDocument: json["id_document"] as String?,
      category: json["category"] as String?,
    );
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

  double get winRate => matchesPlayed == 0 ? 0 : matchesWon / matchesPlayed;

  factory PlayerStats.fromJson(Map<String, dynamic>? json) {
    return PlayerStats(
      matchesPlayed: intOrDefault(json?["matches_played"]),
      matchesWon: intOrDefault(json?["matches_won"]),
      matchesLost: intOrDefault(json?["matches_lost"]),
      setsWon: intOrDefault(json?["sets_won"]),
      setsLost: intOrDefault(json?["sets_lost"]),
    );
  }
}

class PublicPlayerProfile {
  final String idUser;
  final String displayName;
  final String? club;
  final String? gender;
  final PlayerStats stats;

  PublicPlayerProfile({
    required this.idUser,
    required this.displayName,
    this.club,
    this.gender,
    required this.stats,
  });

  factory PublicPlayerProfile.fromJson(Map<String, dynamic> json) {
    final first = (json["first_name"] as String?)?.trim();
    final last = (json["last_name"] as String?)?.trim();
    final joined = [first, last].where((s) => s != null && s.isNotEmpty).join(" ");

    return PublicPlayerProfile(
      idUser: (json["id_user"] ?? "").toString(),
      displayName: joined.isNotEmpty ? joined : "Jugador",
      club: json["club_name"] as String?,
      gender: json["gender"] as String?,
      stats: PlayerStats.fromJson(json["stats"] as Map<String, dynamic>?),
    );
  }
}
