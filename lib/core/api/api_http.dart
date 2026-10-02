import "dart:async";

import "package:flutter/scheduler.dart";
import "package:http/http.dart" as http;

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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    ApiActivity._started();
    try {
      return await _inner.send(request);
    } finally {
      ApiActivity._finished();
    }
  }

  @override
  void close() => _inner.close();
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
  /// encadena otro), o [max] como tope. Si en los primeros ~120 ms no pidió
  /// nada, no espera más (pantallas sin datos del servidor).
  static Future<void> settle({Duration max = const Duration(milliseconds: 1200)}) async {
    final sw = Stopwatch()..start();
    final startedBefore = _startedCount;
    await SchedulerBinding.instance.endOfFrame;
    var quietSince = -1;
    while (sw.elapsedMilliseconds < max.inMilliseconds) {
      final any = _startedCount > startedBefore;
      if (!any && sw.elapsedMilliseconds >= 120) return;
      if (any && _inFlight == 0) {
        if (quietSince < 0) quietSince = sw.elapsedMilliseconds;
        if (sw.elapsedMilliseconds - quietSince >= 60) break;
      } else {
        quietSince = -1;
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
    // Un cuadro más: que la pantalla alcance a dibujar los datos recibidos.
    await SchedulerBinding.instance.endOfFrame;
  }
}
