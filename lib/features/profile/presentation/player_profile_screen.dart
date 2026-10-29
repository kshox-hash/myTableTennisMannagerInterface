import 'package:myttmi/core/ui/section_card.dart';
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/routes/app_routes.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/match_list.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/achievement_row.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/profile/api/profile_api.dart";
import "package:myttmi/features/profile/models/profile_model.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/achievement_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

class PlayerProfileScreen extends StatefulWidget {
  final String userId;
  final String? playerName;

  const PlayerProfileScreen({super.key, required this.userId, this.playerName});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _profileApi = ProfileApi();
  final _playerApi = PlayerApi();
  late Future<PublicPlayerProfile> _profileFuture;
  late Future<List<PlayerMatchHistoryItem>> _historyFuture;
  late Future<List<PlayerAchievement>> _achievementsFuture;
  // Yo (para el "Tú vs …"); null mientras se lee la sesión.
  String? _myId;

  // 200 partidos: alcanza para encontrar los enfrentamientos contigo; el
  // historial de abajo sigue mostrando los últimos 15.
  static const _historyLimit = 200;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileApi.getPublicProfile(widget.userId);
    _historyFuture = _playerApi.getPlayerMatchHistory(widget.userId, limit: _historyLimit);
    _achievementsFuture = _playerApi.getPlayerAchievements(widget.userId);
    SessionStorage().getUserId().then((id) {
      if (mounted) setState(() => _myId = id);
    });
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileApi.getPublicProfile(widget.userId);
      _historyFuture = _playerApi.getPlayerMatchHistory(widget.userId, limit: _historyLimit);
      _achievementsFuture = _playerApi.getPlayerAchievements(widget.userId);
    });
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
                TopHeader(title: widget.playerName ?? "Jugador"),
                const SizedBox(height: 14),
              ],
              body: FutureBuilder<PublicPlayerProfile>(
                    future: _profileFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                        return const LoadingState();
                      }
                      if (snap.hasError) {
                        return ErrorStateView(
                          message:
                              "No pudimos cargar este perfil.\n${snap.error}",
                          onRetry: _reload,
                        );
                      }

                      final p = snap.data!;
                      return ListView(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                UserAvatar(userId: p.idUser, url: p.avatarUrl, size: 76),
                                const SizedBox(height: 12),
                                Text(
                                  p.displayName,
                                  style: AppTypography.h1.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                if (p.club != null)
                                  Text(p.club!, style: AppTypography.bodyMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: "Jugados",
                                  value: "${p.stats.matchesPlayed}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  label: "Ganados",
                                  value: "${p.stats.matchesWon}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  label: "% Victoria",
                                  value: "${(p.stats.winRate * 100).round()}%",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Tú vs este jugador (solo si ya se enfrentaron).
                          if (_myId != null && _myId != widget.userId)
                            FutureBuilder<List<PlayerMatchHistoryItem>>(
                              future: _historyFuture,
                              builder: (context, hSnap) {
                                final vs = (hSnap.data ?? const <PlayerMatchHistoryItem>[])
                                    .where((m) => (m.status == "played" || m.status == "walkover") && (m.player1Id == _myId || m.player2Id == _myId))
                                    .toList();
                                if (vs.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _HeadToHead(matches: vs, myId: _myId!, rivalName: p.displayName),
                                );
                              },
                            ),
                          FutureBuilder<List<PlayerAchievement>>(
                            future: _achievementsFuture,
                            builder: (context, aSnap) => AchievementsCard(
                              achievements: aSnap.data ?? [],
                            ),
                          ),
                          const SectionLabel("Historial", icon: Icons.history_rounded),
                          const SizedBox(height: 10),
                          FutureBuilder<List<PlayerMatchHistoryItem>>(
                            future: _historyFuture,
                            builder: (context, hSnap) {
                              if (hSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const LoadingState();
                              }
                              final items = hSnap.data ?? [];
                              if (items.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.sports_tennis_rounded,
                                  message: "Sin partidos jugados todavía.",
                                );
                              }
                              // Desde el punto de vista de este jugador (no "Tú").
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: matchesByMonth(context, items.take(15).toList(), widget.userId),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: AppTypography.monoStrong.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

/// "Tú vs Juan": cuántas le ganaste y cuántas te ganó, y los últimos
/// enfrentamientos (del más reciente al más viejo; tocar abre el partido).
class _HeadToHead extends StatelessWidget {
  final List<PlayerMatchHistoryItem> matches;
  final String myId;
  final String rivalName;
  const _HeadToHead({required this.matches, required this.myId, required this.rivalName});

  @override
  Widget build(BuildContext context) {
    final mine = matches.where((m) => m.winnerId == myId).length;
    final theirs = matches.length - mine;
    final first = rivalName.trim().split(RegExp(r"\s+")).first;
    final lead = mine == theirs
        ? "Van empatados"
        : mine > theirs
            ? "Le llevas la delantera"
            : "$first te lleva la delantera";

    return SectionCard(
      title: "Tú vs $first",
      icon: Icons.compare_arrows_rounded,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Side(value: mine, label: "Tú", color: AppColors.scorifyButterfly),
              Expanded(
                child: Column(
                  children: [
                    Text(lead, textAlign: TextAlign.center, style: AppTypography.bodyText.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      matches.length == 1 ? "1 partido jugado" : "${matches.length} partidos jugados",
                      style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              _Side(value: theirs, label: first, color: AppColors.scorifyNegative),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Panel.fieldBorder),
          for (final m in matches.take(3)) _VsRow(match: m, myId: myId),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Side({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 70,
        child: Column(
          children: [
            Text("$value", style: TextStyle(fontFamily: AppTypography.display, fontSize: 40, height: 1, fontWeight: FontWeight.w600, color: color)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
          ],
        ),
      );
}

class _VsRow extends StatelessWidget {
  final PlayerMatchHistoryItem match;
  final String myId;
  const _VsRow({required this.match, required this.myId});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final iAmP1 = m.player1Id == myId;
    final won = m.winnerId == myId;
    final c = won ? AppColors.scorifyButterfly : AppColors.scorifyNegative;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: {"matchType": m.matchType, "matchId": m.idMatch}),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: panelBox(color: c),
              child: Text(won ? "G" : "P", style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w700, color: c)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(m.tournamentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
            ),
            Text(
              "${iAmP1 ? m.setsPlayer1 : m.setsPlayer2}-${iAmP1 ? m.setsPlayer2 : m.setsPlayer1}",
              style: const TextStyle(fontFamily: AppTypography.display, fontSize: 20, height: 1, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
            ),
          ],
        ),
      ),
    );
  }
}
