class AppConfig {
  // Backend en Render (mismo baseUrl que usa myttmi-web vía
  // VITE_API_BASE_URL) — mantenerlos sincronizados.
  // Para volver a desarrollo local: "http://localhost:4310" (o la IP de la
  // máquina en la red local si se prueba en un dispositivo/emulador Android
  // físico — 10.0.2.2 para el emulador).
  static const String baseUrl = "https://mytabletennismannager.onrender.com";
}
