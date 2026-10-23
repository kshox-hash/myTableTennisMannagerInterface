/// Dirección de una foto (avatar) lista para cargar en el celular.
///
/// Android, en producción, bloquea las conexiones sin cifrar: una foto
/// guardada como "http://…" no carga (en la web sí). También se corrige
/// una dirección sin esquema ("pub-xxx.r2.dev/avatars/…"), que el
/// cargador de imágenes no sabe abrir. null si no hay foto.
String? safeImageUrl(String? raw) {
  final u = (raw ?? "").trim();
  if (u.isEmpty) return null;
  if (u.startsWith("https://")) return u;
  if (u.startsWith("http://")) return "https://${u.substring(7)}";
  if (u.startsWith("//")) return "https:$u";
  if (!u.contains("://") && u.contains(".")) return "https://$u";
  return u;
}
