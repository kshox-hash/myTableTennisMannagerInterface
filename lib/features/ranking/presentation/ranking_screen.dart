import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/glass_card.dart';
import 'package:myttmi/core/ui/identicon.dart';
import 'package:myttmi/core/ui/list_states.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/features/ranking/api/ranking_api.dart';
import 'package:myttmi/features/ranking/models/ranking_model.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';

class RankingScreen extends StatefulWidget {
  // false cuando vive embebido dentro de una sub-pestaña (p.ej. "Mi
  // rendimiento") que ya muestra su propio encabezado.
  final bool showHeader;

  const RankingScreen({super.key, this.showHeader = true});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with TabAutoRefreshMixin<RankingScreen> {
  @override
  int get tabIndex => 2;

  @override
  void onTabActivated() => _load();

  final TextEditingController _search = TextEditingController();
  final _api = RankingApi();

  List<RankingEntry> _entries = [];
  String? _myUserId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getGlobal(),
        SessionStorage().getUserId(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<RankingEntry>;
        _myUserId = results[1] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _sumMatches(List<RankingEntry> list) =>
      list.fold(0, (acc, p) => acc + p.matchesPlayed);
  int _sumPoints(List<RankingEntry> list) =>
      list.fold(0, (acc, p) => acc + p.rankingPoints);

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();

    final filtered =
        _entries
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query) ||
                  (p.clubName ?? "").toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.rankingPosition.compareTo(b.rankingPosition));

    // El podio solo tiene sentido con la tabla completa (sin filtrar) — al
    // buscar, se oculta y queda solo la lista.
    final podium = query.isEmpty
        ? filtered.where((p) => p.rankingPosition <= 3).toList()
        : <RankingEntry>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.showHeader) ...[
            const TopHeader(title: "Ranking", showBack: false),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyText,
            decoration: InputDecoration(
              hintText: "Buscar jugador o club",
              hintStyle: AppTypography.bodyMuted,
              filled: true,
              fillColor: AppColors.scorifyCardFill,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.scorifyTextMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.scorifyCardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.scorifyMint,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _error != null
                ? ErrorStateView(
                    message: "No pudimos cargar el ranking.\n$_error",
                    onRetry: _load,
                  )
                : RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _load,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _RankingHeaderCard(
                          totalPlayers: filtered.length,
                          totalMatches: _sumMatches(filtered),
                          totalPoints: _sumPoints(filtered),
                        ),
                        const SizedBox(height: 16),
                        if (podium.isNotEmpty) ...[
                          _PodiumRow(top3: podium),
                          const SizedBox(height: 16),
                        ],
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: EmptyState(
                              icon: Icons.leaderboard_rounded,
                              message: "Todavía no hay ranking generado.",
                            ),
                          )
                        else
                          ...filtered.map(
                            (p) => _RankRow(
                              player: p,
                              isMe: p.idUser == _myUserId,
                            ),
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

class _RankingHeaderCard extends StatelessWidget {
  final int totalPlayers;
  final int totalMatches;
  final int totalPoints;

  const _RankingHeaderCard({
    required this.totalPlayers,
    required this.totalMatches,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.scorifyMint,
              ),
              const SizedBox(width: 10),
              Text("Ranking Global", style: AppTypography.h1),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(label: "Jugadores", value: totalPlayers.toString()),
              _MiniStat(label: "Partidos", value: totalMatches.toString()),
              _MiniStat(label: "Puntos", value: totalPoints.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

// Podio visual para el top 3 — antes era una fila más de la lista plana,
// igual de destacada que el puesto #47. El 1° va más alto y al centro,
// como en un podio real, con medalla + Identicon.
class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> top3;
  const _PodiumRow({required this.top3});

  RankingEntry? _at(int position) {
    for (final p in top3) {
      if (p.rankingPosition == position) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumStep(entry: second, medal: "🥈", height: 96),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumStep(entry: first, medal: "🥇", height: 124),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumStep(entry: third, medal: "🥉", height: 80),
        ),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final RankingEntry? entry;
  final String medal;
  final double height;

  const _PodiumStep({
    required this.entry,
    required this.medal,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.shrink();

    final isFirst = medal == "🥇";
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Identicon(seed: e.idUser, size: isFirst ? 52 : 42),
        const SizedBox(height: 6),
        Text(
          e.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          "${e.rankingPoints} pts",
          style: AppTypography.caption.copyWith(
            color: AppColors.scorifyTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 10),
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: AppColors.scorifyMint.withOpacity(isFirst ? 0.18 : 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(
              color: AppColors.scorifyMint.withOpacity(isFirst ? 0.5 : 0.28),
            ),
          ),
          child: Text(medal, style: const TextStyle(fontSize: 22)),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.monoStrong.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankingEntry player;
  final bool isMe;

  const _RankRow({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        fillColor: isMe ? AppColors.scorifyMint.withOpacity(0.14) : null,
        borderColor: isMe ? AppColors.scorifyMint.withOpacity(0.45) : null,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                "#${player.rankingPosition}",
                style: AppTypography.monoStrong,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    player.clubName ?? "Sin club",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMuted,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "${player.rankingPoints} pts",
                style: AppTypography.caption.copyWith(
                  color: AppColors.scorifyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
