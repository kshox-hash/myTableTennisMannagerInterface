import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/match_list.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/profile/api/profile_api.dart";
import "package:myttmi/features/profile/models/profile_model.dart";
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
  // Totales para el resumen de arriba (no dependen de cuántos se cargaron).
  PlayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _refresh();
    ProfileApi().getStats().then((s) {
      if (mounted) setState(() => _stats = s);
    }).catchError((_) {});
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
    final st = _stats;
    Widget stat(String v, String l, Color c) => Expanded(
          child: Column(
            children: [
              Text(v, style: TextStyle(fontFamily: AppTypography.body, fontSize: 24, fontWeight: FontWeight.w600, color: c)),
              Text(l.toUpperCase(),
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: AppColors.scorifyTextMuted)),
            ],
          ),
        );
    Widget sep() => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.10));
    return RefreshIndicator(
      color: AppColors.scorifyMint,
      onRefresh: _refresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Resumen: datos neutros en blanco; verde solo ganados, rojo perdidos.
          if (st != null) ...[
            Row(
              children: [
                stat("${st.matchesPlayed}", "Partidos", AppColors.scorifyText),
                sep(),
                stat("${st.matchesWon}", "Ganados", AppColors.scorifyButterfly),
                sep(),
                stat("${st.matchesLost}", "Perdidos", AppColors.scorifyNegative),
              ],
            ),
            const SizedBox(height: 16),
          ],
          ...matchesByMonth(context, _items, _myId),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint))),
            )
          else if (_error != null)
            TextButton(onPressed: _loadMore, child: const Text("No se pudieron cargar más. Reintentar")),
        ],
      ),
    );
  }
}
