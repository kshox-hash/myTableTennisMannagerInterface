import "dart:async";
import "package:myttmi/core/helpers/text_format.dart";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

class MatchDetailScreen extends StatefulWidget {
  final String matchType;
  final String matchId;

  const MatchDetailScreen({
    super.key,
    required this.matchType,
    required this.matchId,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final _api = PlayerApi();
  late Future<MatchDetail> _future;
  // Mientras el partido está en vivo (el organizador va cargando sets), se
  // refresca solo cada 20 s para seguir el marcador sin tocar nada.
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _liveTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        final m = await _future;
        final played = m.status == "played" || m.status == "walkover";
        if (!played && (m.setScores?.isNotEmpty ?? false) && mounted) _load();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _api.getMatchDetail(widget.matchType, widget.matchId);
    });
  }

  // Set cerrado = alguien llegó a 11 con 2 de ventaja (el último puede ir a medias).
  static bool _setClosed(int a, int b) =>
      (a >= 11 || b >= 11) && (a - b).abs() >= 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TopHeader(
                  title: "Detalle del partido",
                  actions: [
                    HeaderIconButton(icon: Icons.refresh_rounded, onTap: _load),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<MatchDetail>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const LoadingState();
                      }
                      if (snap.hasError) {
                        return ErrorStateView(
                          message:
                              "No pudimos cargar el partido.\n${snap.error}",
                          onRetry: _load,
                        );
                      }

                      final m = snap.data!;
                      final played =
                          m.status == "played" || m.status == "walkover";
                      final live =
                          !played && (m.setScores?.isNotEmpty ?? false);
                      final liveSets1 = live
                          ? m.setScores!
                                .where(
                                  (x) => _setClosed(x.p1, x.p2) && x.p1 > x.p2,
                                )
                                .length
                          : m.setsPlayer1;
                      final liveSets2 = live
                          ? m.setScores!
                                .where(
                                  (x) => _setClosed(x.p1, x.p2) && x.p2 > x.p1,
                                )
                                .length
                          : m.setsPlayer2;

                      return RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: () async {
                          _load();
                          await _future;
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Text(
                              m.tournamentName,
                              style: AppTypography.bodyMuted,
                            ),
                            const SizedBox(height: 2),
                            Text(m.categoryLabel, style: AppTypography.h1),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (m.groupName != null)
                                  InfoChip(label: "Grupo ${m.groupName}"),
                                if (m.round != null)
                                  InfoChip(
                                    label: m.round == 0
                                        ? matchRoundLabel(0)
                                        : "Ronda ${m.round}${m.totalRounds != null ? " de ${m.totalRounds}" : ""}",
                                  ),
                                InfoChip(label: "Partido ${m.matchNumber}"),
                                InfoChip(label: "Mejor de ${m.bestOfSets}"),
                              ],
                            ),

                            const SizedBox(height: 20),
                            if (live) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.scorifyNegative,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "EN VIVO",
                                          style: TextStyle(
                                            fontFamily: AppTypography.body,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Se actualiza solo mientras se juega",
                                      style: AppTypography.bodyMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            GlassCard(
                              variant: GlassCardVariant.elevated,
                              child: Column(
                                children: [
                                  _PlayerRow(
                                    name: m.player1Name,
                                    club: m.player1Club,
                                    seed: m.player1Seed,
                                    sets: liveSets1,
                                    setPoints: [
                                      for (final x in m.setScores ?? const [])
                                        (mine: x.p1, theirs: x.p2),
                                    ],
                                    isWinner:
                                        played &&
                                        m.winnerId != null &&
                                        m.winnerId == m.player1Id,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                                  _PlayerRow(
                                    name: m.player2Name,
                                    club: m.player2Club,
                                    seed: m.player2Seed,
                                    sets: liveSets2,
                                    setPoints: [
                                      for (final x in m.setScores ?? const [])
                                        (mine: x.p2, theirs: x.p1),
                                    ],
                                    isWinner:
                                        played &&
                                        m.winnerId != null &&
                                        m.winnerId == m.player2Id,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            GlassCard(
                              child: Column(
                                children: [
                                  _InfoRow(
                                    label: "Estado",
                                    value:
                                        matchStatusLabel[m.status] ?? m.status,
                                  ),
                                  if (m.tableNumber != null)
                                    _InfoRow(
                                      label: "Mesa asignada",
                                      value: "${m.tableNumber}",
                                    ),
                                  if (m.playedTableNumber != null)
                                    _InfoRow(
                                      label: "Mesa jugada",
                                      value: "${m.playedTableNumber}",
                                    ),
                                  if (m.refereeName != null)
                                    _InfoRow(
                                      label: "Árbitro",
                                      value: m.refereeName!,
                                    ),
                                  if (m.playedAt != null)
                                    _InfoRow(
                                      label: "Jugado",
                                      value: prettyDateTime(m.playedAt!),
                                      isLast: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

/// Fila de un jugador con sus puntos en cada set (como un marcador): el set
/// que ganó en verde, el que perdió en gris, y el que se está jugando en
/// blanco con fondo rojo suave. A la derecha, los sets ganados.
class _PlayerRow extends StatelessWidget {
  final String name;
  final String? club;
  final int? seed;
  final int sets;
  final bool isWinner;
  final List<({int mine, int theirs})> setPoints;

  const _PlayerRow({
    required this.name,
    this.club,
    this.seed,
    required this.sets,
    required this.isWinner,
    this.setPoints = const [],
  });

  static bool _closed(int a, int b) =>
      (a >= 11 || b >= 11) && (a - b).abs() >= 2;

  @override
  Widget build(BuildContext context) {
    final accent = isWinner
        ? AppColors.scorifyButterfly
        : AppColors.scorifyTextFaint;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.16),
          ),
          child: Icon(Icons.person_rounded, color: accent, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 14.5,
                  fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.scorifyText,
                ),
              ),
              if (club != null) Text(club!, style: AppTypography.bodyMuted),
              if (seed != null)
                Text("Semilla $seed", style: AppTypography.caption),
            ],
          ),
        ),
        for (final sp in setPoints)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _closed(sp.mine, sp.theirs)
                  ? Colors.transparent
                  : AppColors.scorifyNegative.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${sp.mine}",
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: !_closed(sp.mine, sp.theirs)
                    ? AppColors.scorifyText
                    : sp.mine > sp.theirs
                    ? AppColors.scorifyButterfly
                    : AppColors.scorifyTextFaint,
              ),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isWinner
                ? AppColors.scorifyButterfly
                : AppColors.scorifySurface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$sets",
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isWinner
                  ? AppColors.scorifyOnButterfly
                  : AppColors.scorifyText,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMuted),
          Text(
            value,
            style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
