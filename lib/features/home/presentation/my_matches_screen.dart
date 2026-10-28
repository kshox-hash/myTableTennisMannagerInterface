import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Todos mis partidos de los campeonatos en curso (se abre desde "Ver todos
/// mis partidos" del Inicio, cuando hay más de uno por jugar): primero los
/// que están en mesa, después los que esperan y al final los jugados, cada
/// uno con su categoría y fase.
class MyMatchesScreen extends StatefulWidget {
  final String myUserId;
  final List<String> tournamentIds;
  const MyMatchesScreen({super.key, required this.myUserId, required this.tournamentIds});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  final _api = PlayerApi();
  late Future<List<TournamentMatch>> _future = _load();

  Future<List<TournamentMatch>> _load() async {
    final lists = await Future.wait(widget.tournamentIds.map(_api.getTournamentMatches));
    return [
      for (final l in lists)
        for (final m in l)
          if (m.player1Id == widget.myUserId || m.player2Id == widget.myUserId) m,
    ];
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScrollingHeaderPage(
              header: [
                const SizedBox(height: 16),
                const TopHeader(title: "Mis partidos"),
                const SizedBox(height: 14),
              ],
              body: FutureBuilder<List<TournamentMatch>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) return const LoadingState();
                      if (snap.hasError) {
                        return ErrorStateView(message: "No pudimos cargar tus partidos.\n${snap.error}", onRetry: _refresh);
                      }
                      final all = snap.data ?? const <TournamentMatch>[];
                      final onTable = all.where((m) => m.winnerId == null && m.tableNumber != null).toList();
                      final waiting = all.where((m) => m.winnerId == null && m.tableNumber == null).toList();
                      final played = all.where((m) => m.winnerId != null).toList()
                        ..sort((a, b) => (b.playedAt ?? "").compareTo(a.playedAt ?? ""));
                      if (all.isEmpty) {
                        return const EmptyState(icon: Icons.sports_tennis_rounded, message: "No tienes partidos en tus campeonatos en curso.");
                      }
                      return RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (onTable.isNotEmpty) ..._section("Ahora en mesa", onTable),
                            if (waiting.isNotEmpty) ..._section("Por jugar", waiting),
                            if (played.isNotEmpty) ..._section("Jugados", played),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _section(String title, List<TournamentMatch> matches) => [
        SectionLabel("$title (${matches.length})"),
        const SizedBox(height: 10),
        for (final m in matches) _MatchRow(match: m, myUserId: widget.myUserId),
        const SizedBox(height: 18),
      ];
}

class _MatchRow extends StatelessWidget {
  final TournamentMatch match;
  final String myUserId;
  const _MatchRow({required this.match, required this.myUserId});

  String get _stage {
    final m = match;
    if (m.matchType == "group") {
      final g = (m.groupName ?? "").replaceFirst(RegExp(r"^GR-?", caseSensitive: false), "");
      return g.isEmpty ? "Grupo" : "Grupo $g";
    }
    final r = m.round ?? 0, total = m.totalRounds ?? 0;
    if (total > 0 && r == total) return "Final";
    if (total > 0 && r == total - 1) return "Semifinal";
    if (total > 0 && r == total - 2) return "Cuartos";
    return matchRoundLabel(r);
  }

  @override
  Widget build(BuildContext context) {
    final m = match;
    final iAm1 = m.player1Id == myUserId;
    final rivalId = iAm1 ? m.player2Id : m.player1Id;
    final rival = iAm1 ? m.player2Name : m.player1Name;
    final played = m.winnerId != null;
    final won = m.winnerId == myUserId;
    final category = m.categoryRange.trim().isEmpty || m.categoryRange == "General" ? m.categoryType : "${m.categoryType} ${m.categoryRange}";

    final (badge, badgeBg, badgeFg) = played
        ? ("${iAm1 ? m.setsPlayer1 : m.setsPlayer2} - ${iAm1 ? m.setsPlayer2 : m.setsPlayer1}",
            won ? AppColors.scorifyButterfly : AppColors.scorifyNegative,
            won ? AppColors.scorifyOnButterfly : Colors.white)
        : m.tableNumber != null
            ? ("Mesa ${m.tableNumber}", AppColors.scorifyLive, AppColors.scorifyOnLive)
            : ("En cola", AppColors.scorifySurface2, AppColors.scorifyTextMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(userId: rivalId, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("vs $rival", maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text("$category · $_stage", maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99)),
                  child: Text(badge, style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w700, color: badgeFg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
