class PublicClub {
  final String idClub;
  final String name;

  PublicClub({required this.idClub, required this.name});

  factory PublicClub.fromJson(Map<String, dynamic> json) => PublicClub(
    idClub: (json["id_club"] ?? "").toString(),
    name: (json["name"] ?? "").toString(),
  );
}

class MyClubRequest {
  final String idRequest;
  final String idClub;
  final String clubName;
  final String status; // "pending" | "approved" | "rejected"

  MyClubRequest({
    required this.idRequest,
    required this.idClub,
    required this.clubName,
    required this.status,
  });

  factory MyClubRequest.fromJson(Map<String, dynamic> json) => MyClubRequest(
    idRequest: (json["id_request"] ?? "").toString(),
    idClub: (json["id_club"] ?? "").toString(),
    clubName: (json["club_name"] ?? "").toString(),
    status: (json["status"] ?? "").toString(),
  );
}
