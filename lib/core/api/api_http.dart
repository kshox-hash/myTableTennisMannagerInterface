import "dart:async";
import "dart:convert";

import "package:flutter/scheduler.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

/// Cliente HTTP compartido por todas las APIs de la app.
///
/// `http.get(...)` suelto crea un cliente nuevo por pedido y lo cierra al
/// terminar: cada llamada abría otra conexión TCP + TLS con el servidor
/// (~100-300 ms extra en celular). Con un solo cliente la conexión queda
/// abierta (keep-alive) y se reutiliza entre pedidos.
///
/// Además cuenta los pedidos en curso (ApiActivity): así una pantalla nueva
/// se muestra recién cuando terminó de traer sus datos (ver CyberPageRoute).
final http.Client apiHttp = _CountingClient(http.Client());

class _CountingClient extends http.BaseClient {
  final http.Client _inner;
  _CountingClient(this._inner);

  // Tope para que llegue la respuesta: sin señal (un gimnasio lleno) la
  // pantalla muestra "Reintentar" en vez de quedar en el esqueleto. Eran
  // 30 s para cuando Render se dormía; con el plan pagado no se duerme.
  static const _timeout = Duration(seconds: 15);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final cacheable = request.method == "GET" && ResponseCache._storing;
    if (cacheable && ResponseCache._reading) {
      final hit = ResponseCache._get(request);
      if (hit != null) {
        return http.StreamedResponse(Stream.value(hit), 200, request: request, headers: const {"content-type": "application/json; charset=utf-8"});
      }
    }
    ApiActivity._started();
    try {
      final res = await _inner.send(request).timeout(_timeout);
      if (!cacheable || res.statusCode != 200) return res;
      final bytes = await res.stream.toBytes();
      ResponseCache._put(request, bytes);
      return http.StreamedResponse(Stream.value(bytes), res.statusCode,
          request: request, headers: res.headers, reasonPhrase: res.reasonPhrase, contentLength: bytes.length);
    } finally {
      ApiActivity._finished();
    }
  }

  @override
  void close() => _inner.close();
}

/// Últimas respuestas del Inicio guardadas en el teléfono. Al abrir la app
/// el Inicio se arma al tiro con lo de la vez anterior ([read]) y después
/// se actualiza con el servidor en silencio ([store]); antes esperaba dos
/// vueltas seguidas a Render (~0,25 s cada una, más la conexión) detrás de
/// la pantalla de carga. Solo se guardan los GET 200 hechos dentro de
/// [store]/[read]; al cerrar sesión se borran (SessionStorage.clearAll
/// limpia todas las preferencias). La clave incluye el token: otra cuenta
/// en el mismo teléfono no ve lo de la anterior.
class ResponseCache {
  ResponseCache._();

  static const _prefix = "http_cache:";
  static SharedPreferences? _prefs;

  static bool get _storing => Zone.current[#responseCacheStore] == true;
  static bool get _reading => Zone.current[#responseCacheRead] == true;

  /// Hay que llamarlo al arrancar (main), antes de usar [read].
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
  }

  /// Pide al servidor y guarda las respuestas para la próxima vez.
  static Future<T> store<T>(Future<T> Function() body) => runZoned(body, zoneValues: {#responseCacheStore: true});

  /// Responde con lo guardado (sin red) lo que haya; lo que no, al servidor.
  static Future<T> read<T>(Future<T> Function() body) => runZoned(body, zoneValues: {#responseCacheStore: true, #responseCacheRead: true});

  /// Cuántas respuestas salieron de lo guardado (si sube durante [read], lo
  /// que se mostró es de la vez anterior y hay que actualizar).
  static int hits = 0;

  static String _key(http.BaseRequest r) => "$_prefix${_fnv(r.headers["Authorization"] ?? "")}:${r.url}";

  // Hash fijo (FNV-1a de 32 bits): el mismo token da la misma clave en cada
  // arranque de la app, cosa que String.hashCode no promete.
  static String _fnv(String s) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(s)) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  static List<int>? _get(http.BaseRequest r) {
    final v = _prefs?.getString(_key(r));
    if (v == null) return null;
    hits++;
    return utf8.encode(v);
  }

  static void _put(http.BaseRequest r, List<int> bytes) {
    final p = _prefs;
    if (p == null) return;
    try {
      p.setString(_key(r), utf8.decode(bytes));
    } catch (_) {}
  }
}

class ApiActivity {
  ApiActivity._();

  static int _inFlight = 0;
  static int _startedCount = 0;

  static void _started() {
    _inFlight++;
    _startedCount++;
  }

  static void _finished() {
    if (_inFlight > 0) _inFlight--;
  }

  /// Espera a que la pantalla recién armada termine de traer sus datos:
  /// hasta que no quede ningún pedido en curso (un instante seguido, por si
  /// encadena otro), o [max] como tope (corto: el toque responde rápido y,
  /// si el servidor tarda, la pantalla entra con su esqueleto). Si en los
  /// primeros ~80 ms no pidió
  /// nada, no espera más (pantallas sin datos del servidor).
  static Future<void> settle({Duration max = const Duration(milliseconds: 350)}) async {
    final sw = Stopwatch()..start();
    final startedBefore = _startedCount;
    await SchedulerBinding.instance.endOfFrame;
    var quietSince = -1;
    while (sw.elapsedMilliseconds < max.inMilliseconds) {
      final any = _startedCount > startedBefore;
      if (!any && sw.elapsedMilliseconds >= 80) return;
      if (any && _inFlight == 0) {
        if (quietSince < 0) quietSince = sw.elapsedMilliseconds;
        if (sw.elapsedMilliseconds - quietSince >= 30) break;
      } else {
        quietSince = -1;
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
    // Un cuadro más: que la pantalla alcance a dibujar los datos recibidos.
    await SchedulerBinding.instance.endOfFrame;
  }
}
