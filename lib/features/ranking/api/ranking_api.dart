import "dart:convert";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/ranking/models/ranking_model.dart";

class RankingApi {
  final String baseUrl;

  RankingApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final token = await SessionStorage().getToken();
    final uri = Uri.parse("$baseUrl$path").replace(queryParameters: query == null || query.isEmpty ? null : query);
    final res = await apiHttp.get(uri, headers: {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    });
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }
    return decoded["data"];
  }

  Map<String, String> _scope(String? organizerId, String copa) => {if (organizerId != null) "organizer": organizerId, "copa": copa};

  /// Ranking general, o el de un organizador (solo sus campeonatos).
  Future<List<RankingEntry>> getGlobal({String? organizerId, String copa = "oro"}) async {
    final data = (await _get(Endpoints.ranking, _scope(organizerId, copa)) as List? ?? []).cast<Map<String, dynamic>>();
    return data.map(RankingEntry.fromJson).toList();
  }

  /// Rankings que puedo elegir aparte del general: un organizador por cada
  /// uno en cuyos campeonatos puntuables tengo resultado.
  Future<List<RankingScope>> getScopes() async {
    final data = (await _get("${Endpoints.ranking}/scopes") as List? ?? []).cast<Map<String, dynamic>>();
    return data.map(RankingScope.fromJson).toList();
  }

  /// Campeonatos que forman ese ranking.
  Future<List<RankingTournament>> getTournaments({String? organizerId, String copa = "oro"}) async {
    final data = (await _get("${Endpoints.ranking}/tournaments", _scope(organizerId, copa)) as List? ?? []).cast<Map<String, dynamic>>();
    return data.map(RankingTournament.fromJson).toList();
  }

  /// De qué campeonatos salen los puntos de un jugador.
  Future<List<RankingResult>> getBreakdown(String userId, {String? organizerId, String copa = "oro"}) async {
    final data = (await _get("${Endpoints.ranking}/players/$userId/breakdown", _scope(organizerId, copa)) as List? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(RankingResult.fromJson).toList();
  }
}
