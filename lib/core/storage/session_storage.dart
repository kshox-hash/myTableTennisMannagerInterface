import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:myttmi/core/monitoring.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Sesión del jugador. El token (la llave de la cuenta) va en almacenamiento
/// cifrado del sistema (Keystore en Android, Keychain en iOS) — antes estaba
/// en SharedPreferences, un archivo de texto plano. Rol, id y email no son
/// secretos y siguen en SharedPreferences.
///
/// El token se guarda además en memoria: se lee en cada pedido al servidor y
/// el almacenamiento cifrado es más lento.
class SessionStorage {
  static const _kToken = "token";
  static const _kRole = "role";
  static const _kUserId = "user_id";
  static const _kEmail = "email";

  static const _secure = FlutterSecureStorage();
  static String? _tokenCache;
  static bool _tokenLoaded = false;

  // En web no hay Keystore: ahí el token sigue en SharedPreferences.
  static bool get _useSecure => !kIsWeb;

  Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
    String? email,
  }) async {
    await saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, role);
    await prefs.setString(_kUserId, userId);
    if (email != null) await prefs.setString(_kEmail, email);
    Monitoring.setUser(userId);
  }

  Future<void> saveToken(String token) async {
    _tokenCache = token;
    _tokenLoaded = true;
    if (_useSecure) {
      await _secure.write(key: _kToken, value: token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
    }
  }

  Future<String?> getToken() async {
    if (_tokenLoaded) return _tokenCache;
    final prefs = await SharedPreferences.getInstance();
    String? token;
    if (_useSecure) {
      try {
        token = await _secure.read(key: _kToken);
      } catch (_) {
        token = null; // Keystore ilegible (p. ej. tras restaurar un respaldo): se vuelve a iniciar sesión
      }
      // Migración: sesiones de antes de esta versión tienen el token en
      // SharedPreferences — se mueve al almacenamiento cifrado y se borra
      // de ahí, sin pedirle al jugador que vuelva a entrar.
      final legacy = prefs.getString(_kToken);
      if (legacy != null) {
        token ??= legacy;
        await _secure.write(key: _kToken, value: token);
        await prefs.remove(_kToken);
      }
    } else {
      token = prefs.getString(_kToken);
    }
    _tokenCache = token;
    _tokenLoaded = true;
    return token;
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, id);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  Future<void> clearAll() async {
    _tokenCache = null;
    _tokenLoaded = true;
    if (_useSecure) {
      try {
        await _secure.delete(key: _kToken);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Monitoring.setUser(null);
  }

  // Alias usado por splash_gate y profile_screen.
  Future<void> clear() => clearAll();

  Future<bool> hasSession() async {
    final token = await getToken();
    final role = await getRole();
    final userId = await getUserId();
    return (token != null && token.isNotEmpty) &&
        (role != null && role.isNotEmpty) &&
        (userId != null && userId.isNotEmpty);
  }
}
