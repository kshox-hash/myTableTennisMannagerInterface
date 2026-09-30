import "dart:async";
import "dart:convert";

import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/helpers/endpoints.dart";
import "package:myttmi/core/navigation/deep_links.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/features/shell/match_ready_watcher.dart";

/// Notificaciones push (Firebase Cloud Messaging).
///
/// El servidor ya manda por FCM cada notificación que guarda (ver
/// notifications/push.ts en el backend); acá la app:
///  - pide permiso y registra el token del celular (POST /notifications/device-token),
///  - con la app abierta, muestra el aviso como toast (Android no lo muestra
///    en la barra si la app está en primer plano),
///  - al tocar el aviso, abre el campeonato que viene en `id_tournament`.
/// Con la app cerrada o en segundo plano, Android muestra el aviso solo en el
/// canal "myttm_partidos" (creado en MainActivity.kt).
class PushService {
  PushService._();

  static bool _ready = false;
  static bool _listening = false;
  static String? _token;

  /// En main(), antes de runApp. Si falta google-services.json o Firebase
  /// falla, la app sigue igual sin push.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      debugPrint("[push] Firebase no disponible: $e");
    }
  }

  /// Con sesión iniciada (AppShell montado): permiso + token + listeners.
  static Future<void> register() async {
    if (!_ready) return;
    try {
      final fm = FirebaseMessaging.instance;
      final settings = await fm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await fm.getToken();
      if (token != null) await _sendToken(token);

      if (!_listening) {
        _listening = true;
        fm.onTokenRefresh.listen(_sendToken);
        FirebaseMessaging.onMessage.listen(_onForeground);
        FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
      }
      // La app estaba cerrada y se abrió tocando el aviso.
      final initial = await fm.getInitialMessage();
      if (initial != null) _onTap(initial);
    } catch (e) {
      debugPrint("[push] registro falló: $e");
    }
  }

  /// Al cerrar sesión (antes de borrar el token de sesión): ese celular deja
  /// de recibir los avisos de esta cuenta.
  static Future<void> unregister() async {
    final token = _token;
    if (!_ready || token == null) return;
    try {
      final session = await SessionStorage().getToken();
      await apiHttp.delete(
        Uri.parse("${AppConfig.baseUrl}${Endpoints.deviceToken}"),
        headers: {
          "Content-Type": "application/json",
          if (session != null) "Authorization": "Bearer $session",
        },
        body: jsonEncode({"token": token}),
      );
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Sin señal al cerrar sesión: el servidor limpia los tokens inválidos
      // la próxima vez que intente mandarles algo.
    }
    _token = null;
  }

  static Future<void> _sendToken(String token) async {
    _token = token;
    final session = await SessionStorage().getToken();
    if (session == null || session.isEmpty) return;
    await apiHttp.post(
      Uri.parse("${AppConfig.baseUrl}${Endpoints.deviceToken}"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $session"},
      body: jsonEncode({"token": token, "platform": "android"}),
    );
  }

  static void _onForeground(RemoteMessage msg) {
    // Mesa asignada: lo muestra el banner "¡Te toca! Ve a la mesa N" de
    // MatchReadyWatcher (con número de mesa y acceso al partido). Antes salía
    // además un toast verde con el mismo texto: dos avisos por lo mismo.
    if (msg.data["type"] == "match_on_table") {
      MatchReadyWatcher.checkNow();
      return;
    }
    final n = msg.notification;
    final ctx = DeepLinks.overlayContext;
    if (n == null || ctx == null || !ctx.mounted) return;
    showNotice(ctx, title: n.title ?? "MyTTM", body: n.body, onTap: () => _onTap(msg));
  }

  static void _onTap(RemoteMessage msg) {
    final id = msg.data["id_tournament"];
    if (id is String && id.isNotEmpty) DeepLinks.openTournament(id);
  }
}
