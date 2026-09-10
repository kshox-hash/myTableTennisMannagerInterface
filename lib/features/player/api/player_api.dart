import "dart:convert";
import "package:http/http.dart" as http;
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/player/models/player_dashboard_model.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/player/models/achievement_model.dart";

class PlayerApi {
  final String baseUrl;

  PlayerApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionStorage().getToken();
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    var uri = Uri.parse("$baseUrl$path");
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractMessage(res.body) ?? "HTTP ${res.statusCode}");
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Respuesta inválida");
    }
    return decoded["data"];
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded["message"] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<PlayerDashboard> getDashboard() async {
    final data = await _get(Endpoints.playerDashboard) as Map<String, dynamic>;
    return PlayerDashboard.fromJson(data);
  }

  Future<List<PlayerEnrollment>> getMyEnrollments() async {
    final data = await _get(Endpoints.myEnrollments) as List;
    return data
        .map((e) => PlayerEnrollment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerCategoryView> getCategoryView(
    String tournamentId,
    String categoryId,
  ) async {
    final data =
        await _get(Endpoints.categoryView(tournamentId, categoryId))
            as Map<String, dynamic>;
    return PlayerCategoryView.fromJson(data);
  }

  // A diferencia de getCategoryView (que solo trae "mi" grupo/partidos), esto
  // da la tabla de posiciones general — visible para cualquier jugador,
  // esté o no inscripto en la categoría (modo espectador).
  Future<CategoryStandings> getCategoryStandings(
    String tournamentId,
    String categoryId,
  ) async {
    final data =
        await _get(Endpoints.categoryStandings(tournamentId, categoryId))
            as Map<String, dynamic>;
    return CategoryStandings.fromJson(data);
  }

  // Todos los grupos de la categoría (no solo "el mío") — para poder ver
  // cómo van los demás grupos, igual que en el panel admin.
  Future<CategoryGroupsView> getAllGroups(
    String tournamentId,
    String categoryId,
  ) async {
    final data =
        await _get(Endpoints.allGroups(tournamentId, categoryId))
            as Map<String, dynamic>;
    return CategoryGroupsView.fromJson(data);
  }

  Future<List<TournamentParticipant>> getTournamentParticipants(
    String tournamentId,
  ) async {
    final data =
        await _get(Endpoints.tournamentParticipants(tournamentId)) as List;
    return data
        .map((e) => TournamentParticipant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TournamentMatch>> getTournamentMatches(
    String tournamentId, {
    String? status,
    int? limit,
  }) async {
    final data =
        await _get(
              Endpoints.tournamentMatches(tournamentId),
              query: {
                if (status != null) "status": status,
                if (limit != null) "limit": limit.toString(),
              },
            )
            as List;
    return data
        .map((e) => TournamentMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MatchDetail> getMatchDetail(String matchType, String matchId) async {
    final data =
        await _get(Endpoints.matchDetail(matchType, matchId))
            as Map<String, dynamic>;
    return MatchDetail.fromJson(data);
  }

  Future<List<PlayerMatchHistoryItem>> getPlayerMatchHistory(
    String userId, {
    int limit = 15,
  }) async {
    final data =
        await _get(
              Endpoints.userMatches(userId),
              query: {"limit": limit.toString()},
            )
            as List;
    return data
        .map((e) => PlayerMatchHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlayerAchievement>> getPlayerAchievements(String userId) async {
    final data = await _get(Endpoints.userAchievements(userId)) as List;
    return data
        .map((e) => PlayerAchievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
