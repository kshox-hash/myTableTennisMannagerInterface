import "dart:convert";
import "package:http/http.dart" as http;

import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/profile/models/club_model.dart";

// Selector de club (registro y Perfil) — pedir unirse manda una solicitud
// al admin dueño del club, no asigna el club directo. Mismo mecanismo que
// myttmi-web (ver features/profile/api/clubsApi.ts ahí).
class ClubsApi {
  final String baseUrl;
  ClubsApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  // El listado es público (sin login) — tiene que poder verse en el
  // registro, antes de que exista sesión. Si hay token igual se manda,
  // no hace daño.
  Future<Map<String, String>> _headers() async {
    final token = await SessionStorage().getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) headers["Authorization"] = "Bearer $token";
    return headers;
  }

  Future<List<PublicClub>> list() async {
    final uri = Uri.parse("$baseUrl${Endpoints.clubs}");
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "No se pudo cargar la lista de clubes");
    }
    final data = decoded["data"] as List<dynamic>? ?? [];
    return data.map((e) => PublicClub.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MyClubRequest?> getMyRequest() async {
    final uri = Uri.parse("$baseUrl${Endpoints.clubMyRequest}");
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "No se pudo cargar la solicitud");
    }
    final data = decoded["data"];
    if (data == null) return null;
    return MyClubRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<void> requestJoin(String idClub) async {
    final uri = Uri.parse("$baseUrl${Endpoints.clubJoin(idClub)}");
    final res = await http.post(uri, headers: await _headers()).timeout(const Duration(seconds: 60));

    if (res.statusCode != 201 && res.statusCode != 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(decoded?["message"] ?? "No se pudo enviar la solicitud");
    }
  }

  Future<void> cancelMyRequest() async {
    final uri = Uri.parse("$baseUrl${Endpoints.clubMyRequest}");
    final res = await http.delete(uri, headers: await _headers()).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(decoded?["message"] ?? "No se pudo cancelar la solicitud");
    }
  }
}
