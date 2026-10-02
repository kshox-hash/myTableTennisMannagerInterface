import "package:audioplayers/audioplayers.dart";
import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Música de fondo (en loop, volumen bajo) mientras hay sesión abierta. Se
/// pausa al salir de la app y sigue al volver. Se apaga en Ajustes
/// ("Música"). Si el archivo no está (assets/sounds/bg_music.mp3), no suena
/// nada y la app funciona igual.
class BackgroundMusic with WidgetsBindingObserver {
  BackgroundMusic._();
  static final BackgroundMusic _i = BackgroundMusic._();

  static const _prefsKey = "myttm:bg_music";
  static const _asset = "sounds/bg_music.mp3";
  static const _volume = 0.22;

  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static AudioPlayer? _player;
  static bool _active = false; // hay sesión (AppShell montado)
  static bool _observing = false;

  /// AppShell montado: empieza a sonar (si está encendida).
  static Future<void> start() async {
    _active = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(_i);
      _observing = true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {}
    if (enabled.value) await _play();
  }

  /// Sin sesión (cerrar sesión): se detiene.
  static Future<void> stop() async {
    _active = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  static Future<void> _play() async {
    try {
      final p = _player ??= AudioPlayer(playerId: "bg_music")
        ..setReleaseMode(ReleaseMode.loop)
        ..setAudioContext(AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build());
      if (p.state == PlayerState.paused) {
        await p.resume();
      } else {
        await p.play(AssetSource(_asset), volume: _volume);
      }
    } catch (_) {
      // Sin el archivo o sin audio: sin música.
    }
  }

  static Future<void> _pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  static Future<void> setEnabled(bool v) async {
    enabled.value = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, v);
    } catch (_) {}
    if (v && _active) {
      await _play();
    } else {
      await _pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active || !enabled.value) return;
    if (state == AppLifecycleState.resumed) {
      _play();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pause();
    }
  }
}
