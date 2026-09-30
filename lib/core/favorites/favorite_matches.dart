import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Un partido guardado con el corazón: tipo (group | bracket) + id.
@immutable
class FavoriteMatch {
  final String matchType;
  final String matchId;
  const FavoriteMatch(this.matchType, this.matchId);

  Map<String, String> toJson() => {"t": matchType, "id": matchId};
  static FavoriteMatch fromJson(Map<String, dynamic> j) => FavoriteMatch(j["t"].toString(), j["id"].toString());

  @override
  bool operator ==(Object other) => other is FavoriteMatch && other.matchType == matchType && other.matchId == matchId;
  @override
  int get hashCode => Object.hash(matchType, matchId);
}

/// Partidos guardados para seguirlos en vivo ("Partidos guardados", el
/// corazón del Inicio). Viven en el celular (SharedPreferences), no en el
/// servidor. Máximo [max]; al terminar un partido la pantalla lo saca solo.
class FavoriteMatches {
  FavoriteMatches._();

  static const max = 10;
  static const _key = "myttm:favorite_matches";
  static const _viewKey = "myttm:favorite_matches_view";

  /// Lista actual (más reciente al final). Los corazones y el contador del
  /// Inicio escuchan esto para actualizarse al tiro.
  static final ValueNotifier<List<FavoriteMatch>> items = ValueNotifier(const []);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      items.value = (jsonDecode(raw) as List).map((e) => FavoriteMatch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  static bool contains(String type, String id) => items.value.contains(FavoriteMatch(type, id));

  /// Agrega o quita. Devuelve false si se quiso agregar y ya había [max].
  static Future<bool> toggle(String type, String id) async {
    final f = FavoriteMatch(type, id);
    final list = [...items.value];
    if (list.contains(f)) {
      list.remove(f);
    } else {
      if (list.length >= max) return false;
      list.add(f);
    }
    await _save(list);
    return true;
  }

  static Future<void> remove(FavoriteMatch f) async {
    if (!items.value.contains(f)) return;
    await _save(items.value.where((x) => x != f).toList());
  }

  static Future<void> _save(List<FavoriteMatch> list) async {
    items.value = List.unmodifiable(list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  /// Cuántos se ven a la vez en la pantalla de guardados (2, 4 o 6).
  static Future<int> getView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_viewKey) ?? 2;
      return const [2, 4, 6].contains(v) ? v : 2;
    } catch (_) {
      return 2;
    }
  }

  static Future<void> setView(int v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_viewKey, v);
    } catch (_) {}
  }
}
