import "package:flutter/material.dart";
import "package:myttmi/core/ui/premium_motion.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/routes/app_routes.dart";

/// Vista "Partidos" ordenada por importancia:
/// MIS PARTIDOS → EN JUEGO AHORA → RESULTADOS (los últimos 5 + "Ver todos") → PRÓXIMOS.
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
  /// Filtro por etapa: null = todas, "G:nombre" = un grupo, "llave" = llave.
  String? _stage;
  /// Turno en la cola de mesas (idMatch → 1, 2, 3…).
  Map<String, int> _queue = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SmartMatchList old) {
    super.didUpdateWidget(old);
    if (old.categoryId != widget.categoryId) {
      _stage = null;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final myId = await SessionStorage().getUserId();
      final out = await _api.getAllTournamentMatches(widget.tournamentId, categoryId: widget.categoryId);
      // Cola real de mesas (si falla, se ordena por ronda y número como antes).
      var queue = <String, int>{};
      try {
        final board = await TournamentApi().getTablesQueue(widget.tournamentId);
        for (var i = 0; i < board.nextMatches.length; i++) {
          queue[board.nextMatches[i].idMatch] = i + 1;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _myId = myId;
        _all = out;
        _queue = queue;
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
    if (all == null) return const LoadingState(); // esqueleto que late (no un círculo girando)

    final q = _q.trim().toLowerCase();
    final realAll = all.where(_real).toList();
    final list = realAll
        .where(_inStage)
        .where((m) => q.isEmpty || m.player1Name.toLowerCase().contains(q) || m.player2Name.toLowerCase().contains(q))
        .toList();
    bool mine(TournamentMatch m) => _myId != null && (m.player1Id == _myId || m.player2Id == _myId);

    final myMatches = q.isEmpty ? (list.where(mine).toList()..sort((a, b) => _done(a) == _done(b) ? 0 : (_done(a) ? 1 : -1))) : <TournamentMatch>[];
    final rest = list.where((m) => !myMatches.contains(m)).toList();
    final live = rest.where((m) => !_done(m) && m.tableNumber != null).toList()
      ..sort((a, b) => (a.tableNumber ?? 0).compareTo(b.tableNumber ?? 0));
    // Próximos en el orden real de la cola; los que aún no entran a la cola, después.
    final upcoming = rest.where((m) => !_done(m) && m.tableNumber == null).toList()
      ..sort((a, b) {
        final qa = _queue[a.idMatch] ?? 1 << 20, qb = _queue[b.idMatch] ?? 1 << 20;
        if (qa != qb) return qa.compareTo(qb);
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
            style: TextStyle(fontFamily: AppTypography.body, fontSize: 14, color: AppColors.scorifyText),
            decoration: InputDecoration(
              hintText: "Buscar jugador",
              hintStyle: TextStyle(fontFamily: AppTypography.body, fontSize: 14, color: AppColors.scorifyTextFaint),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.scorifyTextMuted, size: 20),
              filled: true,
              fillColor: AppColors.scorifyCardFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
            ),
          ),
          _stageBar(realAll),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Text(q.isEmpty ? "Todavía no hay partidos." : "Nadie coincide con \"$_q\".", style: AppTypography.bodyMuted)),
            ),
          if (myMatches.isNotEmpty) ...[
            _title("Mis partidos"),
            for (final m in myMatches) _row(m, highlight: true),
          ],
          if (live.isNotEmpty) ...[
            _title("En juego ahora", dot: AppColors.scorifyNegative, count: live.length),
            for (final m in live) _row(m),
          ],
          if (played.isNotEmpty) ...[
            _title("Resultados", count: played.length),
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
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyMint)),
                ),
              ),
          ],
          if (upcoming.isNotEmpty) ...[
            _title("Próximos", count: upcoming.length),
            for (final m in upcoming) _row(m),
          ],
        ],
      ),
    );
  }

  Widget _title(String text, {Color? color, Color? dot, int? count}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10), // 24 entre secciones
      child: Row(
        children: [
          if (dot != null) ...[
            LiveDot(color: dot),
            const SizedBox(width: 4),
          ],
          Text(text.toUpperCase(),
              style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: color ?? AppColors.scorifySection)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text("$count", style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextFaint)),
          ],
        ],
      ),
    );
  }

  /// En mis partidos jugados: G (verde) / P (rojo). En los de otros, "FIN".
  Widget _resultBadge(TournamentMatch m) {
    final mineMatch = _myId != null && (m.player1Id == _myId || m.player2Id == _myId);
    if (!mineMatch) {
      return Text("FIN",
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

  String _groupShort(String g) => g.replaceFirst(RegExp(r"^GR-?", caseSensitive: false), "");

  String _context(TournamentMatch m) {
    final stage = m.groupName != null
        ? "Grupo ${_groupShort(m.groupName!)}"
        : m.round == 0
            ? "Pre-llave"
            : (m.round != null ? matchRoundLabel(m.round!, m.totalRounds) : "Llave");
    // Con una categoría elegida arriba no se repite en cada fila.
    return widget.categoryId != null ? stage : "$stage · ${m.categoryType}";
  }

  bool _inStage(TournamentMatch m) {
    final st = _stage;
    if (st == null) return true;
    if (st == "llave") return m.groupName == null;
    return m.groupName != null && "G:${m.groupName}" == st;
  }

  /// Filtro por grupo (solo con una categoría elegida y más de una etapa):
  /// barra negra con filete, como los demás filtros.
  Widget _stageBar(List<TournamentMatch> real) {
    final groups = <String>{for (final m in real) if (m.groupName != null) m.groupName!}.toList()
      ..sort((a, b) {
        final na = int.tryParse(_groupShort(a)), nb = int.tryParse(_groupShort(b));
        return (na != null && nb != null) ? na.compareTo(nb) : a.compareTo(b);
      });
    final hasBracket = real.any((m) => m.groupName == null);
    final opts = <(String?, String)>[
      (null, "Todos"),
      for (final g in groups) ("G:$g", "Grupo ${_groupShort(g)}"),
      if (hasBracket) ("llave", "Llave"),
    ];
    if (widget.categoryId == null || opts.length <= 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(color: AppColors.scorifyCardFill, border: Border.all(color: AppColors.scorifyHairline)),
          child: Row(
            children: [
              for (var i = 0; i < opts.length; i++) ...[
                if (i > 0) Container(width: 1, height: 18, color: AppColors.scorifyHairline),
                InkWell(
                  onTap: () => setState(() => _stage = opts[i].$1),
                  child: Container(
                    height: 38,
                    constraints: const BoxConstraints(minWidth: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _stage == opts[i].$1 ? AppColors.scorifySelected : Colors.transparent,
                      border: _stage == opts[i].$1
                          ? Border(bottom: BorderSide(color: AppColors.scorifyMint, width: 2))
                          : null,
                    ),
                    child: Text(
                      opts[i].$2,
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13,
                        fontWeight: _stage == opts[i].$1 ? FontWeight.w700 : FontWeight.w600,
                        color: _stage == opts[i].$1 ? AppColors.scorifyInk : AppColors.scorifyTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(TournamentMatch m, {bool highlight = false}) {
    final done = _done(m);
    final live = !done && m.tableNumber != null;
    // A la izquierda: mesa (en juego), "Mesa N" jugada, o vacío.
    final turn = _queue[m.idMatch];
    Widget player(String name, String id, int sets, int side) {
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
          // Puntos de cada set (como un marcador): blanco el set que ganó
          // este jugador, gris el que perdió.
          if (done)
            for (final sc in m.setScores)
              SizedBox(
                width: 24,
                child: Text(
                  "${side == 1 ? sc.$1 : sc.$2}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: (side == 1 ? sc.$1 > sc.$2 : sc.$2 > sc.$1) ? AppColors.scorifyInk : AppColors.scorifyTextFaint,
                  ),
                ),
              ),
          if (done && m.setScores.isNotEmpty) const SizedBox(width: 6),
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
        color: highlight ? (AppColors.isLight ? const Color(0xFFF1F8FA) : (AppColors.isLight ? const Color(0xFFF1F8FA) : const Color(0xFF1C2738))) : AppColors.scorifyCardFill,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              children: [
                // A la izquierda solo lo que importa: la mesa si se está
                // jugando, o G/P/FIN si ya terminó. Por jugar: nada (antes
                // decía "#12 COLA" / "— COLA" y no se entendía).
                if (live) ...[
                  SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("MESA",
                            style: TextStyle(fontFamily: AppTypography.body, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.scorifyNegative)),
                        const SizedBox(height: 2),
                        Text("${m.tableNumber}",
                            style: TextStyle(fontFamily: AppTypography.display, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.scorifyInk, height: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (done) ...[
                  SizedBox(width: 40, child: _resultBadge(m)),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      player(m.player1Name, m.player1Id, m.setsPlayer1, 1),
                      const SizedBox(height: 4),
                      player(m.player2Name, m.player2Id, m.setsPlayer2, 2),
                      const SizedBox(height: 5),
                      Text(_context(m),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextFaint)),
                    ],
                  ),
                ),
                if (!done && !live && turn != null) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TURNO",
                          style: TextStyle(fontFamily: AppTypography.body, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.scorifyTextFaint)),
                      const SizedBox(height: 2),
                      Text("$turn",
                          style: TextStyle(fontFamily: AppTypography.display, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scorifyTextMuted, height: 1)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
