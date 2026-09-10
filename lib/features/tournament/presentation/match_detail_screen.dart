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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _api.getMatchDetail(widget.matchType, widget.matchId);
    });
  }

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
                const TopHeader(title: "Detalle del partido"),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<MatchDetail>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
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

                      return ListView(
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
                          GlassCard(
                            variant: GlassCardVariant.elevated,
                            child: Column(
                              children: [
                                _PlayerRow(
                                  name: m.player1Name,
                                  club: m.player1Club,
                                  seed: m.player1Seed,
                                  sets: m.setsPlayer1,
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
                                  sets: m.setsPlayer2,
                                  isWinner:
                                      played &&
                                      m.winnerId != null &&
                                      m.winnerId == m.player2Id,
                                ),
                              ],
                            ),
                          ),

                          if (m.setScores != null &&
                              m.setScores!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text("Sets", style: AppTypography.h2),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: m.setScores!
                                  .map(
                                    (s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.scorifyCardFill,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.scorifyCardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        "${s.p1}-${s.p2}",
                                        style: AppTypography.mono14,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          const SizedBox(height: 20),
                          GlassCard(
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: "Estado",
                                  value: matchStatusLabel[m.status] ?? m.status,
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
                                    value: m.playedAt!,
                                    isLast: true,
                                  ),
                              ],
                            ),
                          ),
                        ],
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

class _PlayerRow extends StatelessWidget {
  final String name;
  final String? club;
  final int? seed;
  final int sets;
  final bool isWinner;

  const _PlayerRow({
    required this.name,
    this.club,
    this.seed,
    required this.sets,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isWinner
        ? AppColors.scorifyMint
        : AppColors.scorifyTextFaint;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.16),
            border: Border.all(color: accent.withOpacity(0.5)),
          ),
          child: Icon(Icons.person_rounded, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: isWinner ? AppTypography.h1 : AppTypography.bodyText,
              ),
              if (club != null) Text(club!, style: AppTypography.bodyMuted),
              if (seed != null)
                Text("Semilla $seed", style: AppTypography.caption),
            ],
          ),
        ),
        Text(
          "$sets",
          style: AppTypography.displayMd.copyWith(
            color: isWinner ? AppColors.scorifyMint : AppColors.scorifyText,
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
