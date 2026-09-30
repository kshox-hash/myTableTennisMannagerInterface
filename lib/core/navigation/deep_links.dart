import "dart:async";

import "package:app_links/app_links.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/features/tournament/presentation/tournament_detail_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

/// Links de campeonato compartidos (https://www.myttm.cl/torneos/<id>).
///
/// Con la app instalada, Android los abre acá (App Links: intent-filter en
/// AndroidManifest + /.well-known/assetlinks.json en la web). Si el jugador
/// todavía no inició sesión, el campeonato queda pendiente y se abre apenas
/// entra al AppShell (después del login o del splash).
class DeepLinks {
  DeepLinks._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static String? _pendingTournamentId;
  static bool _shellReady = false;
  static StreamSubscription<Uri>? _sub;

  /// Se llama una vez en main(). El stream entrega también el link con que
  /// se abrió la app (arranque en frío), no solo los que llegan después.
  static void init() {
    _sub ??= AppLinks().uriLinkStream.listen(_handle, onError: (_) {});
  }

  static void _handle(Uri uri) {
    final id = tournamentIdFrom(uri);
    if (id == null) return;
    if (_shellReady) {
      _open(id);
    } else {
      _pendingTournamentId = id;
    }
  }

  /// /torneos/<id> y sus subrutas (/torneos/<id>/categorias/...) llevan al
  /// campeonato. /torneos/partidos/... es un partido suelto: no se abre.
  static String? tournamentIdFrom(Uri uri) {
    final s = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (s.length < 2 || s[0] != "torneos" || s[1] == "partidos") return null;
    return s[1];
  }

  /// AppShell montado (hay sesión): abre el campeonato pendiente, si hay.
  static void shellReady() {
    _shellReady = true;
    final id = _pendingTournamentId;
    _pendingTournamentId = null;
    if (id != null) _open(id);
  }

  static void shellGone() => _shellReady = false;

  static Future<void> _open(String id) async {
    try {
      final tournament = await TournamentApi().getTournamentById(id);
      navigatorKey.currentState?.push(
        CyberPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
      );
    } catch (_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        showToast(ctx, "No se pudo abrir el campeonato del link.", error: true);
      }
    }
  }
}
