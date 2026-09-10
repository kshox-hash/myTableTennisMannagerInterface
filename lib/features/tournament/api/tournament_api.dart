import "dart:convert";
import "package:http/http.dart" as http;

import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/tournament/models/tables_queue_model.dart";
import "package:myttmi/core/helpers/json_parse.dart";

class TournamentsPage {
  final List<Tournament> items;
  final int page;
  final int totalPages;

  TournamentsPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

class TournamentApi {
  final String baseUrl;

  TournamentApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  // -----------------------
  // LISTAR TORNEOS (filtros + paginado) — requiere sesión: la ruta
  // /tournament/player/tournaments exige authRequired (y usa el token para
  // poblar is_enrolled por categoría). El backend pagina de a 20 por
  // default; sin pasar page/limit acá la app se quedaba pegada a los
  // primeros 20 resultados siempre.
  // -----------------------
  Future<TournamentsPage> fetchTournaments({
    String? q,
    String? city, // se manda como "region" al backend
    int page = 1,
    int limit = 20,
  }) async {
    final token = await SessionStorage().getToken();

    final params = <String, String>{
      "page": page.toString(),
      "limit": limit.toString(),
    };
    final qq = (q ?? "").trim();
    if (qq.isNotEmpty) params["q"] = qq;
    final region = (city ?? "").trim();
    if (region.isNotEmpty) params["region"] = region;

    final uri = Uri.parse(
      "$baseUrl${Endpoints.listTournaments}",
    ).replace(queryParameters: params);

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    final data = (decoded["data"] as List).cast<Map<String, dynamic>>();
    final pagination = decoded["pagination"] as Map<String, dynamic>?;
    return TournamentsPage(
      items: data.map(Tournament.fromJson).toList(),
      page: intOrDefault(pagination?["page"], page),
      totalPages: intOrDefault(pagination?["total_pages"], 1),
    );
  }

  // -----------------------
  // UN TORNEO PUNTUAL (ej. tocar un evento del calendario, que solo trae el
  // id/nombre/categoría del torneo — no el objeto Tournament completo que
  // pide TournamentDetailScreen).
  // -----------------------
  Future<Tournament> getTournamentById(String tournamentId) async {
    final token = await SessionStorage().getToken();

    final uri = Uri.parse("$baseUrl${Endpoints.tournamentById(tournamentId)}");

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 404) {
      throw Exception("Ese campeonato ya no está disponible.");
    }
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    return Tournament.fromJson(decoded["data"] as Map<String, dynamic>);
  }

  // -----------------------
  // MESAS EN VIVO + próximos partidos de la cola — misma información que ve
  // el admin en el panel de Mesas, en versión de solo lectura.
  // -----------------------
  Future<TablesQueueBoard> getTablesQueue(String tournamentId) async {
    final token = await SessionStorage().getToken();

    final uri = Uri.parse("$baseUrl${Endpoints.tablesQueue(tournamentId)}");

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }

    return TablesQueueBoard.fromJson(decoded["data"] as Map<String, dynamic>);
  }

  // -----------------------
  // SUSCRIBIRSE A CATEGORÍA
  // El id_user NO va en el body: el backend lo saca del JWT, y el schema es
  // estricto (rechaza cualquier campo que no espere).
  // -----------------------
  Future<void> subscribeToCategory({
    required String tournamentId,
    required String categoryId,
  }) async {
    final token = await SessionStorage().getToken();

    if (token == null || token.isEmpty) {
      throw Exception("No hay sesión. Vuelve a iniciar sesión.");
    }

    final uri = Uri.parse("$baseUrl${Endpoints.subscribe}");

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "id_tournament": tournamentId,
        "id_category": categoryId,
      }),
    );

    if (res.statusCode == 409) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(decoded["message"] ?? "No se pudo suscribir");
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "No se pudo suscribir");
    }
  }
}
