import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/ui/avatar_cache.dart";

/// Club y escudo de cada jugador, como en la web (grupos y llaves). Se sacan
/// de los datos públicos de la categoría (`players[].club_name` /
/// `club_crest_url`), que ya existen para el portal: sin tocar el backend.
class ClubCrests {
  ClubCrests._();

  /// idUser → (club, url del escudo).
  static final map = ValueNotifier<Map<String, ({String? club, String? crest})>>({});
  static final _loaded = <String>{};

  /// Pide una vez por categoría (las siguientes no hacen nada).
  static Future<void> load(String tournamentId, String categoryId) async {
    final key = "$tournamentId/$categoryId";
    if (!_loaded.add(key)) return;
    try {
      final r = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/v1/tournament/public/tournaments/$tournamentId/categories/$categoryId"),
      );
      if (r.statusCode != 200) {
        _loaded.remove(key);
        return;
      }
      final players = ((jsonDecode(r.body) as Map<String, dynamic>)["data"]?["players"] as List?) ?? const [];
      final next = Map.of(map.value);
      for (final p in players.whereType<Map<String, dynamic>>()) {
        final id = (p["id_user"] ?? "").toString();
        if (id.isEmpty) continue;
        next[id] = (club: p["club_name"] as String?, crest: p["club_crest_url"] as String?);
        AvatarCache.rememberName(id, [p["first_name"], p["last_name"]].whereType<String>().join(" "));
      }
      map.value = next;
    } catch (_) {
      _loaded.remove(key);
    }
  }

  static String? clubOf(String id) => map.value[id]?.club;
}

/// Bytes de un escudo incrustado (se decodifica una sola vez por escudo).
final _decoded = <String, Uint8List>{};
Uint8List _decode(String dataUri) =>
    _decoded.putIfAbsent(dataUri, () => base64Decode(dataUri.substring(dataUri.indexOf(",") + 1)));

/// Escudo del club del jugador (nada si no tiene club o el club no tiene escudo).
class ClubCrest extends StatelessWidget {
  final String idUser;
  final double size;
  const ClubCrest({super.key, required this.idUser, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ClubCrests.map,
      builder: (context, m, _) {
        final url = m[idUser]?.crest;
        if (url == null || url.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          // Hay escudos guardados como link y otros incrustados (data:image/...;base64,...).
          child: url.startsWith("data:")
              ? Image.memory(
                  _decode(url),
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
        );
      },
    );
  }
}

/// Línea "escudo + club" bajo el nombre del jugador (grupos y llaves).
class ClubLine extends StatelessWidget {
  final String idUser;
  final String? club;
  final TextStyle style;
  final double crestSize;
  const ClubLine({super.key, required this.idUser, this.club, required this.style, this.crestSize = 13});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ClubCrests.map,
      builder: (context, m, _) {
        final name = (club ?? "").trim().isNotEmpty ? club!.trim() : (m[idUser]?.club ?? "").trim();
        if (name.isEmpty) return const SizedBox.shrink();
        return Row(
          children: [
            ClubCrest(idUser: idUser, size: crestSize),
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          ],
        );
      },
    );
  }
}
