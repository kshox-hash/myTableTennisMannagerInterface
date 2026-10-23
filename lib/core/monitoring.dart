import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:myttmi/core/push/push_service.dart";

/// Reportes de errores (Crashlytics) y estadísticas de uso (Analytics), los
/// dos de Firebase — que ya está en la app por las notificaciones. Sin esto,
/// si la app se cae en el celular de un jugador nadie se entera.
///
/// Solo en Android/iOS y con Firebase listo (PushService.init, antes); en
/// debug no se envía nada, para no mezclar los errores de desarrollo con los
/// de los usuarios.
class Monitoring {
  Monitoring._();

  static bool get _enabled => !kIsWeb && PushService.firebaseReady;

  /// En main(), después de PushService.init() y antes de runApp.
  static Future<void> init() async {
    if (!_enabled) return;
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

    // Errores de Flutter (al armar/pintar pantallas) y los asíncronos que
    // no atrapó nadie.
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Para MaterialApp.navigatorObservers: registra qué pantallas se abren
  /// (las rutas con nombre, ver app_routes.dart).
  static List<NavigatorObserver> get observers =>
      _enabled ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)] : const [];

  /// Asocia los reportes al usuario (solo el id, nunca el email).
  static void setUser(String? idUser) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.setUserIdentifier(idUser ?? "");
    FirebaseAnalytics.instance.setUserId(id: idUser);
  }

  /// Eventos clave del embudo (registro, inscripción…).
  static void log(String event, [Map<String, Object>? params]) {
    if (!_enabled) return;
    FirebaseAnalytics.instance.logEvent(name: event, parameters: params);
  }
}
