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
import 'package:myttmi/routes/app_routes.dart';

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  color: AppColors.scorifyTextMuted,
);

void _openProfile(BuildContext context, RankingEntry p) {
  Navigator.pushNamed(
    context,
    AppRoutes.playerProfile,
    arguments: {"userId": p.idUser, "playerName": p.name},
  );
}

class RankingScreen extends StatefulWidget {
  // false cuando vive embebido dentro de una sub-pestaña (p.ej. "Mi
  // rendimiento") que ya muestra su propio encabezado.
  final bool showHeader;

  const RankingScreen({super.key, this.showHeader = true});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TabAutoRefreshMixin<RankingScreen> {
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_api.getGlobal(), SessionStorage().getUserId()]);
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

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final filtered = _entries
        .where((p) => p.name.toLowerCase().contains(query) || (p.clubName ?? "").toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.rankingPosition.compareTo(b.rankingPosition));

    // El podio solo con la tabla completa (sin buscar).
    final podium = query.isEmpty ? filtered.where((p) => p.rankingPosition <= 3).toList() : <RankingEntry>[];
    final rest = query.isEmpty ? filtered.where((p) => p.rankingPosition > 3).toList() : filtered;
    final me = _entries.where((p) => p.idUser == _myUserId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              isDense: true,
              filled: true,
              fillColor: AppColors.scorifyInput,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.scorifyTextMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _error != null
                    ? ErrorStateView(message: "No pudimos cargar el ranking.\n$_error", onRetry: _load)
                    : RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (me != null) ...[
                              _MyRankCard(me: me, total: _entries.length),
                              const SizedBox(height: 16),
                            ],
                            if (filtered.isEmpty)
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.leaderboard_rounded, color: AppColors.scorifyTextMuted, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        query.isEmpty ? "Todavía no hay ranking generado." : "Nadie coincide con esa búsqueda.",
                                        style: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              if (podium.isNotEmpty) ...[
                                _PodiumRow(top3: podium, myUserId: _myUserId),
                                const SizedBox(height: 16),
                              ],
                              if (rest.isNotEmpty)
                                GlassCard(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                  child: Column(
                                    children: [for (final p in rest) _RankRow(player: p, isMe: p.idUser == _myUserId)],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Tu lugar en el ranking, arriba de todo.
class _MyRankCard extends StatelessWidget {
  final RankingEntry me;
  final int total;
  const _MyRankCard({required this.me, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipOval(child: Identicon(seed: me.idUser, size: 46)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu posición", style: _muted),
                const SizedBox(height: 2),
                Text(
                  "#${me.rankingPosition} de $total",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.scorifyButterfly, borderRadius: BorderRadius.circular(999)),
            child: Text(
              "${me.rankingPoints} pts",
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyOnButterfly),
            ),
          ),
        ],
      ),
    );
  }
}

// Podio para el top 3 — el 1° más alto y al centro.
class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> top3;
  final String? myUserId;
  const _PodiumRow({required this.top3, this.myUserId});

  RankingEntry? _at(int position) => top3.where((p) => p.rankingPosition == position).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumStep(entry: _at(2), place: 2, height: 70, color: const Color(0xFFB8C2C8))),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: _at(1), place: 1, height: 96, color: AppColors.scorifyPending)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: _at(3), place: 3, height: 56, color: const Color(0xFFC98A4B))),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final RankingEntry? entry;
  final int place;
  final double height;
  final Color color;

  const _PodiumStep({required this.entry, required this.place, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.shrink();
    final size = place == 1 ? 56.0 : 46.0;

    return InkWell(
      onTap: () => _openProfile(context, e),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: ClipOval(child: Identicon(seed: e.idUser, size: size)),
          ),
          const SizedBox(height: 8),
          Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
          ),
          Text("${e.rankingPoints} pts", style: _muted.copyWith(fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scorifyCardFill,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(top: BorderSide(color: color, width: 3)),
            ),
            child: Text(
              "$place",
              style: TextStyle(fontFamily: AppTypography.body, fontSize: 26, fontWeight: FontWeight.w600, color: color),
            ),
          ),
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
    return Material(
      color: isMe ? AppColors.scorifyMint.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openProfile(context, player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  "${player.rankingPosition}",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted),
                ),
              ),
              ClipOval(child: Identicon(seed: player.idUser, size: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? "${player.name} (tú)" : player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                    ),
                    Text(player.clubName ?? "Sin club", maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted),
                  ],
                ),
              ),
              Text(
                "${player.rankingPoints} pts",
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
