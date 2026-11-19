import "package:flutter/material.dart";
import "package:myttmi/core/ui/premium_motion.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Vista "Partidos" ordenada por importancia:
/// MIS PARTIDOS → EN JUEGO AHORA → PRÓXIMOS → JUGADOS (los últimos 5 + "Ver todos").
/// Con buscador de jugador. Filas livianas: una línea por jugador, ganador en
/// negrita, sets a la derecha, una sola línea de contexto chica.
class SmartMatchList extends StatefulWidget {
  final String tournamentId;
  final String? categoryId;
  const SmartMatchList({super.key, required this.tournamentId, this.categoryId});

  @override
  State<SmartMatchList> createState() => _SmartMatchListState();
}

class _SmartMatchListState extends State<SmartMatchList> {
  final _api = PlayerApi();
  List<TournamentMatch>? _all;
  String? _error;
  String? _myId;
  String _q = "";
  bool _showAllPlayed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SmartMatchList old) {
    super.didUpdateWidget(old);
    if (old.categoryId != widget.categoryId) _load();
  }

  Future<void> _load() async {
    try {
      final myId = await SessionStorage().getUserId();
      // El servidor entrega de a 100: se piden todas las páginas.
      final out = <TournamentMatch>[];
      for (var offset = 0; offset < 2000; offset += 100) {
        final p = await _api.getTournamentMatchesPage(widget.tournamentId,
            categoryId: widget.categoryId, limit: 100, offset: offset);
        out.addAll(p.items);
        if (p.items.length < 100 || out.length >= p.total) break;
      }
      if (!mounted) return;
      setState(() {
        _myId = myId;
        _all = out;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  bool _done(TournamentMatch m) => m.winnerId != null || m.status == "played" || m.status == "walkover";
  bool _real(TournamentMatch m) => m.player1Id.isNotEmpty && m.player2Id.isNotEmpty && m.status != "bye";

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 40),
        Center(child: Text("No pudimos cargar los partidos.", style: AppTypography.bodyMuted)),
        TextButton(onPressed: _load, child: const Text("Reintentar")),
      ]);
    }
    final all = _all;
    if (all == null) return const Center(child: CircularProgressIndicator(color: AppColors.scorifyMint));

    final q = _q.trim().toLowerCase();
    final list = all
        .where(_real)
        .where((m) => q.isEmpty || m.player1Name.toLowerCase().contains(q) || m.player2Name.toLowerCase().contains(q))
        .toList();
    bool mine(TournamentMatch m) => _myId != null && (m.player1Id == _myId || m.player2Id == _myId);

    final myMatches = q.isEmpty ? (list.where(mine).toList()..sort((a, b) => _done(a) == _done(b) ? 0 : (_done(a) ? 1 : -1))) : <TournamentMatch>[];
    final rest = list.where((m) => !myMatches.contains(m)).toList();
    final live = rest.where((m) => !_done(m) && m.tableNumber != null).toList()
      ..sort((a, b) => (a.tableNumber ?? 0).compareTo(b.tableNumber ?? 0));
    final upcoming = rest.where((m) => !_done(m) && m.tableNumber == null).toList()
      ..sort((a, b) {
        final r = (a.round ?? 0).compareTo(b.round ?? 0);
        return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
      });
    final played = rest.where(_done).toList()..sort((a, b) => (b.playedAt ?? "").compareTo(a.playedAt ?? ""));
    final playedShown = _showAllPlayed || q.isNotEmpty ? played : played.take(5).toList();

    return RefreshIndicator(
      color: AppColors.scorifyMint,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Buscador de jugador.
          TextField(
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, color: AppColors.scorifyText),
            decoration: InputDecoration(
              hintText: "Buscar jugador",
              hintStyle: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, color: AppColors.scorifyTextFaint),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.scorifyTextMuted, size: 20),
              filled: true,
              fillColor: AppColors.scorifyCardFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Text(q.isEmpty ? "Todavía no hay partidos." : "Nadie coincide con \"$_q\".", style: AppTypography.bodyMuted)),
            ),
          if (myMatches.isNotEmpty) ...[
            _title("Mis partidos", color: AppColors.scorifyMint),
            for (final m in myMatches) _row(m, highlight: true),
          ],
          if (live.isNotEmpty) ...[
            _title("En juego ahora", dot: AppColors.scorifyNegative, count: live.length),
            for (final m in live) _row(m),
          ],
          if (upcoming.isNotEmpty) ...[
            _title("Próximos", count: upcoming.length),
            for (final m in upcoming) _row(m),
          ],
          if (played.isNotEmpty) ...[
            _title("Jugados", count: played.length),
            for (final m in playedShown) _row(m),
            if (playedShown.length < played.length)
              InkWell(
                onTap: () => setState(() => _showAllPlayed = true),
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  color: AppColors.scorifyCardFill,
                  alignment: Alignment.center,
                  child: Text("Ver todos (${played.length})",
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyMint)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _title(String text, {Color color = const Color(0xFF8EC5FF), Color? dot, int? count}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10), // 24 entre secciones
      child: Row(
        children: [
          if (dot != null) ...[
            LiveDot(color: dot),
            const SizedBox(width: 4),
          ],
          Text(text.toUpperCase(),
              style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: color)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text("$count", style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextFaint)),
          ],
        ],
      ),
    );
  }

  /// En mis partidos jugados: G (verde) / P (rojo). En los de otros, "FIN".
  Widget _resultBadge(TournamentMatch m) {
    final mineMatch = _myId != null && (m.player1Id == _myId || m.player2Id == _myId);
    if (!mineMatch) {
      return const Text("FIN",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTypography.body, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.scorifyTextFaint));
    }
    final won = m.winnerId == _myId;
    final c = won ? const Color(0xFF3DDC97) : const Color(0xFFFF6B6B);
    return Center(
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        color: c.withValues(alpha: 0.16),
        child: Text(won ? "G" : "P", style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w800, color: c)),
      ),
    );
  }

  String _context(TournamentMatch m) {
    final stage = m.groupName != null
        ? "Grupo ${m.groupName!.replaceFirst(RegExp(r"^GR-?", caseSensitive: false), "")}"
        : m.round == 0
            ? "Pre-llave"
            : "Llave";
    return "$stage · ${m.categoryType}";
  }

  Widget _row(TournamentMatch m, {bool highlight = false}) {
    final done = _done(m);
    final live = !done && m.tableNumber != null;
    // A la izquierda: mesa (en juego), "Mesa N" jugada, o vacío.
    final leftTop = live ? "${m.tableNumber}" : (done ? "" : "—");
    final leftLabel = live ? "MESA" : (done ? "" : "COLA");
    Widget player(String name, String id, int sets) {
      final won = done && m.winnerId == id;
      final lost = done && m.winnerId != null && m.winnerId != id;
      return Row(
        children: [
          Expanded(
            child: Text(
              id == _myId ? "$name (tú)" : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 14,
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
                color: lost ? AppColors.scorifyTextMuted : AppColors.scorifyText,
              ),
            ),
          ),
          // Sets: el ganador en un cuadrito lima (como la web), el perdedor apagado.
          if (done)
            Container(
              width: 26,
              height: 24,
              alignment: Alignment.center,
              color: won ? AppColors.scorifyButterfly : AppColors.scorifySurface2,
              child: CountUpText(sets,
                  style: TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: won ? AppColors.scorifyOnButterfly : AppColors.scorifyTextMuted,
                  )),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: highlight ? const Color(0xFF2B3A4F) : AppColors.scorifyCardFill,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              children: [
                // Columna de estado: número de mesa grande si se está jugando.
                SizedBox(
                  width: 40,
                  child: done
                      ? _resultBadge(m)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(leftTop,
                                style: TextStyle(
                                  fontFamily: AppTypography.display,
                                  fontSize: live ? 20 : 15,
                                  fontWeight: FontWeight.w800,
                                  color: live ? AppColors.scorifyNegative : AppColors.scorifyTextMuted,
                                  height: 1,
                                )),
                            const SizedBox(height: 2),
                            Text(leftLabel,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.scorifyTextFaint)),
                          ],
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      player(m.player1Name, m.player1Id, m.setsPlayer1),
                      const SizedBox(height: 4),
                      player(m.player2Name, m.player2Id, m.setsPlayer2),
                      const SizedBox(height: 5),
                      Text(_context(m),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextFaint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
