import "dart:async";
import "dart:convert";
import "package:http/http.dart" as http;

import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/features/auth/models/auth_models.dart";

class AuthApi {
  final String baseUrl;
  AuthApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/auth/sign-in");

    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email.trim(), "password": password}),
        )
        // 60s (no 12s): el backend es Render free tier y se duerme tras
        // inactividad — el primer request lo despierta y tarda 30-50s. Con
        // 12s el login fallaba siempre que el server estaba dormido (la web
        // no tiene timeout y por eso "aguantaba" el cold start).
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception("Login error: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Login inválido");
    }

    return AuthResponse.fromJson(decoded);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    String role = "player", // por defecto player
    String? firstName,
    String? lastName,
    String? gender,
    String? clubName,
    String? birthDate,
    String? country,
    String? idDocument,
    String? category,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/auth/sign-up");

    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email.trim(),
            "password": password,
            "role": role,
            if (firstName != null && firstName.isNotEmpty) "first_name": firstName,
            if (lastName != null && lastName.isNotEmpty) "last_name": lastName,
            if (gender != null) "gender": gender,
            if (clubName != null && clubName.isNotEmpty) "club_name": clubName,
            if (birthDate != null && birthDate.isNotEmpty) "birth_date": birthDate,
            if (country != null && country.isNotEmpty) "country": country,
            if (idDocument != null && idDocument.isNotEmpty) "id_document": idDocument,
            if (category != null && category.isNotEmpty) "category": category,
          }),
        )
        // 60s (no 12s): el backend es Render free tier y se duerme tras
        // inactividad — el primer request lo despierta y tarda 30-50s. Con
        // 12s el login fallaba siempre que el server estaba dormido (la web
        // no tiene timeout y por eso "aguantaba" el cold start).
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception("Register error: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Registro inválido");
    }

    return AuthResponse.fromJson(decoded);
  }
}
