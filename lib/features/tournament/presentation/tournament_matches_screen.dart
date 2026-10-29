import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/player_actions.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/core/ui/category_filter.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/favorites/favorite_button.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/bracket_view_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/tournament/widget/bracket_tree_view.dart";
import "package:myttmi/features/tournament/widget/group_card.dart";
import "package:myttmi/routes/app_routes.dart";

enum _ViewMode { list, groups, bracket }

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  color: AppColors.scorifyTextMuted,
);

// "GR-3" → "Grupo 3"
String _groupLabel(String name) {
  final m = RegExp(r"^GR-?(\w+)$", caseSensitive: false).firstMatch(name.trim());
  return "Grupo ${m != null ? m.group(1) : name}";
}

void _openProfile(BuildContext context, String userId, String name) {
  if (userId.isEmpty) return;
  Navigator.pushNamed(
    context,
    AppRoutes.playerProfile,
    arguments: {"userId": userId, "playerName": name},
  );
}

class TournamentMatchesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  /// "groups" o "bracket" para abrir directo en esa pestaña (ej. desde el
  /// link de "Resultados"); null usa la lista de partidos por defecto.
  final String? initialMode;

  const TournamentMatchesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.initialMode,
  });

  @override
  State<TournamentMatchesScreen> createState() => _TournamentMatchesScreenState();
}

class _TournamentMatchesScreenState extends State<TournamentMatchesScreen> {
  final _api = PlayerApi();
  Future<List<TournamentMatch>> _future = Future.value(const []);
  String _statusFilter = "all";
  static const _statusLabels = {"all": "Todos", "scheduled": "Por jugar", "finished": "Jugados"};
  // Fase de los partidos de la lista: todos, solo grupos o solo llaves.
  String _stageFilter = "all";
  static const _stageLabels = {"all": "Grupos y llaves", "group": "Grupos", "bracket": "Llaves"};
  late _ViewMode _mode;
  // Llaves queda bloqueada hasta que exista algún partido de llave (mientras
  // se juegan los grupos no hay nada que mostrar ahí).
  bool _hasBracket = false;
  // Todos los partidos del torneo: con ellos la 🏆 de cada jugador arma su
  // recorrido sin pedir nada más (ver TournamentMatchesScope).
  List<TournamentMatch> _allMatches = const [];
  // Una categoría a la vez (arranca en la mía). null = todas.
  List<CategoryOption> _cats = const [];
  String? _cat;
  // La lista espera a saber la categoría inicial (si no, pedía todo y
  // enseguida volvía a pedir solo la mía).
  bool _catsLoaded = false;

  @override
  void initState() {
    super.initState();
    TournamentApi().getTournamentById(widget.tournamentId).then((t) {
      if (!mounted) return;
      final opts = categoryOptions(t.categories);
      setState(() {
        _cats = opts;
        _cat = CategoryFilterBar.initial(opts, t.categories.where((c) => c.isEnrolled).map((c) => c.idCategory));
        _catsLoaded = true;
      });
    }).catchError((_) {
      if (mounted) setState(() => _catsLoaded = true);
    });
    _mode = switch (widget.initialMode) {
      "groups" => _ViewMode.groups,
      "bracket" => _ViewMode.bracket,
      _ => _ViewMode.list,
    };
    _load();
    _api.getTournamentMatches(widget.tournamentId).then((all) {
      if (!mounted) return;
      final has = all.any((m) => m.matchType == "bracket");
      setState(() {
        _hasBracket = has;
        _allMatches = all;
      });
      if (!has && _mode == _ViewMode.bracket) _setMode(_ViewMode.groups);
    }).catchError((_) {});
  }

  void _load() {
    // En modo Grupos/Llaves siempre se pide todo sin filtro de estado — esas
    // vistas necesitan ver las rondas futuras y las ya jugadas a la vez, si
    // no quedan incompletas.
    if (_mode == _ViewMode.list) {
      setState(() {});
      return;
    }
    setState(() {
      _future = _api.getTournamentMatches(widget.tournamentId);
    });
    _future.then((all) {
      if (mounted) setState(() => _allMatches = all);
    }).catchError((_) {});
  }

  void _setMode(_ViewMode mode) {
    if (mode == _ViewMode.bracket && !_hasBracket) {
      showToast(context, "La llave se habilita cuando terminen los grupos.", error: true);
      return;
    }
    setState(() => _mode = mode);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return TournamentMatchesScope(
      matches: _allMatches,
      child: Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScrollingHeaderPage(
              header: [
                const SizedBox(height: 16),
                TopHeader(title: widget.tournamentName, subtitle: "Partidos"),
                const SizedBox(height: 14),
                _Segmented(
                  items: [
                    (label: "Partidos", selected: _mode == _ViewMode.list, locked: false, onTap: () => _setMode(_ViewMode.list)),
                    (label: "Grupos", selected: _mode == _ViewMode.groups, locked: false, onTap: () => _setMode(_ViewMode.groups)),
                    (label: "Llaves", selected: _mode == _ViewMode.bracket, locked: !_hasBracket, onTap: () => _setMode(_ViewMode.bracket)),
                  ],
                ),
                // Una sola línea de filtros: categoría a la izquierda y, en la
                // lista de partidos, el estado a la derecha (antes eran dos
                // filas de chips y se veía amontonado).
                if (_cats.length > 1 || _mode == _ViewMode.list) ...[
                  const SizedBox(height: 12),
                  CategoryFilterBar(
                    options: _cats,
                    selected: _cat,
                    onChanged: (id) => setState(() => _cat = id),
                    trailing: _mode != _ViewMode.list
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: FilterDropdown(
                                icon: Icons.account_tree_rounded,
                                label: _stageLabels[_stageFilter]!,
                                onTap: () async {
                                  final picked = await showOptionsSheet<String>(
                                    context,
                                    title: "Fase",
                                    options: [for (final e in _stageLabels.entries) (value: e.key, label: e.value)],
                                    selected: _stageFilter,
                                  );
                                  if (picked == null) return;
                                  setState(() => _stageFilter = picked.value);
                                },
                              )),
                              const SizedBox(width: 8),
                              Flexible(child: FilterDropdown(
                            icon: Icons.filter_list_rounded,
                            label: _statusLabels[_statusFilter]!,
                            onTap: () async {
                              final picked = await showOptionsSheet<String>(
                                context,
                                title: "Mostrar",
                                options: [for (final e in _statusLabels.entries) (value: e.key, label: e.value)],
                                selected: _statusFilter,
                              );
                              if (picked == null) return;
                              setState(() => _statusFilter = picked.value);
                              _load();
                            },
                          )),
                            ],
                          ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
              body: _mode == _ViewMode.list && !_catsLoaded
                  ? const LoadingState()
                  : _mode == _ViewMode.list
                  ? _PagedMatchList(
                      key: ValueKey("$_statusFilter|$_stageFilter|$_cat"),
                      tournamentId: widget.tournamentId,
                      status: _statusFilter == "all" ? null : _statusFilter,
                      stage: _stageFilter == "all" ? null : _stageFilter,
                      categoryId: _cat,
                    )
                  : RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<List<TournamentMatch>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                          return const LoadingState();
                        }
                        if (snap.hasError) {
                          return ListView(
                            children: [
                              ErrorStateView(
                                message: "No pudimos cargar los partidos.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final all = snap.data ?? [];
                        final matches = _cat == null ? all : all.where((m) => m.idCategory == _cat).toList();

                        if (_mode == _ViewMode.bracket) {
                          return _BracketByCategory(matches: matches);
                        }
                        if (_mode == _ViewMode.groups) {
                          return _GroupsByCategory(tournamentId: widget.tournamentId, matches: matches);
                        }
                        // La lista "Partidos" la dibuja _PagedMatchList (paginada).
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Partido "jugador vs jugador": tocar la tarjeta abre el partido y tocar
/// a un jugador abre su perfil.
class _MatchCard extends StatelessWidget {
  final TournamentMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final played = m.status == "played" || m.status == "walkover";
    final (pillText, pillBg, pillFg) = played
        ? ("Finalizado", AppColors.scorifySurface2, AppColors.scorifyTextMuted)
        : m.tableNumber != null
            ? ("En mesa ${m.tableNumber}", AppColors.scorifyLive, AppColors.scorifyOnLive)
            : (matchStatusText(m.status, m.resultReason), AppColors.scorifySurface2, AppColors.scorifyText);
    final meta = "Partido ${m.matchNumber}";

    return GlassCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.matchDetail,
        arguments: {"matchType": m.matchType, "matchId": m.idMatch},
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted)),
              // Guardar para seguirlo en vivo (solo si todavía no termina).
              if (!played) FavoriteButton(matchType: m.matchType, matchId: m.idMatch, size: 20),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(Panel.radius)),
                child: Text(pillText,
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: pillFg)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Player(
                  id: m.player1Id,
                  name: m.player1Name,
                  winner: played && m.winnerId == m.player1Id,
                ),
              ),
              SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    played ? "${m.setsPlayer1} - ${m.setsPlayer2}" : "VS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: played ? 22 : 16,
                      fontWeight: FontWeight.w600,
                      color: played ? AppColors.scorifyText : AppColors.scorifyTextMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _Player(
                  id: m.player2Id,
                  name: m.player2Name,
                  winner: played && m.winnerId == m.player2Id,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Player extends StatelessWidget {
  final String id;
  final String name;
  final bool winner;
  const _Player({required this.id, required this.name, required this.winner});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openProfile(context, id, name),
      borderRadius: BorderRadius.circular(Panel.radius),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: winner ? AppColors.scorifyButterfly : Colors.transparent,
              ),
              child: UserAvatar(userId: id, size: 40),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 13.5,
                height: 1.25,
                fontWeight: winner ? FontWeight.w600 : FontWeight.w600,
                color: AppColors.scorifyText,
              ),
            ),
            const SizedBox(height: 2),
            PlayerActions(playerId: id, playerName: name, showProfile: false),
          ],
        ),
      ),
    );
  }
}

/// Todos los grupos de todas las categorías del torneo (no solo "los
/// míos") — una card por grupo, con el propio resaltado si el jugador
/// logueado está en él.
class _GroupsByCategory extends StatefulWidget {
  final String tournamentId;
  final List<TournamentMatch> matches;
  const _GroupsByCategory({required this.tournamentId, required this.matches});

  @override
  State<_GroupsByCategory> createState() => _GroupsByCategoryState();
}

class _GroupsByCategoryState extends State<_GroupsByCategory> {
  final _api = PlayerApi();
  late Future<List<(String label, CategoryGroupsView view)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAll();
  }

  @override
  void didUpdateWidget(covariant _GroupsByCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches != widget.matches) {
      _future = _fetchAll();
    }
  }

  Future<List<(String label, CategoryGroupsView view)>> _fetchAll() async {
    final byCategory = <String, String>{}; // idCategory -> label
    for (final m in widget.matches) {
      byCategory.putIfAbsent(m.idCategory, () => m.categoryLabel);
    }
    final results = await Future.wait(
      byCategory.entries.map((e) async {
        final view = await _api.getAllGroups(widget.tournamentId, e.key);
        return (label: e.value, view: view);
      }),
    );
    return [for (final r in results) (r.label, r.view)];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(String label, CategoryGroupsView view)>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const LoadingState();
        }
        if (snap.hasError) {
          return ListView(
            children: [
              ErrorStateView(
                message: "No pudimos cargar los grupos.\n${snap.error}",
                onRetry: () => setState(() {
                  _future = _fetchAll();
                }),
              ),
            ],
          );
        }

        final categories = (snap.data ?? []).where((c) => c.$2.groups.isNotEmpty).toList();
        if (categories.isEmpty) {
          return ListView(
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyState(icon: Icons.groups_rounded, message: "Todavía no hay grupos generados."),
              ),
            ],
          );
        }

        return FutureBuilder<String?>(
          future: SessionStorage().getUserId(),
          builder: (context, userSnap) {
            final myUserId = userSnap.data;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final cat in categories) ...[
                  _CategoryTitle(cat.$1),
                  for (final g in cat.$2.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GroupCard(
                        group: g,
                        myUserId: myUserId,
                        isMyGroup: myUserId != null && g.members.any((m) => m.idUser == myUserId),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Agrupa los partidos de llave por categoría — la mayoría de los torneos
/// tienen una sola, pero si hay más de una se muestran todas apiladas, cada
/// una con su propio cuadro.
class _BracketByCategory extends StatelessWidget {
  final List<TournamentMatch> matches;
  const _BracketByCategory({required this.matches});

  @override
  Widget build(BuildContext context) {
    final bracketMatches = matches.where((m) => m.matchType == "bracket").toList();
    if (bracketMatches.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: EmptyState(icon: Icons.account_tree_rounded, message: "Todavía no hay llave generada."),
          ),
        ],
      );
    }

    final byCategory = <String, List<TournamentMatch>>{};
    for (final m in bracketMatches) {
      byCategory.putIfAbsent(m.idCategory, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final entry in byCategory.entries) ...[
          _CategoryTitle(entry.value.first.categoryLabel),
          BracketTreeView(matches: entry.value),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  final String text;
  const _CategoryTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
        ),
      );
}

/// Selector de pestañas de ancho parejo (mismo estilo que los filtros de
/// Campeonatos). Una pestaña bloqueada se ve apagada y con candado.
class _Segmented extends StatelessWidget {
  final List<({String label, bool selected, bool locked, VoidCallback onTap})> items;
  const _Segmented({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(Panel.buttonRadius)),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: DecoratedBox(decoration: selectedPillDecoration(it.selected), child: Material(
                color: Colors.transparent,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Panel.buttonRadius))),
                child: InkWell(
                  onTap: () {
                    it.onTap();
                  },
                  customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Panel.buttonRadius))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (it.locked) ...[
                          const Icon(Icons.lock_rounded, size: 14, color: AppColors.scorifyTextFaint),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          it.label,
                          style: TextStyle(
                            fontFamily: AppTypography.body,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: it.selected
                                ? AppColors.scorifyText
                                : it.locked
                                    ? AppColors.scorifyTextFaint
                                    : AppColors.scorifyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
        ],
      ),
    );
  }
}


/// Lista "Partidos" con scroll infinito: pide de a 20 y trae los siguientes
/// al acercarse al final, y solo dibuja las tarjetas visibles
/// (ListView.builder). Antes se pedían hasta 100 de una y se dibujaban todos.
class _PagedMatchList extends StatefulWidget {
  final String tournamentId;
  final String? status;
  final String? categoryId;
  final String? stage;
  const _PagedMatchList({super.key, required this.tournamentId, this.status, this.categoryId, this.stage});

  @override
  State<_PagedMatchList> createState() => _PagedMatchListState();
}

class _PagedMatchListState extends State<_PagedMatchList> {
  static const _pageSize = 20;
  final _api = PlayerApi();
  final List<TournamentMatch> _items = [];
  int _total = 0;
  bool _loading = false;
  bool _firstLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  // Sin ScrollController propio: la lista usa el del NestedScrollView de la
  // página (el encabezado sube con ella), así que el "cerca del final" se
  // detecta con la notificación de scroll.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical && n.metrics.pixels >= n.metrics.maxScrollExtent - 400) _loadMore();
    return false;
  }

  bool get _hasMore => _firstLoad || _items.length < _total;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.getTournamentMatchesPage(
        widget.tournamentId,
        status: widget.status,
        categoryId: widget.categoryId,
        stage: widget.stage,
        limit: _pageSize,
        offset: _items.length,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _firstLoad = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _total = 0;
      _firstLoad = true;
    });
    await _loadMore();
  }

  static String _sectionKey(TournamentMatch m) {
    final stage = m.groupName != null
        ? _groupLabel(m.groupName!)
        : m.round != null
            ? "Llave · ${matchRoundLabel(m.round!)}"
            : "Llave";
    return "${m.categoryLabel}|$stage";
  }

  @override
  Widget build(BuildContext context) {
    if (_firstLoad && _loading) return const LoadingState();
    if (_items.isEmpty && _error != null) {
      return ListView(children: [ErrorStateView(message: "No pudimos cargar los partidos.\n$_error", onRetry: _refresh)]);
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: EmptyState(icon: Icons.sports_tennis_rounded, message: "No hay partidos con ese filtro."),
          ),
        ],
      );
    }

    // Lista plana de títulos de sección + tarjetas (un título cuando cambia
    // el grupo/ronda respecto del partido anterior; el servidor ya los manda
    // ordenados así).
    final rows = <Object>[];
    String? last;
    for (final m in _items) {
      final key = _sectionKey(m);
      if (key != last) {
        rows.add(key);
        last = key;
      }
      rows.add(m);
    }

    return RefreshIndicator(
      color: AppColors.scorifyMint,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) {
          if (i == rows.length) {
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint))),
              );
            }
            if (_error != null) {
              return TextButton(onPressed: _loadMore, child: const Text("No se pudieron cargar más. Reintentar"));
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  _hasMore ? "" : "${_items.length} de $_total partidos",
                  style: _muted,
                ),
              ),
            );
          }
          final row = rows[i];
          if (row is String) {
            final parts = row.split("|");
            return Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.scorifyMint, borderRadius: BorderRadius.circular(Panel.radius))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(parts.last,
                        style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                  ),
                  Text(parts.first, style: _muted),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MatchCard(match: row as TournamentMatch),
          );
        },
        ),
      ),
    );
  }
}
