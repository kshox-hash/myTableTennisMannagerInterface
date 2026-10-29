import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/player_actions.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/features/player/models/tournament_match_model.dart';

const _roundLabel = {
  1: "Final",
  2: "Semifinal",
  3: "Cuartos de final",
  4: "Octavos de final",
};

String _roundTitle(int round, int totalRounds) {
  // La ronda 0 es la "pre-llave": el partido que juegan los últimos
  // clasificados para completar un cuadro que no es potencia de 2 (ej. 3 o
  // 5 clasificados) — no es una ronda del cuadro real, así que no entra en
  // el cálculo "final/semifinal/..." de las demás.
  if (round == 0) return "Pre-llave";
  final fromEnd = totalRounds - round + 1;
  return _roundLabel[fromEnd] ?? "Ronda $round";
}

/// Un lugar del cuadro: un partido que mandó el servidor o uno que todavía
/// no tiene jugadores (el servidor no manda esos, p. ej. la final antes de
/// jugarse las semis) y se dibuja como "Por definir".
class _Slot {
  final int round;
  final int number;
  final TournamentMatch? match;
  final int? nextRound;
  final int? nextNumber;
  _Slot({required this.round, required this.number, this.match, this.nextRound, this.nextNumber});

  String get key => match?.idMatch ?? "slot_${round}_$number";
}

class _RoundGroup {
  final int round;
  final List<_Slot> slots;
  _RoundGroup({required this.round, required this.slots});
}

class _ConnectorLine {
  final List<Offset> points;
  final bool decided;
  _ConnectorLine({required this.points, required this.decided});
}

/// Cuadro eliminatorio conectado (rondas + líneas), igual que en el panel
/// admin: cada ronda es una columna y cada partido queda a la altura de los
/// que lo alimentan (la pre-llave, junto al partido al que avanza). Tocar a
/// un jugador lo resalta en todos los cruces donde aparece.
class BracketTreeView extends StatefulWidget {
  final List<TournamentMatch> matches;
  const BracketTreeView({super.key, required this.matches});

  @override
  State<BracketTreeView> createState() => _BracketTreeViewState();
}

class _BracketTreeViewState extends State<BracketTreeView> {
  String? _highlightedPlayerId;
  final Map<String, GlobalKey> _matchKeys = {};
  final GlobalKey _wrapperKey = GlobalKey();
  final GlobalKey _championKey = GlobalKey();
  List<_ConnectorLine> _lines = [];

  static const _boxHeight = 104.0;
  static const _boxGap = 14.0;
  static const _step = _boxHeight + _boxGap;

  /// Todas las rondas, incluidas las que el servidor todavía no manda
  /// (partidos sin jugadores): se deducen de next_round/next_match_number.
  /// Antes la última ronda recibida se tomaba como "Final", así que con la
  /// final vacía las semis se llamaban "Final" y todo quedaba corrido.
  List<_RoundGroup> _buildRounds() {
    final slots = <String, _Slot>{};
    for (final m in widget.matches) {
      if (m.round == null) continue;
      slots["${m.round}_${m.matchNumber}"] =
          _Slot(round: m.round!, number: m.matchNumber, match: m, nextRound: m.nextRound, nextNumber: m.nextMatchNumber);
    }
    // Completa los lugares que faltan siguiendo los "avanza a…" hasta la final.
    var changed = true;
    while (changed) {
      changed = false;
      for (final s in slots.values.toList()) {
        final nr = s.nextRound;
        final nn = s.nextNumber;
        if (nr == null || nn == null || slots.containsKey("${nr}_$nn")) continue;
        // Faltante: avanza al estilo de un cuadro normal (n → ⌈n/2⌉), salvo
        // que sea la final (el único partido de su ronda).
        final sameRound = slots.values.where((x) => x.round == nr).length + 1;
        final isFinal = nn == 1 && sameRound == 1 && slots.values.where((x) => x.nextRound == nr).every((x) => x.nextNumber == 1);
        slots["${nr}_$nn"] = _Slot(
          round: nr,
          number: nn,
          nextRound: isFinal ? null : nr + 1,
          nextNumber: isFinal ? null : (nn + 1) ~/ 2,
        );
        changed = true;
      }
    }
    final byRound = <int, List<_Slot>>{};
    for (final s in slots.values) {
      byRound.putIfAbsent(s.round, () => []).add(s);
    }
    final keys = byRound.keys.toList()..sort();
    return [
      for (final r in keys) _RoundGroup(round: r, slots: byRound[r]!..sort((a, b) => a.number.compareTo(b.number))),
    ];
  }

  /// Altura (top) de cada lugar: la primera ronda del cuadro repartida
  /// pareja; las siguientes, al medio de los partidos que las alimentan; la
  /// pre-llave (ronda 0), a la altura del partido al que avanza.
  Map<String, double> _layout(List<_RoundGroup> rounds) {
    final top = <String, double>{};
    final main = rounds.where((r) => r.round >= 1).toList();
    if (main.isEmpty) {
      for (final r in rounds) {
        for (var i = 0; i < r.slots.length; i++) {
          top[r.slots[i].key] = i * _step;
        }
      }
      return top;
    }
    final base = main.first;
    for (var i = 0; i < base.slots.length; i++) {
      top[base.slots[i].key] = i * _step;
    }
    final all = [for (final r in rounds) ...r.slots];
    _Slot? target(_Slot s) =>
        s.nextRound == null ? null : all.where((x) => x.round == s.nextRound && x.number == s.nextNumber).firstOrNull;
    for (final r in main.skip(1)) {
      for (var i = 0; i < r.slots.length; i++) {
        final s = r.slots[i];
        final feeders = all.where((f) => f.round == r.round - 1 && target(f) == s && top.containsKey(f.key)).toList();
        top[s.key] = feeders.isEmpty ? i * _step * 2 : feeders.map((f) => top[f.key]!).reduce((a, b) => a + b) / feeders.length;
      }
    }
    // Pre-llave: junto al partido al que avanza, sin encimarse.
    for (final r in rounds.where((r) => r.round < 1)) {
      var last = double.negativeInfinity;
      final ordered = r.slots.toList()
        ..sort((a, b) => (top[target(a)?.key] ?? 0).compareTo(top[target(b)?.key] ?? 0));
      for (final s in ordered) {
        var y = top[target(s)?.key] ?? 0;
        if (y < last + _step) y = last + _step;
        top[s.key] = y;
        last = y;
      }
    }
    return top;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeLines());
  }

  @override
  void didUpdateWidget(covariant BracketTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeLines());
  }

  void _toggleHighlight(String? id) {
    if (id == null || id.isEmpty) return;
    setState(
      () => _highlightedPlayerId = _highlightedPlayerId == id ? null : id,
    );
  }

  void _recomputeLines() {
    if (!mounted) return;
    final wrapperBox = _wrapperKey.currentContext?.findRenderObject() as RenderBox?;
    if (wrapperBox == null) return;

    final rounds = _buildRounds();
    final lines = <_ConnectorLine>[];

    void connect(String fromKey, String toKey, bool decided) {
      final fromBox = _matchKeys[fromKey]?.currentContext?.findRenderObject() as RenderBox?;
      final toBox = _matchKeys[toKey]?.currentContext?.findRenderObject() as RenderBox?;
      if (fromBox == null || toBox == null) return;
      final fromPos = fromBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
      final toPos = toBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
      final x1 = fromPos.dx + fromBox.size.width;
      final y1 = fromPos.dy + fromBox.size.height / 2 + _cardCenterOffset;
      final x2 = toPos.dx;
      final y2 = toPos.dy + toBox.size.height / 2 + _cardCenterOffset;
      final midX = x1 + (x2 - x1) / 2;
      lines.add(_ConnectorLine(points: [Offset(x1, y1), Offset(midX, y1), Offset(midX, y2), Offset(x2, y2)], decided: decided));
    }

    // Se conecta por next_round/next_match_number (lo que manda el backend):
    // con pre-llave la cantidad de partidos de una ronda no siempre es el
    // doble de la siguiente, así que la posición sola no alcanza.
    final byRoundAndNumber = <String, _Slot>{
      for (final r in rounds)
        for (final s in r.slots) "${r.round}_${s.number}": s,
    };
    for (final r in rounds) {
      for (final s in r.slots) {
        if (s.nextRound == null || s.nextNumber == null) continue;
        final target = byRoundAndNumber["${s.nextRound}_${s.nextNumber}"];
        if (target == null) continue;
        final st = s.match?.status;
        connect(s.key, target.key, st == "played" || st == "walkover" || st == "bye");
      }
    }

    if (rounds.isNotEmpty) {
      final finalMatch = rounds.last.slots.first.match;
      if (finalMatch?.winnerId != null) {
        final fromBox = _matchKeys[finalMatch!.idMatch]?.currentContext?.findRenderObject() as RenderBox?;
        final toBox = _championKey.currentContext?.findRenderObject() as RenderBox?;
        if (fromBox != null && toBox != null) {
          final fromPos = fromBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
          final toPos = toBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
          final x1 = fromPos.dx + fromBox.size.width;
          final y1 = fromPos.dy + fromBox.size.height / 2 + _cardCenterOffset;
          final x2 = toPos.dx;
          final y2 = toPos.dy + toBox.size.height / 2;
          final midX = x1 + (x2 - x1) / 2;
          lines.add(_ConnectorLine(points: [Offset(x1, y1), Offset(midX, y1), Offset(midX, y2), Offset(x2, y2)], decided: true));
        }
      }
    }

    setState(() => _lines = lines);
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _buildRounds();
    if (rounds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Text("Todavía no hay llave para esta categoría.", style: AppTypography.bodyMuted),
      );
    }

    final totalRounds = rounds.last.round;
    final finalMatch = rounds.last.slots.first.match;
    final championId = finalMatch?.winnerId;
    final championName = championId == null
        ? null
        : (championId == finalMatch!.player1Id ? finalMatch.player1Name : finalMatch.player2Name);

    final top = _layout(rounds);
    final maxTop = top.values.fold<double>(0, (a, b) => a > b ? a : b);
    final columnHeight = maxTop + _boxHeight;
    const headerHeight = 28.0;
    final treeHeight = columnHeight + headerHeight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SizedBox(
          key: _wrapperKey,
          height: treeHeight,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _LinesPainter(_lines))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in rounds)
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: SizedBox(
                        width: 240,
                        height: treeHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: headerHeight,
                              child: Text(
                                _roundTitle(r.round, totalRounds).toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.scorifyTextMuted),
                              ),
                            ),
                            SizedBox(
                              height: columnHeight,
                              child: Stack(
                                children: [
                                  for (final s in r.slots)
                                    Positioned(
                                      top: top[s.key] ?? 0,
                                      left: 0,
                                      right: 0,
                                      child: s.match == null
                                          ? _PendingBox(key: _matchKeys.putIfAbsent(s.key, () => GlobalKey()), number: s.number, height: _boxHeight)
                                          : _MatchBox(
                                              key: _matchKeys.putIfAbsent(s.key, () => GlobalKey()),
                                              match: s.match!,
                                              height: _boxHeight,
                                              highlightedPlayerId: _highlightedPlayerId,
                                              onTapPlayer: _toggleHighlight,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (championId != null)
                    SizedBox(
                      height: treeHeight,
                      child: Center(child: _ChampionCard(key: _championKey, name: championName!)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Partido sin jugadores todavía (p. ej. la final antes de las semis).
class _PendingBox extends StatelessWidget {
  final int number;
  final double height;
  const _PendingBox({super.key, required this.number, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Partido $number",
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyTextFaint)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Panel.radius),
            child: const Column(children: [_ByeRow(tinted: false, label: "Por definir"), _ByeRow(tinted: true, label: "Por definir")]),
          ),
        ],
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final List<_ConnectorLine> lines;
  _LinesPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.decided ? const Color(0xFF7FE0F5) : const Color(0xFF1A2F39)
        ..strokeWidth = line.decided ? 2.25 : 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
      for (final p in line.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => true;
}

// Misma tarjeta que la llave de la web (MatchPlayerRows): encabezado
// "● Partido N" en verde, dos filas (la segunda un tono más oscura), inicial
// en círculo y la pastilla de sets verde para el ganador. Tocar a un jugador
// ilumina su camino por la llave.
// La tarjeta queda bajo el encabezado "Partido N" (~22 px): su centro está
// ~11 px más abajo que el centro de la caja completa.
const double _cardCenterOffset = 11;

class _MatchBox extends StatelessWidget {
  final TournamentMatch match;
  final double height;
  final String? highlightedPlayerId;
  final void Function(String? id) onTapPlayer;

  const _MatchBox({
    super.key,
    required this.match,
    required this.height,
    this.highlightedPlayerId,
    required this.onTapPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final played = match.status == "played" || match.status == "walkover";
    final isBye = match.status == "bye";
    final byePlayer1 = isBye && match.player1Id.isEmpty;
    final byePlayer2 = isBye && match.player2Id.isEmpty;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.scorifyButterfly, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("Partido ${match.matchNumber}",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.scorifyButterfly)),
              if (match.tableNumber != null && !played)
                Text("  · Mesa ${match.tableNumber}",
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Panel.radius),
            child: ColoredBox(
              color: const Color(0xEB13213B),
              child: Column(
                children: [
                  byePlayer1 || match.player1Id.isEmpty
                      ? _ByeRow(tinted: false, label: byePlayer1 ? "BYE" : "Por definir")
                      : _PlayerRow(
                          idUser: match.player1Id,
                          name: match.player1Name,
                          score: played ? match.setsPlayer1 : null,
                          isWinner: played && match.winnerId == match.player1Id,
                          highlighted: highlightedPlayerId != null && highlightedPlayerId == match.player1Id,
                          tinted: false,
                          onTap: () => onTapPlayer(match.player1Id),
                        ),
                  byePlayer2 || match.player2Id.isEmpty
                      ? _ByeRow(tinted: true, label: byePlayer2 ? "BYE" : "Por definir")
                      : _PlayerRow(
                          idUser: match.player2Id,
                          name: match.player2Name,
                          score: played ? match.setsPlayer2 : null,
                          isWinner: played && match.winnerId == match.player2Id,
                          highlighted: highlightedPlayerId != null && highlightedPlayerId == match.player2Id,
                          tinted: true,
                          onTap: () => onTapPlayer(match.player2Id),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ByeRow extends StatelessWidget {
  final bool tinted;
  final String label;
  const _ByeRow({required this.tinted, this.label = "BYE"});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: AppColors.scorifySurface2,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
          color: AppColors.scorifyTextMuted,
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String idUser;
  final String name;
  final int? score;
  final bool isWinner;
  final bool highlighted;
  final bool tinted;
  final VoidCallback onTap;

  const _PlayerRow({
    required this.idUser,
    required this.name,
    this.score,
    required this.isWinner,
    required this.highlighted,
    required this.tinted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? "?" : name.trim().substring(0, 1).toUpperCase();

    return InkWell(
      onTap: idUser.isEmpty ? null : onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF4DD2EE) : (tinted ? Colors.black.withValues(alpha: 0.15) : null),
        ),
        child: Row(
          children: [
            idUser.isEmpty
                ? Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: highlighted ? Colors.white : AppColors.scorifySurface2,
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: highlighted ? const Color(0xFF4DD2EE) : AppColors.scorifyTextMuted,
                      ),
                    ),
                  )
                : UserAvatar(userId: idUser, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.isEmpty ? "Por definir" : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 13.5,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w600,
                  color: highlighted
                      ? AppColors.scorifyOnMint
                      : name.isEmpty
                          ? AppColors.scorifyTextMuted
                          : AppColors.scorifyText,
                ),
              ),
            ),
            if (idUser.isNotEmpty)
              PlayerActions(playerId: idUser, playerName: name, color: highlighted ? AppColors.scorifyOnMint : null),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Panel.radius),
                color: highlighted
                    ? Colors.white
                    : isWinner
                        ? AppColors.scorifyButterfly
                        : AppColors.scorifySurface2,
              ),
              child: Text(
                score?.toString() ?? "-",
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? const Color(0xFF4DD2EE)
                      : isWinner
                          ? AppColors.scorifyOnButterfly
                          : AppColors.scorifyTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampionCard extends StatelessWidget {
  final String name;
  const _ChampionCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      // Campeón (estilo panel): caja oscura con filete lima, sin bloque sólido.
      decoration: panelBox(color: AppColors.scorifyButterfly),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.scorifyButterfly,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.scorifyText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
