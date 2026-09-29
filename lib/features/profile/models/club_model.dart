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

/// "¿Estoy al día con mi club?" — mismo cálculo de morosidad que ve el
/// dueño del club, solo la fila del jugador.
class MyClubDues {
  final String clubName;
  final int? fee;
  final String feeFrequency; // monthly | weekly
  final int owedPeriods;
  final int owedAmount;

  MyClubDues({required this.clubName, this.fee, required this.feeFrequency, required this.owedPeriods, required this.owedAmount});

  bool get upToDate => owedPeriods == 0;

  factory MyClubDues.fromJson(Map<String, dynamic> json) => MyClubDues(
        clubName: (json["club_name"] ?? "").toString(),
        fee: json["fee"] == null ? null : (json["fee"] as num).round(),
        feeFrequency: (json["fee_frequency"] ?? "monthly").toString(),
        owedPeriods: (json["owed_periods"] as num? ?? 0).round(),
        owedAmount: (json["owed_amount"] as num? ?? 0).round(),
      );
}
