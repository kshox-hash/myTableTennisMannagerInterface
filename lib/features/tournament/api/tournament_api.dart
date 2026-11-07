import "dart:convert";
import "package:flutter/foundation.dart";
import "package:myttmi/core/api/api_http.dart";

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
  /// Sube cada vez que el jugador se inscribe o anula una inscripción (desde
  /// cualquier pantalla). El Inicio y el Calendario lo escuchan y se ponen
  /// al día: antes, si te inscribías desde un campeonato abierto encima del
  /// Inicio (próximo desafío, aviso, link compartido) y volvías atrás, la
  /// pestaña no cambiaba y "Mis campeonatos" seguía sin el campeonato.
  static final enrollmentsChanged = ValueNotifier<int>(0);

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

    final res = await apiHttp.get(
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

    final res = await apiHttp.get(
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

    // limit=20 (el máximo): la tarjeta "Tu turno" necesita encontrar el
    // partido del jugador aunque esté más atrás en la cola.
    final uri = Uri.parse("$baseUrl${Endpoints.tablesQueue(tournamentId)}?limit=20");

    final res = await apiHttp.get(
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
  /// Anula mi inscripción (solo mientras la categoría siga en inscripciones).
  Future<void> unsubscribeFromCategory({
    required String tournamentId,
    required String categoryId,
  }) async {
    final token = await SessionStorage().getToken();
    if (token == null || token.isEmpty) {
      throw Exception("No hay sesión. Vuelve a iniciar sesión.");
    }
    final res = await apiHttp.post(
      Uri.parse("$baseUrl${Endpoints.subscribe.replaceFirst("/subscribe", "/unsubscribe")}"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"id_tournament": tournamentId, "id_category": categoryId}),
    );
    if (res.statusCode != 200) {
      String msg = "No se pudo anular la inscripción";
      try {
        msg = (jsonDecode(res.body) as Map<String, dynamic>)["message"]?.toString() ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
    enrollmentsChanged.value++;
  }

  Future<void> subscribeToCategory({
    required String tournamentId,
    required String categoryId,
  }) async {
    final token = await SessionStorage().getToken();

    if (token == null || token.isEmpty) {
      throw Exception("No hay sesión. Vuelve a iniciar sesión.");
    }

    final uri = Uri.parse("$baseUrl${Endpoints.subscribe}");

    final res = await apiHttp.post(
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
    enrollmentsChanged.value++;
  }

  // -----------------------
  // SEGUIR UN CAMPEONATO como visita (sin inscribirse): avisos de los
  // momentos importantes (empezó una categoría, la llave, los campeones,
  // cambios y cancelación).
  // -----------------------
  Future<({bool following, int followers})> getFollow(String tournamentId) async {
    final token = await SessionStorage().getToken();
    final res = await apiHttp.get(
      Uri.parse("$baseUrl${Endpoints.tournamentFollow(tournamentId)}"),
      headers: {if (token != null && token.isNotEmpty) "Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}");
    final data = (jsonDecode(res.body) as Map<String, dynamic>)["data"] as Map<String, dynamic>;
    return (following: data["following"] == true, followers: (data["followers"] as num?)?.toInt() ?? 0);
  }

  /// Campeonatos que sigo (los más nuevos primero).
  Future<List<FollowedTournament>> getFollowing() async {
    final token = await SessionStorage().getToken();
    final res = await apiHttp.get(
      Uri.parse("$baseUrl${Endpoints.followingTournaments}"),
      headers: {if (token != null && token.isNotEmpty) "Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) throw Exception("No se pudieron cargar los campeonatos que sigues");
    final list = (jsonDecode(res.body) as Map<String, dynamic>)["data"] as List<dynamic>;
    return list.map((e) => FollowedTournament.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setFollow(String tournamentId, bool follow) async {
    final token = await SessionStorage().getToken();
    final uri = Uri.parse("$baseUrl${Endpoints.tournamentFollow(tournamentId)}");
    final headers = {if (token != null && token.isNotEmpty) "Authorization": "Bearer $token"};
    final res = follow ? await apiHttp.post(uri, headers: headers) : await apiHttp.delete(uri, headers: headers);
    if (res.statusCode != 200) throw Exception("No se pudo ${follow ? "seguir" : "dejar de seguir"} el campeonato");
  }
}

/// Un campeonato que sigo como visita.
class FollowedTournament {
  final String idTournament;
  final String name;
  final DateTime? eventDate;
  final String status;
  final String? address;
  const FollowedTournament({required this.idTournament, required this.name, this.eventDate, required this.status, this.address});

  factory FollowedTournament.fromJson(Map<String, dynamic> j) => FollowedTournament(
        idTournament: j["id_tournament"] as String,
        name: (j["tournament_name"] as String?) ?? "Campeonato",
        eventDate: j["event_date"] == null ? null : DateTime.tryParse(j["event_date"] as String)?.toLocal(),
        status: (j["status"] as String?) ?? "active",
        address: j["address"] as String?,
      );
}
