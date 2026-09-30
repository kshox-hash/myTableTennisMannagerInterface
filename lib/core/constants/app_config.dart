class AppConfig {
  // Backend en Render (mismo baseUrl que usa myttmi-web vía
  // VITE_API_BASE_URL) — mantenerlos sincronizados.
  // Para volver a desarrollo local: "http://localhost:4310" (o la IP de la
  // máquina en la red local si se prueba en un dispositivo/emulador Android
  // físico — 10.0.2.2 para el emulador).
  //
  // Se puede cambiar al correr sin tocar este archivo:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:4310
  // Sin el define queda Render (producción), igual que siempre.
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://mytabletennismannager.onrender.com",
  );

  /// Web pública: base de los links de campeonato que se comparten
  /// (https://www.myttm.cl/torneos/<id>). Con la app instalada, Android abre
  /// esos links acá (App Links, ver AndroidManifest + deep_links.dart).
  static const String webBaseUrl = "https://www.myttm.cl";

  /// ID de cliente WEB de Google (el mismo del login con Google de la web):
  /// la app pide el token para ese cliente, que es el que valida el servidor
  /// (GOOGLE_CLIENT_ID).
  static const String googleWebClientId = String.fromEnvironment(
    "GOOGLE_WEB_CLIENT_ID",
    defaultValue: "274578390065-br8pmjhg8a8r3c2albr9eg5la2pse9hv.apps.googleusercontent.com",
  );
}
