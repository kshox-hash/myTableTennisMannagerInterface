import "dart:convert";

import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/helpers/text_format.dart";
import "package:myttmi/core/storage/session_storage.dart";

/// Partido que me toca arbitrar (asignado por el organizador o por QR).
class RefereeMatch {
  final String idMatch;
  final String matchType; // group | bracket
  final String tournamentName;
  final String categoryDisplay;
  final String player1Name;
  final String player2Name;
  final int? tableNumber;

  RefereeMatch({
    required this.idMatch,
    required this.matchType,
    required this.tournamentName,
    required this.categoryDisplay,
    required this.player1Name,
    required this.player2Name,
    this.tableNumber,
  });

  factory RefereeMatch.fromJson(Map<String, dynamic> j) => RefereeMatch(
        idMatch: j["id_match"].toString(),
        matchType: j["match_type"].toString(),
        tournamentName: prettyTitle((j["tournament_name"] ?? "").toString()),
        categoryDisplay: (j["category_display"] ?? "").toString(),
        player1Name: (j["player1_name"] ?? "Por definir").toString(),
        player2Name: (j["player2_name"] ?? "Por definir").toString(),
        tableNumber: j["table_number"] is int ? j["table_number"] as int : int.tryParse("${j["table_number"]}"),
      );
}

class RefereeApi {
  Future<Map<String, String>> _headers() async {
    final token = await SessionStorage().getToken();
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  String _seg(String matchType) => matchType == "group" ? "matches" : "bracket-matches";

  dynamic _decode(int status, String body) {
    Map<String, dynamic>? j;
    try {
      j = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {}
    if (status >= 200 && status < 300 && j?["ok"] == true) return j?["data"];
    throw Exception(j?["message"] ?? "Error $status");
  }

  Future<List<RefereeMatch>> myMatches() async {
    final r = await apiHttp.get(Uri.parse("${AppConfig.baseUrl}${Endpoints.refereeMyMatches}"), headers: await _headers());
    final data = _decode(r.statusCode, r.body) as List;
    return data.map((e) => RefereeMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Canjea el QR del organizador: devuelve (tipo, idPartido).
  Future<(String, String)> claim(String code) async {
    final r = await apiHttp.post(
      Uri.parse("${AppConfig.baseUrl}${Endpoints.refereeClaim}"),
      headers: await _headers(),
      body: jsonEncode({"token": code}),
    );
    final d = _decode(r.statusCode, r.body) as Map<String, dynamic>;
    return (d["match_type"].toString(), d["id_match"].toString());
  }

  /// Sets terminados hasta ahora (marcador en vivo para jugadores y público).
  Future<void> saveLive(String matchType, String matchId, List<(int, int)> sets) async {
    final r = await apiHttp.patch(
      Uri.parse("${AppConfig.baseUrl}${Endpoints.base}/bracket/referee/${_seg(matchType)}/$matchId/live-score"),
      headers: await _headers(),
      body: jsonEncode({"set_scores": [for (final s in sets) {"p1": s.$1, "p2": s.$2}]}),
    );
    _decode(r.statusCode, r.body);
  }

  /// Resultado final (igual que si lo cargara el organizador).
  Future<void> submitResult({
    required String matchType,
    required String matchId,
    required String winnerId,
    required List<(int, int)> sets,
  }) async {
    final s1 = sets.where((s) => s.$1 > s.$2).length;
    final s2 = sets.where((s) => s.$2 > s.$1).length;
    final r = await apiHttp.post(
      Uri.parse("${AppConfig.baseUrl}${Endpoints.base}/bracket/referee/${_seg(matchType)}/$matchId/result"),
      headers: await _headers(),
      body: jsonEncode({
        "winner_id": winnerId,
        "sets_player1": s1,
        "sets_player2": s2,
        "set_scores": [for (final s in sets) {"p1": s.$1, "p2": s.$2}],
      }),
    );
    _decode(r.statusCode, r.body);
  }
}
