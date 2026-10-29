import "package:audioplayers/audioplayers.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Música de fondo mientras hay sesión: todas las canciones de
/// assets/music/ (mp3/m4a, nombre con "_" en vez de espacios), una tras otra y en orden de nombre; al terminar
/// la última vuelve a la primera. El título que se muestra es el nombre del
/// archivo. Se pausa al salir de la app y sigue al volver; se apaga en
/// Ajustes ("Música"). Sin archivos no suena nada y la app funciona igual.
class BackgroundMusic with WidgetsBindingObserver {
  BackgroundMusic._();
  static final BackgroundMusic _i = BackgroundMusic._();

  static const _prefsKey = "myttm:bg_music";
  static const _folder = "assets/music/";
  static const _volume = 0.22;

  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  /// La canción que acaba de empezar (la barra "Sonando" la muestra unos
  /// segundos). Cambia a cada canción nueva.
  static final ValueNotifier<String?> nowPlaying = ValueNotifier(null);

  static AudioPlayer? _player;
  static List<String> _playlist = const [];
  static int _current = 0;
  static bool _active = false; // hay sesión (AppShell montado)
  static bool _observing = false;
  static bool _started = false; // ya sonó una vez (el navegador lo permitió)

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
      if (_playlist.isEmpty) {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        _playlist = manifest
            .listAssets()
            .where((a) => a.startsWith(_folder) && (a.endsWith(".mp3") || a.endsWith(".m4a")))
            .toList()
          ..sort();
      }
    } catch (e) {
      debugPrint("[BackgroundMusic] lista: $e");
    }
    debugPrint("[BackgroundMusic] canciones: $_playlist");
    if (enabled.value) await _play();
  }

  /// Primer toque en la pantalla: si la música no pudo arrancar sola (el
  /// navegador no deja sonar nada antes de que el usuario toque), arranca.
  static void userGesture() {
    if (!_active || !enabled.value || _playlist.isEmpty) return;
    if (_started) return;
    _playCurrent();
  }

  /// Sin sesión (cerrar sesión): se detiene.
  static Future<void> stop() async {
    _active = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  static AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer(playerId: "bg_music")
      ..setReleaseMode(ReleaseMode.stop)
      ..setAudioContext(AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
      ).build());
    // Terminó una canción: la siguiente.
    p.onPlayerComplete.listen((_) {
      if (_playlist.isEmpty) return;
      _current = (_current + 1) % _playlist.length;
      _playCurrent();
    });
    return _player = p;
  }

  static Future<void> _play() async {
    if (_playlist.isEmpty) return;
    final p = _ensurePlayer();
    if (p.state == PlayerState.paused) {
      try {
        await p.resume();
      } catch (_) {}
    } else if (p.state != PlayerState.playing) {
      await _playCurrent();
    }
  }

  static Future<void> _playCurrent() async {
    try {
      // AssetSource va sin el "assets/" del principio.
      await _ensurePlayer().play(AssetSource(_playlist[_current].substring("assets/".length)), volume: _volume);
      _started = true;
      nowPlaying.value = _title(_playlist[_current]);
    } catch (e) {
      // Sin el archivo o sin audio (o el navegador aún no deja): sin música;
      // userGesture lo reintenta con el primer toque.
      debugPrint("[BackgroundMusic] no pudo sonar: $e");
    }
  }

  /// "assets/music/Shakira_-_Hips.mp3" → "Shakira - Hips". Los archivos van
  /// con "_" en vez de espacios: con espacios el nombre se codifica dos veces
  /// y el navegador no encuentra la canción.
  static String _title(String asset) {
    final file = Uri.decodeComponent(asset.split("/").last).replaceAll("_", " ");
    final dot = file.lastIndexOf(".");
    return dot > 0 ? file.substring(0, dot) : file;
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
