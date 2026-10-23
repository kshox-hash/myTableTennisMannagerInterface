import "dart:async";
import "dart:convert";

/// Convierte cualquier error (excepción de red, timeout, "HTTP 500: {...}"
/// del servidor) en un mensaje para el jugador. Antes los toasts y las
/// pantallas de error mostraban el texto crudo — "Exception: HTTP 500:
/// {"ok":false,...}" — que no le dice nada a nadie y se ve roto.
///
/// Los mensajes que ya vienen pensados para el usuario (el "message" del
/// servidor, "Ese campeonato ya no está disponible.") pasan tal cual.
String friendlyError(Object error) {
  if (error is TimeoutException) {
    return "El servidor está tardando en responder. Revisa tu conexión e inténtalo de nuevo.";
  }

  var msg = error.toString().replaceFirst("Exception: ", "").trim();

  // Sin red: SocketException / ClientException / XMLHttpRequest (web).
  if (RegExp(r"SocketException|ClientException|Failed host lookup|Connection (refused|reset|closed)|XMLHttpRequest|HandshakeException",
          caseSensitive: false)
      .hasMatch(msg)) {
    return "Sin conexión. Revisa tu internet e inténtalo de nuevo.";
  }
  if (msg.contains("TimeoutException")) {
    return "El servidor está tardando en responder. Revisa tu conexión e inténtalo de nuevo.";
  }

  // "HTTP 404: {...}" o "Register error: {...}": si el cuerpo trae un
  // "message" del servidor, ese es el mensaje; si no, uno según el código.
  final http = RegExp(r"^HTTP (\d{3})").firstMatch(msg);
  final jsonStart = msg.indexOf("{");
  if (jsonStart >= 0) {
    try {
      final body = jsonDecode(msg.substring(jsonStart));
      if (body is Map && body["message"] is String && (body["message"] as String).isNotEmpty) {
        return body["message"] as String;
      }
    } catch (_) {}
  }
  if (http != null) {
    final code = int.parse(http.group(1)!);
    if (code == 401) return "Tu sesión venció. Vuelve a iniciar sesión.";
    if (code == 403) return "No tienes permiso para hacer esto.";
    if (code == 404) return "No encontramos lo que buscabas. Puede que ya no exista.";
    if (code == 429) return "Demasiados intentos. Espera unos minutos e inténtalo de nuevo.";
    if (code >= 500) return "Tuvimos un problema en el servidor. Inténtalo de nuevo en un momento.";
    return "No se pudo completar. Inténtalo de nuevo.";
  }

  // Texto técnico que se haya colado (stack, tipos de Dart, JSON suelto).
  if (msg.isEmpty || msg.length > 160 || msg.contains("{") || RegExp(r"Error|type '|Null check|RangeError").hasMatch(msg)) {
    return "Algo salió mal. Inténtalo de nuevo.";
  }
  return msg;
}
