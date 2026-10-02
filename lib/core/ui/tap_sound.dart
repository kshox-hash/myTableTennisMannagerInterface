import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Sonido corto al tocar botones y selectores. Se puede apagar en Ajustes
/// ("Sonidos"). No corta la música que esté sonando en el teléfono
/// (mixWithOthers) y respeta el modo silencio.
class TapSound {
  TapSound._();

  static const _prefsKey = "myttm:tap_sound";
  static const _volume = 0.55;

  /// Encendido/apagado (se guarda en el teléfono).
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static AudioPool? _pool;
  static bool _loading = false;

  /// Al abrir la app: lee la preferencia y deja el sonido cargado, así el
  /// primer toque suena al instante.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {}
    await _load();
  }

  static Future<void> _load() async {
    if (_pool != null || _loading) return;
    _loading = true;
    try {
      _pool = await AudioPool.create(
        source: AssetSource("sounds/tap.wav"),
        maxPlayers: 3,
        audioContext: AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );
    } catch (_) {
      // Sin audio disponible: los botones funcionan igual, sin sonido.
    } finally {
      _loading = false;
    }
  }

  static void play() {
    if (!enabled.value) return;
    final pool = _pool;
    if (pool == null) {
      _load();
      return;
    }
    pool.start(volume: _volume).catchError((_) => () async {});
  }

  static Future<void> setEnabled(bool v) async {
    enabled.value = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, v);
    } catch (_) {}
    if (v) play();
  }
}
