import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/match_history_row.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// Historial con scroll infinito: de a 30 partidos, los siguientes al llegar
// al final. Antes pedía los últimos 50 y no había forma de ver más atrás
// (quien juega todos los fines de semana los junta en un par de meses).
class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 30;
  final _api = PlayerApi();
  final _scroll = ScrollController();
  final List<PlayerMatchHistoryItem> _items = [];
  String? _myId;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _myId ??= await SessionStorage().getUserId();
    setState(() {
      _items.clear();
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    final id = _myId;
    if (_loading || !_hasMore || id == null || id.isEmpty) {
      if (id == null || id.isEmpty) setState(() => _hasMore = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.getPlayerMatchHistory(id, limit: _pageSize, offset: _items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const TopHeader(title: "Historial"),
                const SizedBox(height: 14),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const LoadingState();
    if (_items.isEmpty && _error != null) {
      return ListView(children: [ErrorStateView(message: "No pudimos cargar tu historial.\n$_error", onRetry: _refresh)]);
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(icon: Icons.history_rounded, message: "Todavía no has jugado ningún partido."),
          ),
        ],
      );
    }
    final myId = _myId;
    return RefreshIndicator(
      color: AppColors.scorifyMint,
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i == _items.length) {
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint))),
              );
            }
            if (_error != null) return TextButton(onPressed: _loadMore, child: const Text("No se pudieron cargar más. Reintentar"));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  _hasMore ? "" : "${_items.length} partidos jugados",
                  style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 12.5),
                ),
              ),
            );
          }
          final m = _items[i];
          final isP1 = m.player1Id == myId;
          final won = myId != null && m.winnerId == myId;
          return MatchHistoryRow(
            opponentName: "vs ${isP1 ? m.player2Name : m.player1Name}",
            opponentId: isP1 ? m.player2Id : m.player1Id,
            meta: [
              m.tournamentName,
              m.categoryLabel,
              if (m.groupName != null) "Grupo ${m.groupName}",
              if (m.round != null) matchRoundLabel(m.round!),
              matchStatusLabel[m.status] ?? m.status,
            ].join(" · "),
            won: won,
            scoreText: "${isP1 ? m.setsPlayer1 : m.setsPlayer2}-${isP1 ? m.setsPlayer2 : m.setsPlayer1}",
          );
        },
      ),
    );
  }
}
