import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/card_border.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/favorites/favorite_matches.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/scoreboard.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// "Partidos guardados": los partidos marcados con ♥, como marcadores en
/// vivo. Se actualiza cada 10 s (el organizador carga los resultados set a
/// set). Se elige cuántos ver a la vez (2, 4 o 6: las tarjetas se achican
/// para que entren en la pantalla). Cuando un partido termina, muestra el
/// resultado final unos segundos y se saca solo de la lista.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _refresh = Duration(seconds: 10);
  static const _finishedLinger = Duration(seconds: 8);

  final _api = PlayerApi();
  final Map<FavoriteMatch, MatchDetail> _data = {};
  final Set<FavoriteMatch> _failed = {};
  // Partidos que ya terminaron: se muestran un rato con el resultado final y
  // después se sacan de la lista.
  final Set<FavoriteMatch> _leaving = {};
  Timer? _timer;
  int _view = 2;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    FavoriteMatches.getView().then((v) {
      if (mounted) setState(() => _view = v);
    });
    FavoriteMatches.items.addListener(_onListChanged);
    _loadAll();
    _timer = Timer.periodic(_refresh, (_) => _loadAll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    FavoriteMatches.items.removeListener(_onListChanged);
    super.dispose();
  }

  void _onListChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    final favs = FavoriteMatches.items.value;
    await Future.wait(favs.map((f) async {
      try {
        final d = await _api.getMatchDetail(f.matchType, f.matchId);
        _data[f] = d;
        _failed.remove(f);
        final done = d.status == "played" || d.status == "walkover";
        if (done && !_leaving.contains(f)) {
          _leaving.add(f);
          Future.delayed(_finishedLinger, () {
            FavoriteMatches.remove(f);
            _leaving.remove(f);
            _data.remove(f);
          });
        }
      } catch (_) {
        _failed.add(f);
      }
    }));
    if (mounted) setState(() => _loading = false);
  }

  void _setView(int v) {
    setState(() => _view = v);
    FavoriteMatches.setView(v);
  }

  @override
  Widget build(BuildContext context) {
    final favs = FavoriteMatches.items.value;
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScrollingHeaderPage(
              header: [
                const SizedBox(height: 16),
                const TopHeader(title: "Partidos guardados"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Se actualizan solos cada 10 s. Al terminar, el partido se quita de la lista.",
                        style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ViewSelector(value: _view, onChanged: _setView),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              crossAxisAlignment: CrossAxisAlignment.stretch,
              body: favs.isEmpty
                      ? const _Empty()
                      : LayoutBuilder(
                          builder: (context, box) {
                            // 2 → una columna, dos filas; 4 → 2×2; 6 → 2×3.
                            final cols = _view == 2 ? 1 : 2;
                            final rows = _view == 6 ? 3 : 2;
                            const gap = 10.0;
                            final w = (box.maxWidth - gap * (cols - 1)) / cols;
                            // Alto propio de cada vista, con techo: antes era
                            // "pantalla ÷ filas" y con 1 o 2 partidos guardados
                            // las tarjetas quedaban enormes y vacías.
                            final fill = ((box.maxHeight - 12) - gap * (rows - 1)) / rows;
                            final h = fill.clamp(120.0, _view == 2 ? 190.0 : 160.0);
                            final compact = _view != 2;
                            return RefreshIndicator(
                              color: AppColors.scorifyMint,
                              onRefresh: _loadAll,
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: favs.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: gap,
                                  crossAxisSpacing: gap,
                                  childAspectRatio: w / h.clamp(120, 1000),
                                ),
                                itemBuilder: (context, i) {
                                  final f = favs[i];
                                  return _LiveCard(
                                    detail: _data[f],
                                    loading: _loading && _data[f] == null,
                                    failed: _failed.contains(f) && _data[f] == null,
                                    leaving: _leaving.contains(f),
                                    compact: compact,
                                    onRemove: () => FavoriteMatches.remove(f),
                                    onOpen: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.matchDetail,
                                      arguments: {"matchType": f.matchType, "matchId": f.matchId},
                                    ),
                                  );
                                },
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
}

class _ViewSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ViewSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: panelBox(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in const [2, 4, 6])
            GestureDetector(
              onTap: () {
                onChanged(v);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: selectedPillDecoration(v == value),
                child: Text(
                  "$v",
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: v == value ? AppColors.scorifyText : AppColors.scorifyTextMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 44, color: AppColors.scorifyTextMuted),
            const SizedBox(height: 12),
            const Text(
              "Aún no guardas partidos",
              style: TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
            ),
            const SizedBox(height: 6),
            Text(
              "Toca el ♥ en un partido (en la lista de partidos del campeonato o en su detalle) para seguirlo en vivo aquí.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador de un partido guardado.
class _LiveCard extends StatelessWidget {
  final MatchDetail? detail;
  final bool loading;
  final bool failed;
  final bool leaving;
  final bool compact;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _LiveCard({
    required this.detail,
    required this.loading,
    required this.failed,
    required this.leaving,
    required this.compact,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return CardBorder(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(Panel.radius)), child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Panel.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: d == null ? null : onOpen,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: d == null
              ? Center(
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.scorifyMint))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(failed ? "No se pudo cargar" : "", style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
                            TextButton(onPressed: onRemove, child: const Text("Quitar")),
                          ],
                        ),
                )
              : _content(d),
        ),
      ),
    )));
  }

  Widget _content(MatchDetail d) {
    final done = d.status == "played" || d.status == "walkover";
    final sets = d.setScores ?? const [];
    final live = !done && d.tableNumber != null;
    final (pill, pillBg, pillFg) = done
        ? ("Final", AppColors.scorifySurface2, AppColors.scorifyText)
        : live
            ? ("EN VIVO · MESA ${d.tableNumber}", AppColors.scorifyNegative, Colors.white)
            : ("Por jugar", AppColors.scorifySurface2, AppColors.scorifyTextMuted);
    final stage = [
      d.categoryType,
      if (d.groupName != null) groupLabel(d.groupName) else if (d.round != null) matchRoundLabel(d.round!, d.totalRounds),
    ].join(" · ");
    final winner = !done ? null : (d.winnerId == d.player1Id ? 1 : (d.winnerId == d.player2Id ? 2 : null));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(Panel.radius)),
                child: Text(
                  pill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: pillFg),
                ),
              ),
              ),
            ),
            InkResponse(
              onTap: onRemove,
              radius: 16,
              child: const Icon(Icons.favorite_rounded, size: 18, color: AppColors.scorifyNegative),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          compact ? stage : "${d.tournamentName} · $stage",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMuted.copyWith(fontSize: compact ? 11 : 12.5),
        ),
        const Spacer(),
        Scoreboard(
          player1: d.player1Name,
          player2: d.player2Name,
          sets1: done || sets.isNotEmpty ? d.setsPlayer1 : null,
          sets2: done || sets.isNotEmpty ? d.setsPlayer2 : null,
          winner: winner,
          // En la vista de 4 o 6 no caben los puntos de cada set.
          setScores: compact ? const [] : [for (final x in sets) (x.p1, x.p2)],
          showScore: done || sets.isNotEmpty,
          nameSize: compact ? 12 : 14,
          setsSize: compact ? 16 : 20,
        ),
        if (leaving) ...[
          const SizedBox(height: 4),
          Text(
            "Terminó · se quitará en unos segundos",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMuted.copyWith(fontSize: 11, color: AppColors.scorifyButterfly),
          ),
        ],
      ],
    );
  }
}
