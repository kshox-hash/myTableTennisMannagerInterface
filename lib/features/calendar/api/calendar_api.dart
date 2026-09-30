import "dart:convert";
import "package:myttmi/core/api/api_http.dart";

import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/calendar/models/calendar_event.dart";

class CalendarApi {
  final String baseUrl;
  CalendarApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<List<CalendarEvent>> myEvents({required DateTime from, required DateTime to}) async {
    final token = await SessionStorage().getToken();
    if (token == null || token.isEmpty) throw Exception("Sin sesión");

    String fmt(DateTime d) =>
        "${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}";

    final uri = Uri.parse("$baseUrl/api/v1/calendar/my?from=${fmt(from)}&to=${fmt(to)}");

    final res = await apiHttp.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded["ok"] != true) throw Exception(decoded["message"] ?? "Respuesta inválida");

    final list = (decoded["data"] as List).cast<Map<String, dynamic>>();
    return list.map(CalendarEvent.fromJson).toList();
  }
}
