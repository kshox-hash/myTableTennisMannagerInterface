import 'package:flutter/material.dart';
import "package:myttmi/features/home/widget/home_layout.dart";
import "package:myttmi/core/ui/side_panel_route.dart";
import "package:myttmi/features/notifications/presentation/notifications_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:myttmi/features/shell/splash_gate.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/features/player/models/player_dashboard_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/notifications/api/notifications_api.dart';

import '../../../routes/app_routes.dart';

import '../widget/spin_header.dart';
import '../widget/spin_next_match_panel.dart';
import "package:myttmi/core/push/push_service.dart";

/// Pestaña "Inicio" del shell — ya no arma su propio Scaffold/fondo/nav, eso
/// lo maneja AppShell. Cambiar a otra pestaña se pide vía AppShellScope en
/// vez de empujar una segunda pantalla encima.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TabAutoRefreshMixin<HomeScreen> {
  @override
  int get tabIndex => 0;

  @override
  void onTabActivated() => _load();

  final _playerApi = PlayerApi();
  final _profileApi = ProfileApi();
  final _notificationsApi = NotificationsApi();

  UserProfile? _profile;
  PlayerDashboard? _dashboard;
  // Racha: resultado de los últimos partidos terminados, del más antiguo al
  // más reciente (true = ganado). Vacío si todavía no jugó.
  List<bool> _form = const [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _profileApi.getMe(),
        _playerApi.getDashboard(),
        _notificationsApi.getUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _dashboard = results[1] as PlayerDashboard;
        _unreadCount = results[2] as int;
      });
      _loadForm(_profile?.idUser);
    } catch (_) {
      // Silencioso: la pantalla igual se puede usar sin estos datos.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Aparte del Future.wait principal: necesita el id del perfil, y si falla
  // el Inicio igual se muestra (solo sin la racha).
  Future<void> _loadForm(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final history = await _playerApi.getPlayerMatchHistory(userId, limit: 10);
      final done = history
          .where((m) => m.status == "played" || m.status == "walkover")
          .take(5)
          .map((m) => m.winnerId == userId)
          .toList()
          .reversed
          .toList();
      if (mounted) setState(() => _form = done);
    } catch (_) {}
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.scorifyDeep,
        title: const Text(
          "Cerrar sesión",
          style: TextStyle(color: AppColors.scorifyText),
        ),
        content: Text(
          "¿Quieres cerrar sesión y volver al login?",
          style: TextStyle(color: AppColors.scorifyText.withOpacity(0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancelar",
              style: TextStyle(color: AppColors.scorifyText.withOpacity(0.85)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.scorifyButterfly,
              foregroundColor: AppColors.scorifyOnButterfly,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PushService.unregister();
      await SessionStorage().clearAll();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        CyberPageRoute(builder: (_) => const SplashGate()),
        (route) => false,
      );
    }
  }

  Future<void> _openSettings() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.scorifyDeep.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.scorifyText),
                title: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: AppColors.scorifyText),
                ),
                onTap: () => Navigator.pop(context, "logout"),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    // Perfil e historial ya están en el Inicio (tarjeta y botones).
    if (action == "logout") {
      await _confirmLogout();
    }
  }

  Widget _panelFor(PlayerNextMatch? m) {
    final stage = m == null
        ? ""
        : [
            m.categoryDisplay,
            if (m.groupName != null)
              "Grupo ${m.groupName}"
            else if (m.round != null)
              "Ronda ${m.round}",
          ].where((s) => s.trim().isNotEmpty).join(" · ");
    return SpinNextMatchPanel(
      hasMatch: m != null,
      tournamentName: m?.tournamentName ?? "",
      stageLabel: stage,
      myId: _profile?.idUser,
      myName: (_profile?.displayName.isNotEmpty ?? false)
          ? _profile!.displayName
          : "Tú",
      opponentId: m?.opponentId,
      opponentName: m?.opponentName ?? "Rival por definir",
      tableNumber: m?.tableNumber,
      scheduledAt: m?.scheduledStartAt,
      statusLabel: m != null && m.tableNumber == null ? m.queueLabel : "",
      emptySubtitle: _loading
          ? "Cargando…"
          : "Inscríbete a un campeonato para entrar al fixture",
      onTap: m?.opponentId != null
          ? () => Navigator.pushNamed(
              context,
              AppRoutes.playerProfile,
              arguments: {
                "userId": m!.opponentId,
                "playerName": m.opponentName ?? "Jugador",
              },
            )
          : () => AppShellScope.of(context)?.switchTab(3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nm = _dashboard?.nextMatch;

    final stats = _dashboard?.stats;
    final played = stats?.matchesPlayed ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SpinHeader(
            notificationsCount: _unreadCount,
            // Panel lateral en vez de página completa; al cerrarlo se
            // refresca el contador de no leídas.
            onNotifications: () => Navigator.push(
              context,
              SidePanelRoute(child: const NotificationsScreen()),
            ).then((_) => _load()),
            onSettings: _openSettings,
          ),

          const SizedBox(height: 16),

          // Los bloques se reparten a lo alto de la pantalla (spaceBetween sobre
          // un alto mínimo = pantalla): sin hueco abajo en celulares altos, y en
          // pantallas chicas se desplaza igual que antes.
          Expanded(
            child: LayoutBuilder(
              // Deslizar hacia abajo recarga el inicio.
              builder: (context, box) => RefreshIndicator(
                color: AppColors.scorifyMint,
                onRefresh: _load,
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeHero(
                        userId: _profile?.idUser,
                        name: (_profile?.displayName.isNotEmpty ?? false)
                            ? _profile!.displayName
                            : "Jugador",
                        country: _profile?.country,
                        club: _profile?.club,
                        age: _profile?.age,
                        gender: _profile?.gender,
                        memberSince: _profile?.createdAt,
                        avatarUrl: _profile?.avatarUrl,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                      const SizedBox(height: 10),
                      HomeStatsBar(
                        played: played,
                        activeEnrollments: _dashboard?.activeEnrollments ?? 0,
                        ranking: "–",
                      ),
                      const SizedBox(height: 10),
                      HomeStreakCard(
                        form: _form,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.history),
                      ),
                      const SizedBox(height: 10),
                      HomeActionButtons(
                        onProfile: () =>
                            Navigator.pushNamed(context, AppRoutes.profile),
                        onHistory: () =>
                            Navigator.pushNamed(context, AppRoutes.history),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: HomeKpiCard(
                              icon: Icons.emoji_events_rounded,
                              decoration: Icons.emoji_events_outlined,
                              accent: AppColors.scorifyButterfly,
                              label: "Victorias",
                              value: "${stats?.matchesWon ?? 0}",
                              sub:
                                  "${stats?.matchesWon ?? 0} G · ${stats?.matchesLost ?? 0} P",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HomeKpiCard(
                              icon: Icons.insights_rounded,
                              decoration: Icons.show_chart_rounded,
                              accent: AppColors.scorifyMint,
                              label: "Efectividad",
                              value: played == 0
                                  ? "—"
                                  : "${(stats!.winRate * 100).round()}%",
                              sub: played == 0
                                  ? "Sin partidos aún"
                                  : "de $played ${played == 1 ? "partido" : "partidos"}",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Próximo partido: si hay, las tarjetas deslizables de siempre;
                      // si no, la invitación a buscar campeonatos.
                      if (nm == null)
                        HomeNoMatchCard(
                          loading: _loading,
                          onBrowse: () =>
                              AppShellScope.of(context)?.switchTab(3),
                        )
                      else
                        _MatchesCarousel(
                          pages: [
                            for (final m in [
                              nm,
                              ...?_dashboard?.otherNextMatches,
                            ])
                              _panelFor(m),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carrusel horizontal de tarjetas de partido: se desliza de a una, con
/// puntitos que indican cuántas hay. Con una sola tarjeta no muestra puntos.
class _MatchesCarousel extends StatefulWidget {
  final List<Widget> pages;
  const _MatchesCarousel({required this.pages});

  @override
  State<_MatchesCarousel> createState() => _MatchesCarouselState();
}

class _MatchesCarouselState extends State<_MatchesCarousel> {
  final _controller = ScrollController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    if (pages.length == 1) return pages.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Column(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (_) {
                final p = (_controller.offset / w).round().clamp(
                  0,
                  pages.length - 1,
                );
                if (p != _page) setState(() => _page = p);
                return false;
              },
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final page in pages) SizedBox(width: w, child: page),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Con muchos partidos los puntitos no caben: se muestra "3 / 12".
            if (pages.length > 6)
              Text(
                "${_page + 1} / ${pages.length}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.scorifyTextMuted,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.scorifyMint
                            : AppColors.scorifySurface2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
