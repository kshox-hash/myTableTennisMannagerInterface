import "dart:async";

import "package:flutter/foundation.dart";

/// Coordina la pantalla de carga con el Inicio: la app (AppShell) se arma
/// por debajo de la pantalla de carga y esta se quita recién cuando el
/// Inicio terminó de traer TODO (perfil, partido, racha, grupo, árbitro).
/// Así el Inicio aparece completo, sin bloques que se cargan después.
class ShellPreload {
  ShellPreload._();

  /// Avance de la carga del Inicio (0 a 1), para la barra.
  static final ValueNotifier<double> progress = ValueNotifier(0);

  /// La pantalla de carga ya se quitó: las animaciones de entrada del Inicio
  /// esperan esto (si no, se reproducirían escondidas debajo).
  static final ValueNotifier<bool> revealed = ValueNotifier(true);

  static Completer<void> _ready = Completer<void>();
  static Future<void> get ready => _ready.future;

  /// Empieza una carga nueva (al abrir la app o al iniciar sesión).
  static void reset() {
    progress.value = 0;
    revealed.value = false;
    if (_ready.isCompleted) _ready = Completer<void>();
  }

  static void report(double v) {
    if (v > progress.value) progress.value = v;
  }

  /// El Inicio terminó (bien o con error: igual se muestra).
  static void done() {
    report(1);
    if (!_ready.isCompleted) _ready.complete();
  }
}
