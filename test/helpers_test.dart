import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:myttmi/core/helpers/friendly_error.dart";
import "package:myttmi/core/helpers/json_parse.dart";
import "package:myttmi/core/helpers/text_format.dart";

void main() {
  group("friendlyError", () {
    test("usa el message del servidor en vez del JSON crudo", () {
      final e = Exception('HTTP 409: {"ok":false,"message":"Email ya existe"}');
      expect(friendlyError(e), "Email ya existe");
    });

    test("error 500 sin message: texto genérico, sin código ni JSON", () {
      final msg = friendlyError(Exception("HTTP 500: <html>Internal Server Error</html>"));
      expect(msg, contains("problema en el servidor"));
      expect(msg, isNot(contains("HTTP")));
    });

    test("sin conexión", () {
      expect(friendlyError(Exception("ClientException: Failed host lookup: 'api'")), contains("Sin conexión"));
    });

    test("timeout", () {
      expect(friendlyError(TimeoutException("x")), contains("tardando"));
    });

    test("un mensaje ya pensado para el usuario pasa tal cual", () {
      expect(friendlyError(Exception("Ese campeonato ya no está disponible.")), "Ese campeonato ya no está disponible.");
    });

    test("errores internos de Dart no se muestran", () {
      expect(friendlyError("type 'Null' is not a subtype of type 'String'"), "Algo salió mal. Inténtalo de nuevo.");
    });
  });

  group("json_parse", () {
    test("acepta números como número o como string (bigint de Postgres)", () {
      expect(intOrDefault(3), 3);
      expect(intOrDefault("7"), 7);
      expect(intOrDefault(null, 5), 5);
      expect(intOrNull("abc"), isNull);
    });
  });

  group("prettyTitle", () {
    test("mayúscula inicial y preposiciones en minúscula", () {
      expect(prettyTitle("torneo comunal de san miguel"), "Torneo Comunal de San Miguel");
    });

    test("respeta la marca MyTTM", () {
      expect(prettyTitle("copa myttm"), "Copa MyTTM");
    });
  });
}
