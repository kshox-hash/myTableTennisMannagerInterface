import "package:myttmi/core/helpers/json_parse.dart";

/// Vista de TODOS los grupos de una categoría (no solo "el mío") — usa el
/// mismo endpoint que el panel admin, que ya es accesible para cualquier
/// jugador logueado.
class GroupMemberInfo {
  final String idUser;
  final String? firstName;
  final String? lastName;
  final String? clubName;
  final String email;

  GroupMemberInfo({
    required this.idUser,
    this.firstName,
    this.lastName,
    this.clubName,
    required this.email,
  });

  String get displayName {
    final joined = [
      firstName,
      lastName,
    ].where((s) => (s ?? "").trim().isNotEmpty).join(" ");
    return joined.isNotEmpty ? joined : email;
  }

  factory GroupMemberInfo.fromJson(Map<String, dynamic> json) {
    return GroupMemberInfo(
      idUser: (json["id_user"] ?? "").toString(),
      firstName: json["first_name"] as String?,
      lastName: json["last_name"] as String?,
      clubName: json["club_name"] as String?,
      email: (json["email"] ?? "").toString(),
    );
  }
}

class GroupStandingInfo {
  final String idUser;
  final int played;
  final int won;
  final int lost;
  final int setsFor;
  final int setsAgainst;
  final int? position;
  final bool qualifiedToBracket;

  GroupStandingInfo({
    required this.idUser,
    required this.played,
    required this.won,
    required this.lost,
    required this.setsFor,
    required this.setsAgainst,
    this.position,
    required this.qualifiedToBracket,
  });

  factory GroupStandingInfo.fromJson(Map<String, dynamic> json) {
    return GroupStandingInfo(
      idUser: (json["id_user"] ?? "").toString(),
      played: intOrDefault(json["played"]),
      won: intOrDefault(json["won"]),
      lost: intOrDefault(json["lost"]),
      setsFor: intOrDefault(json["sets_for"]),
      setsAgainst: intOrDefault(json["sets_against"]),
      position: intOrNull(json["position"]),
      qualifiedToBracket: json["qualified_to_bracket"] == true,
    );
  }
}

class GroupMatchInfo {
  final String idMatch;
  final int? round;
  final int matchNumber;
  final String? player1Id;
  final String? player2Id;
  final String? winnerId;
  final int setsPlayer1;
  final int setsPlayer2;
  final String status;
  final int? tableNumber;

  GroupMatchInfo({
    required this.idMatch,
    this.round,
    required this.matchNumber,
    this.player1Id,
    this.player2Id,
    this.winnerId,
    required this.setsPlayer1,
    required this.setsPlayer2,
    required this.status,
    this.tableNumber,
  });

  factory GroupMatchInfo.fromJson(Map<String, dynamic> json) {
    return GroupMatchInfo(
      idMatch: (json["id_match"] ?? "").toString(),
      round: intOrNull(json["round_number"]),
      matchNumber: intOrDefault(json["match_number"]),
      player1Id: json["player1_id"] as String?,
      player2Id: json["player2_id"] as String?,
      winnerId: json["winner_id"] as String?,
      setsPlayer1: intOrDefault(json["sets_player1"]),
      setsPlayer2: intOrDefault(json["sets_player2"]),
      status: (json["status"] ?? "scheduled").toString(),
      tableNumber: intOrNull(json["table_number"]),
    );
  }
}

class GroupFullView {
  final String idGroup;
  final String groupName;
  final List<GroupMemberInfo> members;
  final List<GroupStandingInfo> standings;
  final List<GroupMatchInfo> matches;

  GroupFullView({
    required this.idGroup,
    required this.groupName,
    required this.members,
    required this.standings,
    required this.matches,
  });

  String nameFor(String? userId) {
    if (userId == null) return "Vacante";
    final m = members.where((m) => m.idUser == userId);
    return m.isEmpty ? "Jugador" : m.first.displayName;
  }

  factory GroupFullView.fromJson(Map<String, dynamic> json) {
    return GroupFullView(
      idGroup: (json["id_group"] ?? "").toString(),
      groupName: (json["group_name"] ?? "").toString(),
      members: (json["members"] as List? ?? [])
          .map((e) => GroupMemberInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      standings: (json["standings"] as List? ?? [])
          .map((e) => GroupStandingInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      matches: (json["matches"] as List? ?? [])
          .map((e) => GroupMatchInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryGroupsView {
  final List<GroupFullView> groups;

  CategoryGroupsView({required this.groups});

  String nameFor(String? userId) {
    if (userId == null) return "Vacante";
    for (final g in groups) {
      final m = g.members.where((m) => m.idUser == userId);
      if (m.isNotEmpty) return m.first.displayName;
    }
    return "Jugador";
  }

  factory CategoryGroupsView.fromJson(Map<String, dynamic> json) {
    return CategoryGroupsView(
      groups: (json["groups"] as List? ?? [])
          .map((e) => GroupFullView.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
