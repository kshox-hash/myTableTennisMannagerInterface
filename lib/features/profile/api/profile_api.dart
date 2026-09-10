import "dart:convert";
import "package:http/http.dart" as http;

import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/profile/models/profile_model.dart";

class ProfileApi {
  final String baseUrl;
  ProfileApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionStorage().getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Sin sesión (token vacío)");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<UserProfile> getMe() async {
    final uri = Uri.parse("$baseUrl${Endpoints.me}");
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    return UserProfile.fromJson(decoded["data"] as Map<String, dynamic>);
  }

  Future<UserProfile> updateMe({
    String? firstName,
    String? lastName,
    String? gender,
    String? clubName,
    String? birthDate,
    String? country,
    String? idDocument,
    String? category,
  }) async {
    final uri = Uri.parse("$baseUrl${Endpoints.me}");
    final res = await http.patch(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        if (firstName != null) "first_name": firstName,
        if (lastName != null) "last_name": lastName,
        if (gender != null) "gender": gender,
        if (clubName != null) "club_name": clubName,
        if (birthDate != null) "birth_date": birthDate,
        if (country != null) "country": country,
        if (idDocument != null) "id_document": idDocument,
        if (category != null) "category": category,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "No se pudo actualizar el perfil");
    }

    return UserProfile.fromJson(decoded["data"] as Map<String, dynamic>);
  }

  Future<PlayerStats> getStats() async {
    final uri = Uri.parse("$baseUrl${Endpoints.myStats}");
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    return PlayerStats.fromJson(decoded["data"] as Map<String, dynamic>?);
  }

  Future<PublicPlayerProfile> getPublicProfile(String userId) async {
    final uri = Uri.parse("$baseUrl${Endpoints.userProfile(userId)}");
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    return PublicPlayerProfile.fromJson(decoded["data"] as Map<String, dynamic>);
  }
}
