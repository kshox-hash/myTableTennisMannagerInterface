import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Partidos del campeonato que se está viendo. Lo pone la pantalla de
/// Partidos (ya los tiene descargados) para que la 🏆 arme el recorrido de
/// cualquier jugador sin pedir nada nuevo al servidor.
class TournamentMatchesScope extends InheritedWidget {
  final List<TournamentMatch> matches;
  const TournamentMatchesScope({super.key, required this.matches, required super.child});

  static List<TournamentMatch>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TournamentMatchesScope>()?.matches;

  @override
  bool updateShouldNotify(TournamentMatchesScope old) => old.matches != matches;
}

/// 👁 ver perfil · 🏆 ver recorrido en el campeonato — los mismos dos
/// botones que tiene cada jugador en la web (MatchPlayerRows.tsx).
class PlayerActions extends StatelessWidget {
  final String? playerId;
  final String playerName;
  final Color? color;
  const PlayerActions({super.key, required this.playerId, required this.playerName, this.color});

  @override
  Widget build(BuildContext context) {
    final id = playerId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();
    final c = color ?? AppColors.scorifyTextMuted;
    final matches = TournamentMatchesScope.of(context);
    Widget btn(IconData icon, String tip, VoidCallback onTap) => InkResponse(
          onTap: onTap,
          radius: 18,
          child: Tooltip(message: tip, child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: c))),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.visibility_rounded, "Ver perfil",
            () => Navigator.pushNamed(context, AppRoutes.playerProfile, arguments: {"userId": id, "playerName": playerName})),
        if (matches != null)
          btn(Icons.emoji_events_rounded, "Ver recorrido", () => showPlayerJourney(context, id, playerName, matches)),
      ],
    );
  }
}

/// Recorrido de un jugador en el campeonato: por categoría, sus partidos
/// (fase, rival, marcador) y cómo le va — Campeón, En juego o Eliminado.
void showPlayerJourney(BuildContext context, String playerId, String playerName, List<TournamentMatch> all) {
  final mine = all.where((m) => m.player1Id == playerId || m.player2Id == playerId).toList();
  final byCategory = <String, List<TournamentMatch>>{};
  for (final m in mine) {
    byCategory.putIfAbsent(m.idCategory, () => []).add(m);
  }
  for (final list in byCategory.values) {
    list.sort((a, b) {
      if (a.matchType != b.matchType) return a.matchType == "group" ? -1 : 1;
      final r = (a.round ?? 0).compareTo(b.round ?? 0);
      return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
    });
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.scorifyDeep,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              UserAvatar(userId: playerId, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.h2.copyWith(fontSize: 17)),
                    Text("Recorrido en el campeonato", style: AppTypography.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (byCategory.isEmpty) Text("Todavía no tiene partidos en este campeonato.", style: AppTypography.bodyMuted),
          for (final list in byCategory.values) _JourneyCategory(playerId: playerId, matches: list),
        ],
      ),
    ),
  );
}

class _JourneyCategory extends StatelessWidget {
  final String playerId;
  final List<TournamentMatch> matches;
  const _JourneyCategory({required this.playerId, required this.matches});

  bool _won(TournamentMatch m) => m.winnerId != null && m.winnerId == playerId;

  String _stage(TournamentMatch m) {
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
    final first = matches.first;
    final played = matches.where((m) => m.winnerId != null).toList();
    final wins = played.where(_won).length;
    final lostBracket = matches.any((m) => m.matchType == "bracket" && m.winnerId != null && !_won(m));
    final pending = matches.any((m) => m.winnerId == null);
    final champion = matches.any((m) => m.matchType == "bracket" && _won(m) && m.round != null && m.round == m.totalRounds);
    final (label, bg, fg) = champion
        ? ("🏆 Campeón", AppColors.scorifyPending, AppColors.scorifyOnButterfly)
        : lostBracket
            ? ("Eliminado", AppColors.scorifySurface2, AppColors.scorifyTextMuted)
            : pending
                ? ("En juego", AppColors.scorifyLive, AppColors.scorifyOnLive)
                : ("Sin partidos pendientes", AppColors.scorifySurface2, AppColors.scorifyTextMuted);

    final category = first.categoryRange.trim().isEmpty || first.categoryRange == "General"
        ? first.categoryType
        : "${first.categoryType} ${first.categoryRange}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(category, style: AppTypography.h2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("${played.length} ${played.length == 1 ? "partido" : "partidos"} · $wins ${wins == 1 ? "victoria" : "victorias"}",
              style: AppTypography.bodyMuted),
          const SizedBox(height: 10),
          for (final m in matches)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.winnerId == null
                          ? AppColors.scorifyTextFaint
                          : (_won(m) ? AppColors.scorifyButterfly : AppColors.scorifyNegative),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 82, child: Text(_stage(m), style: AppTypography.bodyMuted.copyWith(fontSize: 12))),
                  Expanded(
                    child: Text(
                      "vs ${m.player1Id == playerId ? m.player2Name : m.player1Name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyText.copyWith(fontSize: 13.5),
                    ),
                  ),
                  Text(
                    m.winnerId == null
                        ? (m.tableNumber != null ? "Mesa ${m.tableNumber}" : "Por jugar")
                        : m.player1Id == playerId
                            ? "${m.setsPlayer1} - ${m.setsPlayer2}"
                            : "${m.setsPlayer2} - ${m.setsPlayer1}",
                    style: AppTypography.bodyText.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
