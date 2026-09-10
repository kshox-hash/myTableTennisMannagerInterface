import "dart:convert";
import "package:http/http.dart" as http;
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/ranking/models/ranking_model.dart";

class RankingApi {
  final String baseUrl;

  RankingApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<List<RankingEntry>> getGlobal() async {
    final token = await SessionStorage().getToken();
    final uri = Uri.parse("$baseUrl${Endpoints.ranking}");
    final res = await http.get(uri, headers: {
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
    final data = (decoded["data"] as List? ?? []).cast<Map<String, dynamic>>();
    return data.map(RankingEntry.fromJson).toList();
  }
}
