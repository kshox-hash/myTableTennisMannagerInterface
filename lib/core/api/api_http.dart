import "package:http/http.dart" as http;

/// Cliente HTTP compartido por todas las APIs de la app.
///
/// `http.get(...)` suelto crea un cliente nuevo por pedido y lo cierra al
/// terminar: cada llamada abría otra conexión TCP + TLS con el servidor
/// (~100-300 ms extra en celular). Con un solo cliente la conexión queda
/// abierta (keep-alive) y se reutiliza entre pedidos.
final http.Client apiHttp = http.Client();
