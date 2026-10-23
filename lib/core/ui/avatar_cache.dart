/// Registro de fotos de perfil: id de jugador → dirección de su foto.
///
/// Cada respuesta del servidor que trae la foto de alguien (perfil, ranking,
/// inscritos, partidos, tablas) la deja anotada acá. UserAvatar la busca
/// por id, así que una pantalla cuyo endpoint no manda la foto igual la
/// muestra si ya se vio en otra parte. La imagen descargada la reutiliza el
/// caché de imágenes de Flutter (misma dirección y tamaño = no se baja ni
/// se decodifica de nuevo).
class AvatarCache {
  AvatarCache._();

  static final Map<String, String> _urls = {};

  /// Anota la foto de [userId] (ignora vacíos).
  static void remember(Object? userId, Object? url) {
    if (userId is! String || userId.isEmpty) return;
    if (url is! String || url.trim().isEmpty) return;
    _urls[userId] = url.trim();
  }

  static String? urlFor(String? userId) => userId == null ? null : _urls[userId];

  /// Anota las fotos que traiga una fila de partido/tabla del servidor.
  static void rememberRow(Map<String, dynamic> json) {
    remember(json["id_user"], json["avatar_url"]);
    remember(json["player1_id"], json["player1_avatar_url"]);
    remember(json["player2_id"], json["player2_avatar_url"]);
    remember(json["opponent_id"], json["opponent_avatar_url"]);
  }
}
