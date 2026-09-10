import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/features/tournament/presentation/tournament_detail_screen.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/shell/tab_auto_refresh.dart";

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

  String? _selectedCity; // null = todas

  List<Tournament> _items = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const List<String> chileCities = [
    "Santiago",
    "Valparaíso",
    "Viña del Mar",
    "Concepción",
    "Antofagasta",
    "La Serena",
    "Iquique",
    "Arica",
    "Copiapó",
    "Temuco",
    "Valdivia",
    "Osorno",
    "Puerto Montt",
    "Chillán",
    "Punta Arenas",
  ];

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
      final result = await api.fetchTournaments(city: _selectedCity, page: 1);
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
        city: _selectedCity,
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

  void _clearCity() {
    setState(() => _selectedCity = null);
    _reload();
  }

  void _onSelectCity(String? city) {
    setState(() => _selectedCity = (city == "Todas") ? null : city);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const TopHeader(title: "Campeonatos", showBack: false),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _error != null
                ? ErrorStateView(
                    message: "No pudimos cargar los campeonatos.\n$_error",
                    onRetry: _reload,
                  )
                : RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _reload,
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_city_outlined,
                                    color: AppColors.scorifyMint,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Filtrar por ciudad",
                                    style: AppTypography.h2,
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${_items.length}",
                                    style: AppTypography.bodyMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCity ?? "Todas",
                                isExpanded: true,
                                dropdownColor: AppColors.scorifyDeep,
                                iconEnabledColor: AppColors.scorifyTextMuted,
                                style: AppTypography.bodyText,
                                decoration: _ddDeco("Ciudad"),
                                items: [
                                  const DropdownMenuItem(
                                    value: "Todas",
                                    child: Text("Todas"),
                                  ),
                                  ...chileCities.map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  ),
                                ],
                                onChanged: _onSelectCity,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Center(
                                  child: OutlinePillButton(
                                    icon: Icons.refresh_rounded,
                                    label: "Ver todos",
                                    onTap: _clearCity,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (_items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: EmptyState(
                              icon: Icons.emoji_events_outlined,
                              message: "No hay campeonatos con ese filtro.",
                            ),
                          )
                        else
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final t = _items[i];

                              return GlassCard(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CyberPageRoute(
                                      builder: (_) =>
                                          TournamentDetailScreen(tournament: t),
                                    ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: AppColors.scorifyMint
                                            .withOpacity(0.14),
                                        border: Border.all(
                                          color: AppColors.scorifyCardBorder,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events_outlined,
                                        color: AppColors.scorifyMint,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.tournamentName,
                                            style: AppTypography.h1,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            [
                                              if (t.region != null &&
                                                  t.region!.trim().isNotEmpty)
                                                t.region!,
                                              "Categorías: ${t.categories.length}",
                                            ].join(" · "),
                                            style: AppTypography.bodyMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.scorifyTextFaint,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        if (_loadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.scorifyMint,
                              ),
                            ),
                          )
                        else if (_page >= _totalPages && _items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "No hay más campeonatos.",
                                style: AppTypography.caption,
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

  InputDecoration _ddDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMuted,
      isDense: true,
      filled: true,
      fillColor: AppColors.scorifyCardFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.4),
      ),
    );
  }
}
