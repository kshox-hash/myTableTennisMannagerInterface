import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/features/tournament/presentation/tournament_detail_screen.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/shell/tab_auto_refresh.dart";

// "Mis campeonatos": en período de prueba los campeonatos son privados y no
// se buscan — el servidor devuelve solo los públicos y aquellos en que el
// jugador ya está inscrito. A uno nuevo se entra por el link que comparte el
// organizador (abre directo el detalle, ver deep_links.dart).

enum _Status { upcoming, ongoing, finished, unknown }

// Primero manda el avance real de las categorías: si alguna ya salió de
// inscripciones está "En curso", y si todas terminaron está "Finalizado".
// Sin avance, se decide por la fecha.
_Status _statusOf(Tournament t) {
  final cats = t.categories;
  if (cats.isNotEmpty && cats.every((c) => c.phase == "finished")) return _Status.finished;
  if (cats.any((c) => c.phase != "enrollment")) return _Status.ongoing;
  final d = DateTime.tryParse(t.eventDate ?? "");
  if (d == null) return _Status.unknown;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final event = DateTime(d.year, d.month, d.day);
  if (event == today) return _Status.ongoing;
  return event.isAfter(today) ? _Status.upcoming : _Status.finished;
}

// Los filtros son los mismos estados del chip de cada tarjeta; "Sin fecha"
// cuenta como próximo.
enum _ActiveFilter { all, upcoming, ongoing, finished }

String _formatDate(String date) {
  final p = date.split("-");
  return p.length == 3 ? "${p[2]}-${p[1]}-${p[0]}" : date;
}

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with TabAutoRefreshMixin<TournamentsScreen> {
  @override
  int get tabIndex => 3;

  @override
  void onTabActivated() => _reload();

  late final TournamentApi api;
  final ScrollController _scrollController = ScrollController();
  _ActiveFilter _activeFilter = _ActiveFilter.all;

  List<Tournament> _items = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    api = TournamentApi();
    _scrollController.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await api.fetchTournaments(
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final result = await api.fetchTournaments(
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } catch (_) {
      // Silencioso: si falla cargar la próxima página, el usuario sigue
      // viendo lo que ya tiene y puede reintentar haciendo scroll de nuevo.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Tournament> get _visible => _items.where((t) {
    final s = _statusOf(t);
    return switch (_activeFilter) {
      _ActiveFilter.all => true,
      _ActiveFilter.upcoming => s == _Status.upcoming || s == _Status.unknown,
      _ActiveFilter.ongoing => s == _Status.ongoing,
      _ActiveFilter.finished => s == _Status.finished,
    };
  }).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopHeader(title: "Mis campeonatos", showBack: false),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.scorifyMint,
              onRefresh: _reload,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    "Los campeonatos en que participas. Para inscribirte en uno nuevo, abre el link que comparte el organizador.",
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: 14),
                  _filterChips(),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: LoadingState(),
                    )
                  else if (_error != null)
                    ErrorStateView(
                      message: "No pudimos cargar los campeonatos.\n$_error",
                      onRetry: _reload,
                    )
                  else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: EmptyState(
                        icon: Icons.emoji_events_outlined,
                        message: _items.isEmpty
                            ? "Aún no participas en ningún campeonato.\nPide al organizador el link del campeonato para inscribirte."
                            : "No hay campeonatos con ese filtro.",
                      ),
                    )
                  else
                    for (final t in visible) ...[
                      _TournamentCard(
                        tournament: t,
                        onTap: () => Navigator.push(
                          context,
                          CyberPageRoute(
                            builder: (_) =>
                                TournamentDetailScreen(tournament: t),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.scorifyMint,
                        ),
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

  Widget _filterChips() {
    const labels = {
      _ActiveFilter.all: "Todos",
      _ActiveFilter.upcoming: "Próximos",
      _ActiveFilter.ongoing: "En curso",
      _ActiveFilter.finished: "Finalizados",
    };
    // Una sola fila de ancho parejo: con 4 opciones un Wrap bajaba
    // "Finalizados" a una segunda línea en celulares angostos.
    return Row(
      children: [
        for (final e in labels.entries) ...[
          if (e.key != _ActiveFilter.all) const SizedBox(width: 6),
          Expanded(
            child: _FilterChip(
              label: e.value,
              selected: _activeFilter == e.key,
              onTap: () => setState(() => _activeFilter = e.key),
            ),
          ),
        ],
      ],
    );
  }

}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.scorifyMint : AppColors.scorifySurface2,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.scorifyOnMint
                    : AppColors.scorifyTextMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final status = _statusOf(t);
    final enrolled = t.categories.fold<int>(0, (s, c) => s + c.enrolledCount);
    final allFinite =
        t.categories.isNotEmpty && t.categories.every((c) => c.quotas != null);
    final quota = allFinite
        ? t.categories.fold<int>(0, (s, c) => s + (c.quotas ?? 0))
        : null;
    final place = [
      (t.region ?? "").trim().isEmpty ? "Región sin especificar" : t.region!,
      if ((t.address ?? "").trim().isNotEmpty) t.address!,
    ].join(" · ");

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  t.tournamentName,
                  style: const TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.scorifyText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(status: status),
            ],
          ),
          if ((t.organizerName ?? "").isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipOval(
                  child: (t.organizerAvatarUrl ?? "").isEmpty
                      ? Identicon(seed: t.createdBy, size: 22)
                      : Image.network(
                          t.organizerAvatarUrl!,
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Identicon(seed: t.createdBy, size: 22),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Organiza ${t.organizerName}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.scorifyText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(place, style: AppTypography.bodyMuted),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (t.eventDate != null)
                _Meta(
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.scorifyMint,
                  text: _formatDate(t.eventDate!),
                ),
              _Meta(
                icon: Icons.emoji_events_rounded,
                color: AppColors.scorifyPending,
                text:
                    "${t.categories.length} ${t.categories.length == 1 ? "categoría" : "categorías"}",
              ),
              _Meta(
                icon: Icons.group_rounded,
                color: AppColors.scorifyButterfly,
                text: quota != null
                    ? "$enrolled / $quota inscritos"
                    : "$enrolled inscritos",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _Status.upcoming => (
        "Próximo",
        AppColors.scorifyMint,
        AppColors.scorifyOnMint,
      ),
      _Status.ongoing => (
        "En curso",
        AppColors.scorifyButterfly,
        AppColors.scorifyOnButterfly,
      ),
      _Status.finished => (
        "Finalizado",
        AppColors.scorifySurface2,
        AppColors.scorifyTextMuted,
      ),
      _Status.unknown => (
        "Sin fecha",
        AppColors.scorifySurface2,
        AppColors.scorifyTextMuted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Meta({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: AppColors.scorifyTextMuted,
          ),
        ),
      ],
    );
  }
}
