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
      final y1 = fromPos.dy + fromBox.size.height / 2;
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
          final y1 = fromPos.dy + fromBox.size.height / 2;
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

    const boxHeight = 96.0;
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
                      padding: const EdgeInsets.only(right: 32),
                      child: SizedBox(
                        width: 190,
                        height: treeHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _roundTitle(r.round, totalRounds).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: AppTypography.caption,
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
        ..color = line.decided
            ? AppColors.scorifyMint
            : Colors.white.withOpacity(0.18)
        ..strokeWidth = line.decided ? 2 : 1.5
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
    // El rival de un bye no existe (avanzó directo) — mostrarlo como fila
    // "BYE" en vez de un nombre vacío, igual que en el panel admin.
    final byePlayer1 = isBye && match.player1Id.isEmpty;
    final byePlayer2 = isBye && match.player2Id.isEmpty;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.scorifyDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.scorifyCardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              byePlayer1
                  ? const _ByeRow()
                  : _PlayerRow(
                      idUser: match.player1Id,
                      name: match.player1Name,
                      score: played ? match.setsPlayer1 : null,
                      isWinner: match.winnerId == match.player1Id,
                      highlighted:
                          highlightedPlayerId != null &&
                          highlightedPlayerId == match.player1Id,
                      onTap: () => onTapPlayer(match.player1Id),
                    ),
              Divider(height: 1, color: Colors.white.withOpacity(0.08)),
              byePlayer2
                  ? const _ByeRow()
                  : _PlayerRow(
                      idUser: match.player2Id,
                      name: match.player2Name,
                      score: played ? match.setsPlayer2 : null,
                      isWinner: match.winnerId == match.player2Id,
                      highlighted:
                          highlightedPlayerId != null &&
                          highlightedPlayerId == match.player2Id,
                      onTap: () => onTapPlayer(match.player2Id),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ByeRow extends StatelessWidget {
  const _ByeRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        "BYE",
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
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
  final VoidCallback onTap;

  const _PlayerRow({
    required this.idUser,
    required this.name,
    this.score,
    required this.isWinner,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? "?"
        : name.trim().substring(0, 1).toUpperCase();

    return InkWell(
      onTap: idUser.isEmpty ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: highlighted ? AppColors.scorifyMint : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? Colors.white
                    : AppColors.scorifyMintDark.withOpacity(0.4),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: highlighted
                      ? AppColors.scorifyMint
                      : AppColors.scorifyText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: highlighted || isWinner
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: highlighted
                      ? AppColors.scorifyOnMint
                      : AppColors.scorifyText,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: highlighted
                    ? Colors.white
                    : (isWinner
                          ? AppColors.scorifyMint.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                score?.toString() ?? "-",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: highlighted
                      ? AppColors.scorifyMint
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
        color: AppColors.scorifyMint,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.scorifyMint.withOpacity(0.5),
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
            color: AppColors.scorifyOnMint,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.scorifyOnMint,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
