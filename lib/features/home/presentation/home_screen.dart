import "package:myttmi/features/shell/shell_preload.dart";
import "package:myttmi/features/calendar/api/calendar_api.dart";
import "package:myttmi/features/calendar/models/calendar_event.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/core/ui/stagger_in.dart";
import 'package:myttmi/core/ui/app_button.dart';
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
import 'package:myttmi/features/player/models/player_category_view_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/notifications/api/notifications_api.dart';

import '../../../routes/app_routes.dart';

import '../widget/spin_header.dart';
import '../widget/spin_next_match_panel.dart';
import "package:myttmi/core/push/push_service.dart";
import "package:myttmi/features/favorites/favorites_screen.dart";
import "package:myttmi/features/referee/referee_api.dart";
import "package:myttmi/features/referee/referee_screen.dart";
import "package:myttmi/features/referee/referee_scan_screen.dart";
import "package:myttmi/features/notifications/notification_popups.dart";

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
  // Modo día de torneo: mi fila en la tabla de mi grupo (del próximo
  // partido de grupo) y cuántos son en el grupo.
  PlayerStanding? _myStanding;
  // Partidos que me toca arbitrar (asignados por el organizador o por QR).
  List<RefereeMatch> _refMatches = const [];
  // Sin partido asignado: el próximo campeonato en que estás inscrito, o
  // cuántos campeonatos tienen la inscripción abierta.
  CalendarEvent? _upcoming;
  int _openCount = 0;
  int _groupSize = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // La primera carga avisa a la pantalla de carga (ShellPreload): esta se
  // quita recién cuando el Inicio tiene TODO, para que aparezca completo.
  bool _firstLoad = true;

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
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
        NotificationPopups.unread.value = _unreadCount;
      });
      if (_firstLoad) ShellPreload.report(0.6);
      // Racha, grupo y partidos por arbitrar: en paralelo, y se esperan para
      // que el Inicio se muestre completo de una vez.
      await Future.wait([
        _loadForm(_profile?.idUser),
        _loadGroup(_dashboard?.nextMatch),
        _loadReferee(),
        if (_dashboard?.nextMatch == null) _loadUpcoming(),
      ]);
    } catch (_) {
      // Silencioso: la pantalla igual se puede usar sin estos datos.
    } finally {
      if (mounted) setState(() => _loading = false);
      if (_firstLoad) {
        _firstLoad = false;
        ShellPreload.done();
      }
    }
  }

  /// Sin partido: tu próximo campeonato (inscrito y aún sin empezar); si no
  /// hay, cuántos campeonatos tienen la inscripción abierta.
  Future<void> _loadUpcoming() async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    CalendarEvent? next;
    try {
      final events = await CalendarApi().myEvents(from: day, to: day.add(const Duration(days: 180)));
      final pending = events.where((e) => !e.finished && !e.inProgress && !e.date.isBefore(day)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (pending.isNotEmpty) next = pending.first;
    } catch (_) {}
    var open = 0;
    if (next == null) {
      try {
        final page = await TournamentApi().fetchTournaments(limit: 50);
        open = page.items.where((t) {
          if (t.isCancelled) return false;
          final d = DateTime.tryParse(t.eventDate ?? "");
          if (d != null && d.isBefore(day)) return false;
          return t.categories.any((c) => c.phase == "enrollment");
        }).length;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _upcoming = next;
      _openCount = open;
    });
  }

  static const _weekdays = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"];
  static const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

  /// "sáb 12 oct · faltan 9 días" / "· es mañana" / "· es hoy".
  String _whenLabel(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final left = days <= 0 ? "es hoy" : days == 1 ? "es mañana" : "faltan $days días";
    return "${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} · $left";
  }

  Future<void> _openUpcoming() async {
    final e = _upcoming;
    if (e == null) return;
    try {
      final t = await TournamentApi().getTournamentById(e.tournamentId);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: t);
      if (mounted) _load(silent: true);
    } catch (_) {}
  }

  Future<void> _loadReferee() async {
    try {
      final r = await RefereeApi().myMatches();
      if (mounted) setState(() => _refMatches = r);
    } catch (_) {}
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

  // Aparte del Future.wait principal (como la racha): si falla, el Inicio se
  // muestra igual, solo sin la tarjeta del grupo.
  Future<void> _loadGroup(PlayerNextMatch? m) async {
    final me = _profile?.idUser;
    if (m == null || m.matchType != "group" || me == null) {
      if (mounted) setState(() => _myStanding = null);
      return;
    }
    try {
      final view = await _playerApi.getCategoryView(m.idTournament, m.idCategory);
      final mine = view.standings.where((r) => r.idUser == me).toList();
      if (!mounted) return;
      setState(() {
        _myStanding = mine.isEmpty ? null : mine.first;
        _groupSize = view.standings.length;
      });
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
          AppButton(
            label: "Cerrar sesión",
            icon: Icons.logout,
            onPressed: () => Navigator.pop(context, true),
            height: 40,
            expand: false,
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
                leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.scorifyText),
                title: const Text(
                  "Arbitrar con QR",
                  style: TextStyle(color: AppColors.scorifyText),
                ),
                onTap: () => Navigator.pop(context, "referee_scan"),
              ),
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
    } else if (action == "referee_scan") {
      await Navigator.push(context, CyberPageRoute(builder: (_) => const RefereeScanScreen()));
      if (mounted) _load(silent: true);
    }
  }

  Widget _fillHeight(bool enabled, Widget child) => enabled ? IntrinsicHeight(child: child) : child;

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
      myAvatarUrl: _profile?.avatarUrl,
      opponentId: m?.opponentId,
      opponentName: m?.opponentName ?? "Rival por definir",
      opponentAvatarUrl: m?.opponentAvatarUrl,
      tableNumber: m?.tableNumber,
      scheduledAt: m?.scheduledStartAt,
      statusLabel: m != null && m.tableNumber == null ? m.queueLabel : "",
      emptySubtitle: _loading
          ? "Cargando…"
          : "Inscríbete a un campeonato para entrar al fixture",
      onTap: m != null
          ? () => Navigator.pushNamed(
              context,
              AppRoutes.tournamentTables,
              arguments: {"tournamentId": m.idTournament, "tournamentName": m.tournamentName},
            )
          : () => AppShellScope.of(context)?.switchTab(3),
      onOpponentProfile: m?.opponentId != null
          ? () => Navigator.pushNamed(
              context,
              AppRoutes.playerProfile,
              arguments: {
                "userId": m!.opponentId,
                "playerName": m.opponentName ?? "Jugador",
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nm = _dashboard?.nextMatch;

    final stats = _dashboard?.stats;
    final played = stats?.matchesPlayed ?? 0;

    final hero = HomeHero(
      userId: _profile?.idUser,
      name: (_profile?.displayName.isNotEmpty ?? false) ? _profile!.displayName : "Jugador",
      country: _profile?.country,
      club: _profile?.club,
      age: _profile?.age,
      gender: _profile?.gender,
      memberSince: _profile?.createdAt,
      avatarUrl: _profile?.avatarUrl,
      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
    );
    final matches = nm == null
        ? const SizedBox.shrink()
        : _MatchesCarousel(
            pages: [
              for (final m in [nm, ...?_dashboard?.otherNextMatches]) _panelFor(m),
            ],
          );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationPopups.unread,
            builder: (context, unread, _) => SpinHeader(
            notificationsCount: unread,
            onFavorites: () => Navigator.push(
              context,
              CyberPageRoute(builder: (_) => const FavoritesScreen()),
            ),
            // Panel lateral en vez de página completa; al cerrarlo se
            // refresca el contador de no leídas.
            onNotifications: () => Navigator.push(
              context,
              SidePanelRoute(child: const NotificationsScreen()),
            ).then((_) => _load()),
            onSettings: _openSettings,
          ),
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
                  // Separación pareja de 12 px entre bloques (antes se
                  // repartían para llenar la pantalla y quedaban huecos
                  // grandes); sin partido, el alto que sobra lo toma la
                  // tarjeta de abajo. Con partido no hace falta (el
                  // contenido ya llena) y el carrusel —que usa
                  // LayoutBuilder— no admite IntrinsicHeight.
                  child: _fillHeight(nm == null, Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: staggerChildren([
                      hero,
                      const SizedBox(height: 12),
                      if (_refMatches.isNotEmpty) ...[
                        HomeRefereeCard(
                          title: "${_refMatches.first.player1Name} vs ${_refMatches.first.player2Name}",
                          subtitle: [
                            if (_refMatches.first.tableNumber != null) "Mesa ${_refMatches.first.tableNumber}",
                            _refMatches.first.categoryDisplay,
                            if (_refMatches.length > 1) "+${_refMatches.length - 1} más",
                          ].join(" · "),
                          onTap: () async {
                            final r = _refMatches.first;
                            await Navigator.push(
                              context,
                              CyberPageRoute(builder: (_) => RefereeScreen(matchType: r.matchType, matchId: r.idMatch)),
                            );
                            if (mounted) _load(silent: true);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      HomeStatsBar(
                        played: played,
                        won: stats?.matchesWon ?? 0,
                        winRate: played == 0 ? "—" : "${(stats!.winRate * 100).round()}%",
                      ),
                      // Con un partido por jugar: el partido y cómo vas en tu
                      // grupo, al medio del Inicio (bajo tu perfil y tus
                      // números; arriba del todo el perfil quedaba perdido).
                      if (nm != null) ...[
                        const SizedBox(height: 12),
                        matches,
                        if (_myStanding != null && nm.matchType == "group") ...[
                          const SizedBox(height: 12),
                          HomeGroupCard(
                            groupName: nm.groupName ?? "",
                            position: _myStanding!.played == 0 ? null : _myStanding!.position,
                            total: _groupSize,
                            won: _myStanding!.won,
                            lost: _myStanding!.lost,
                            setsFor: _myStanding!.setsFor,
                            setsAgainst: _myStanding!.setsAgainst,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.myCategory,
                              arguments: {
                                "tournamentId": nm.idTournament,
                                "tournamentName": nm.tournamentName,
                                "categoryId": nm.idCategory,
                                "categoryLabel": nm.categoryDisplay,
                              },
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      HomeStreakCard(
                        form: _form,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.history),
                      ),
                      // Sin partido: la invitación a buscar campeonatos, abajo.
                      if (nm == null) ...[
                        const SizedBox(height: 12),
                        Expanded(
                          child: HomeNoMatchCard(
                            loading: _loading,
                            onBrowse: () =>
                                AppShellScope.of(context)?.switchTab(3),
                            upcomingName: _upcoming?.tournamentName,
                            upcomingWhen: _upcoming == null ? null : _whenLabel(_upcoming!.date),
                            upcomingCategory: _upcoming?.categoryName,
                            onUpcoming: _openUpcoming,
                            openCount: _openCount,
                          ),
                        ),
                      ],
                    ]),
                  )),
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
            const SizedBox(height: 12),
            // Con muchos partidos los puntitos no caben: se muestra "3 / 12".
            if (pages.length > 6)
              Text(
                "${_page + 1} / ${pages.length}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
