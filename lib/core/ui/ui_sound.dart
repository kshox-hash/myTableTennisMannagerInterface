import "package:audioplayers/audioplayers.dart";
import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Sonido corto al tocar botones, cambiar de pestaña y volver atrás
/// (assets/sounds/tap.wav: completo con su estela, solo sin el silencio inicial).
/// Se puede apagar en Ajustes ("Sonido al tocar").
class UiSound {
  UiSound._();

  static const _prefKey = "ui_sound_enabled";
  static const _asset = "sounds/tap.wav";

  /// Encendido por defecto; Ajustes lo cambia.
  static final enabled = ValueNotifier<bool>(true);

  // Tres reproductores alternados: con toques seguidos la estela (0,8 s) de
  // uno no se corta por el siguiente.
  static final _players = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  static int _next = 0;
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static bool _ready = false;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefKey) ?? true;
      for (final p in _players) {
        // Baja latencia (SoundPool en Android): sin demora al reproducir.
        await p.setPlayerMode(PlayerMode.lowLatency);
        // Se mezcla con la música de fondo en vez de cortarla.
        await p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build());
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.6);
        await p.setSource(AssetSource(_asset));
      }
      _ready = true;
    } catch (_) {
      // Sin sonido no pasa nada: la app sigue igual.
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  /// Toque. Ignora repeticiones en menos de 60 ms (un mismo gesto que
  /// dispara botón + cambio de pantalla suena una sola vez).
  static void tap() {
    if (!_ready || !enabled.value) return;
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 60) return;
    _last = now;
    final p = _players[_next++ % _players.length];
    p.stop().then((_) => p.resume()).catchError((_) {});
  }
}

/// Suena al volver a una pantalla anterior (flecha ‹ o gesto/botón atrás del
/// sistema). Solo pantallas completas, no ventanas ni paneles.
class UiSoundNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (route is PageRoute) UiSound.tap();
  }
}
