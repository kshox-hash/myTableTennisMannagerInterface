import "dart:convert";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/notifications/models/notification_model.dart";
import "package:myttmi/core/helpers/json_parse.dart";

class NotificationsApi {
  final String baseUrl;

  NotificationsApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionStorage().getToken();
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<NotificationsSnapshot> list() async {
    final uri = Uri.parse("$baseUrl${Endpoints.notifications}");
    final res = await apiHttp.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) throw Exception(decoded["message"] ?? "Respuesta inválida");
    return NotificationsSnapshot.fromJson(decoded["data"] as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final uri = Uri.parse("$baseUrl${Endpoints.notificationsUnreadCount}");
    final res = await apiHttp.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) throw Exception(decoded["message"] ?? "Respuesta inválida");
    final data = decoded["data"] as Map<String, dynamic>?;
    return intOrDefault(data?["unread_count"]);
  }

  Future<void> markRead(String idNotification) async {
    final uri = Uri.parse("$baseUrl${Endpoints.notificationRead(idNotification)}");
    final res = await apiHttp.patch(uri, headers: await _authHeaders());
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  Future<void> markAllRead() async {
    final uri = Uri.parse("$baseUrl${Endpoints.notificationsReadAll}");
    final res = await apiHttp.post(uri, headers: await _authHeaders());
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }
}
