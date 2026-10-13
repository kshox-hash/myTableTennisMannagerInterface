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

/// Lo que el socio ve de sus cuotas — solo si el dueño del club lo activó
/// (si no, el servidor responde null y no se muestra nada). Nunca trae
/// "deuda": su modalidad de cuota y su historial de pagos registrados.
class MyClubPayments {
  final String clubName;
  final String feeFrequency; // monthly | weekly
  final String feeMode; // none | standard | custom | exempt | paused
  final int? feeAmount;
  final List<ClubPayment> payments;

  MyClubPayments({
    required this.clubName,
    required this.feeFrequency,
    required this.feeMode,
    this.feeAmount,
    required this.payments,
  });

  ClubPayment? get lastPayment => payments.isEmpty ? null : payments.first;

  factory MyClubPayments.fromJson(Map<String, dynamic> json) => MyClubPayments(
        clubName: (json["club_name"] ?? "").toString(),
        feeFrequency: (json["fee_frequency"] ?? "monthly").toString(),
        feeMode: (json["fee_mode"] ?? "none").toString(),
        feeAmount: json["fee_amount"] == null ? null : (json["fee_amount"] as num).round(),
        payments: ((json["payments"] as List?) ?? const [])
            .map((p) => ClubPayment.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class ClubPayment {
  final String idPayment;
  final int amount;
  final int periods;
  final DateTime firstPeriod;
  final String? method; // cash | transfer | other
  final DateTime paidOn;

  ClubPayment({
    required this.idPayment,
    required this.amount,
    required this.periods,
    required this.firstPeriod,
    this.method,
    required this.paidOn,
  });

  factory ClubPayment.fromJson(Map<String, dynamic> json) => ClubPayment(
        idPayment: (json["id_payment"] ?? "").toString(),
        amount: (json["amount"] as num? ?? 0).round(),
        periods: (json["periods"] as num? ?? 1).round(),
        // "YYYY-MM-DD" sin hora: se lee como fecha local.
        firstPeriod: DateTime.parse((json["first_period"] ?? "1970-01-01").toString()),
        method: json["method"]?.toString(),
        paidOn: DateTime.parse((json["paid_on"] ?? "1970-01-01").toString()),
      );
}
