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

class _RoundGroup {
  final int round;
  final List<TournamentMatch> matches;
  _RoundGroup({required this.round, required this.matches});
}

class _ConnectorLine {
  final List<Offset> points;
  final bool decided;
  _ConnectorLine({required this.points, required this.decided});
}

/// Cuadro eliminatorio conectado (rondas + líneas), igual que en el panel
/// admin: cada ronda es una columna, las líneas se calculan a partir de la
/// posición real (post-layout) de cada card en vez de una fórmula, y tocar
/// a un jugador lo resalta en todos los cruces donde aparece.
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

  List<_RoundGroup> _buildRounds() {
    final byRound = <int, List<TournamentMatch>>{};
    for (final m in widget.matches) {
      // round == 0 es la pre-llave — sí se muestra, es un partido real.
      if (m.round == null) continue;
      byRound.putIfAbsent(m.round!, () => []).add(m);
    }
    final keys = byRound.keys.toList()..sort();
    return [
      for (final r in keys)
        _RoundGroup(
          round: r,
          matches: byRound[r]!
            ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber)),
        ),
    ];
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
    if (id == null) return;
    setState(
      () => _highlightedPlayerId = _highlightedPlayerId == id ? null : id,
    );
  }

  void _recomputeLines() {
    if (!mounted) return;
    final wrapperBox =
        _wrapperKey.currentContext?.findRenderObject() as RenderBox?;
    if (wrapperBox == null) return;

    final rounds = _buildRounds();
    final lines = <_ConnectorLine>[];

    void connect(String fromId, String toId, bool decided) {
      final fromBox =
          _matchKeys[fromId]?.currentContext?.findRenderObject() as RenderBox?;
      final toBox =
          _matchKeys[toId]?.currentContext?.findRenderObject() as RenderBox?;
      if (fromBox == null || toBox == null) return;
      final fromPos = fromBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
      final toPos = toBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
      final x1 = fromPos.dx + fromBox.size.width;
      final y1 = fromPos.dy + fromBox.size.height / 2 + _cardCenterOffset;
      final x2 = toPos.dx;
      final y2 = toPos.dy + toBox.size.height / 2 + _cardCenterOffset;
      final midX = x1 + (x2 - x1) / 2;
      lines.add(
        _ConnectorLine(
          points: [
            Offset(x1, y1),
            Offset(midX, y1),
            Offset(midX, y2),
            Offset(x2, y2),
          ],
          decided: decided,
        ),
      );
    }

    // Se conecta por next_round/next_match_number (lo que manda el backend)
    // en vez de emparejar por posición: con pre-llave (ronda 0) la cantidad
    // de partidos de una ronda no siempre es el doble de la siguiente, así
    // que la posición sola no alcanza para saber a qué partido avanza cada
    // ganador.
    final byRoundAndNumber = <String, TournamentMatch>{
      for (final r in rounds)
        for (final m in r.matches) "${r.round}_${m.matchNumber}": m,
    };
    for (final r in rounds) {
      for (final m in r.matches) {
        if (m.nextRound == null || m.nextMatchNumber == null) continue;
        final target = byRoundAndNumber["${m.nextRound}_${m.nextMatchNumber}"];
        if (target == null) continue;
        connect(
          m.idMatch,
          target.idMatch,
          m.status == "played" || m.status == "walkover" || m.status == "bye",
        );
      }
    }

    if (rounds.isNotEmpty) {
      final finalMatch = rounds.last.matches.first;
      if (finalMatch.winnerId != null) {
        final fromBox =
            _matchKeys[finalMatch.idMatch]?.currentContext?.findRenderObject()
                as RenderBox?;
        final toBox =
            _championKey.currentContext?.findRenderObject() as RenderBox?;
        if (fromBox != null && toBox != null) {
          final fromPos = fromBox.localToGlobal(
            Offset.zero,
            ancestor: wrapperBox,
          );
          final toPos = toBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
          final x1 = fromPos.dx + fromBox.size.width;
          final y1 = fromPos.dy + fromBox.size.height / 2 + _cardCenterOffset;
          final x2 = toPos.dx;
          final y2 = toPos.dy + toBox.size.height / 2;
          final midX = x1 + (x2 - x1) / 2;
          lines.add(
            _ConnectorLine(
              points: [
                Offset(x1, y1),
                Offset(midX, y1),
                Offset(midX, y2),
                Offset(x2, y2),
              ],
              decided: true,
            ),
          );
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
        child: Text(
          "Todavía no hay llave para esta categoría.",
          style: AppTypography.bodyMuted,
        ),
      );
    }

    final totalRounds = rounds.last.round;
    final finalMatch = rounds.last.matches.first;
    final championId = finalMatch.winnerId;
    final championName = championId == null
        ? null
        : (championId == finalMatch.player1Id
              ? finalMatch.player1Name
              : finalMatch.player2Name);

    const boxHeight = 104.0;
    const boxGap = 14.0;
    // La ronda más ancha no es necesariamente la primera de la lista: con
    // pre-llave, la ronda 0 puede tener más partidos que la ronda 1.
    final maxMatchCount = rounds
        .map((r) => r.matches.length)
        .reduce((a, b) => a > b ? a : b);
    final treeHeight = maxMatchCount * (boxHeight + boxGap) + 34;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SizedBox(
          key: _wrapperKey,
          height: treeHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _LinesPainter(_lines)),
              ),
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
                            Text(
                              _roundTitle(r.round, totalRounds).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.scorifyTextMuted),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  for (final m in r.matches)
                                    _MatchBox(
                                      key: _matchKeys.putIfAbsent(
                                        m.idMatch,
                                        () => GlobalKey(),
                                      ),
                                      match: m,
                                      height: boxHeight,
                                      highlightedPlayerId: _highlightedPlayerId,
                                      onTapPlayer: _toggleHighlight,
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
                      child: Center(
                        child: _ChampionCard(
                          key: _championKey,
                          name: championName!,
                        ),
                      ),
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
            borderRadius: BorderRadius.circular(2),
            child: ColoredBox(
              color: const Color(0xEB1C3440),
              child: Column(
                children: [
                  byePlayer1
                      ? const _ByeRow(tinted: false)
                      : _PlayerRow(
                          idUser: match.player1Id,
                          name: match.player1Name,
                          score: played ? match.setsPlayer1 : null,
                          isWinner: played && match.winnerId == match.player1Id,
                          highlighted: highlightedPlayerId != null && highlightedPlayerId == match.player1Id,
                          tinted: false,
                          onTap: () => onTapPlayer(match.player1Id),
                        ),
                  byePlayer2
                      ? const _ByeRow(tinted: true)
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
  const _ByeRow({required this.tinted});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: AppColors.scorifySurface2,
      child: const Text(
        "BYE",
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
          color: highlighted ? null : (tinted ? Colors.black.withValues(alpha: 0.15) : null),
          gradient: highlighted ? const LinearGradient(colors: [Color(0xFF7FE0F5), Color(0xFF4DD2EE)]) : null,
        ),
        child: Row(
          children: [
            Container(
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
            ),
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
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
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
      decoration: BoxDecoration(
        color: AppColors.scorifyButterfly,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: AppColors.scorifyButterfly.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.scorifyOnButterfly,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.scorifyOnButterfly,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
