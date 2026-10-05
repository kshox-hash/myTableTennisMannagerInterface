import "package:myttmi/core/ui/tap_sound.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/shell/shell_preload.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/player/models/achievement_model.dart";
import "package:myttmi/features/home/widget/home_v2.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
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
  // Inicio "hacia adelante": campeonatos con inscripción abierta, tus
  // eventos de esta semana y un logro positivo (último podio).
  List<Tournament> _open = const [];
  List<CalendarEvent> _week = const [];
  PlayerAchievement? _lastPodium;
  // Partidos jugados, del más reciente al más antiguo.
  List<PlayerMatchHistoryItem> _history = const [];
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
        _loadUpcoming(),
        _loadPodium(),
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

  /// Tu próximo campeonato (inscrito y sin empezar), tus eventos de los
  /// próximos 7 días y los campeonatos con la inscripción abierta.
  Future<void> _loadUpcoming() async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    CalendarEvent? next;
    var week = <CalendarEvent>[];
    final mine = <String>{};
    try {
      final events = await CalendarApi().myEvents(from: day, to: day.add(const Duration(days: 180)));
      for (final e in events) {
        mine.add(e.tournamentId);
      }
      final pending = events.where((e) => !e.finished && !e.date.isBefore(day)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final notStarted = pending.where((e) => !e.inProgress).toList();
      if (notStarted.isNotEmpty) next = notStarted.first;
      week = pending.where((e) => e.date.isBefore(day.add(const Duration(days: 7)))).take(4).toList();
    } catch (_) {}
    var open = <Tournament>[];
    try {
      final page = await TournamentApi().fetchTournaments(limit: 50);
      open = page.items.where((t) {
        if (t.isCancelled || mine.contains(t.idTournament)) return false;
        final d = DateTime.tryParse(t.eventDate ?? "");
        if (d != null && d.isBefore(day)) return false;
        return t.categories.any((c) => c.phase == "enrollment");
      }).toList()
        ..sort((a, b) => (a.eventDate ?? "9").compareTo(b.eventDate ?? "9"));
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _upcoming = next;
      _week = week;
      _open = open.take(5).toList();
      _openCount = open.length;
    });
  }

  /// Último podio (para el logro positivo del Inicio).
  Future<void> _loadPodium() async {
    final me = _profile?.idUser;
    if (me == null) return;
    try {
      final list = await _playerApi.getPlayerAchievements(me);
      list.sort((a, b) => (b.eventDate ?? "").compareTo(a.eventDate ?? ""));
      if (mounted) setState(() => _lastPodium = list.isEmpty ? null : list.first);
    } catch (_) {}
  }

  /// Logro positivo: racha de 2+ victorias o tu último podio. Si no hay nada
  /// positivo que mostrar, no aparece (el Inicio no muestra derrotas).
  Widget? _highlight() {
    final me = _profile?.idUser;
    var streak = 0;
    for (final m in _history) {
      if (m.winnerId != me) break;
      streak++;
    }
    if (streak >= 2) {
      return HomeHighlightCard(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFFA62B),
        title: "¡Vas en racha!",
        subtitle: "$streak victorias seguidas. Sigue así.",
      );
    }
    final p = _lastPodium;
    if (p != null) {
      final place = p.position == 1 ? "Campeón" : p.position == 2 ? "Subcampeón" : "3er lugar";
      return HomeHighlightCard(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFE0A526),
        title: "Tu último podio: $place",
        subtitle: "${p.categoryType} · ${p.tournamentName}",
      );
    }
    return null;
  }

  static String _dateShort(String? iso) {
    final d = DateTime.tryParse(iso ?? "");
    if (d == null) return "Fecha por definir";
    const days = ["Lun.", "Mar.", "Mié.", "Jue.", "Vie.", "Sáb.", "Dom."];
    const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return "${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}";
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

  /// "Sáb. 27 Sep".
  String _whenShort(DateTime d) {
    const days = ["Lun.", "Mar.", "Mié.", "Jue.", "Vie.", "Sáb.", "Dom."];
    const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return "${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}";
  }

  /// Sin partido asignado: próximo campeonato, o invitación a buscar.
  Widget _noMatchCard() {
    final up = _upcoming;
    return HomeCard(
      gradient: AppColors.featuredGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardTitle(
            icon: up != null ? Icons.emoji_events_rounded : Icons.calendar_month_rounded,
            title: up != null ? "Próximo campeonato" : "Próximo partido",
          ),
          const SizedBox(height: 10),
          Text(
            _loading ? "Cargando…" : (up?.tournamentName ?? "Sin partidos programados"),
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
          ),
          const SizedBox(height: 4),
          Text(
            up != null
                ? "${_whenLabel(up.date)} · ${up.categoryName}"
                : _openCount > 0
                    ? "${_openCount == 1 ? "Hay 1 campeonato" : "Hay $_openCount campeonatos"} con la inscripción abierta"
                    : "Inscríbete a un campeonato para entrar al fixture",
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, color: AppColors.scorifyTextMuted),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: up != null ? "Ver campeonato" : "Ver torneos",
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: up != null ? _openUpcoming : () => AppShellScope.of(context)?.switchTab(3),
            height: 40,
            expand: false,
          ),
        ],
      ),
    );
  }

  /// Guía para nuevos: completar el perfil, inscribirse y jugar el primer
  /// partido. Null cuando ya hizo todo (o mientras carga).
  Widget? _onboarding() {
    final p = _profile;
    if (p == null || _loading) return null;
    final profileOk = (p.country ?? "").isNotEmpty && (p.gender ?? "").isNotEmpty && p.birthDate != null;
    final played = (_dashboard?.stats.matchesPlayed ?? 0) > 0 || _history.isNotEmpty;
    final enrolled = played || _dashboard?.nextMatch != null || _upcoming != null || _week.isNotEmpty;
    if (profileOk && enrolled && played) return null;
    return HomeOnboardingCard(steps: [
      HomeStep(
        title: "Completa tu perfil (país, género y fecha de nacimiento)",
        done: profileOk,
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.profile);
          if (mounted) _load(silent: true);
        },
      ),
      HomeStep(title: "Inscríbete en un campeonato", done: enrolled, onTap: () => AppShellScope.of(context)?.switchTab(3)),
      HomeStep(title: "Juega tu primer partido", done: played, onTap: () => AppShellScope.of(context)?.switchTab(3)),
    ]);
  }

  /// "Vs. este rival": cuántas veces se enfrentaron y cómo les fue.
  String? _h2h(String? rival) {
    if (rival == null || _profile == null) return null;
    final me = _profile!.idUser;
    final games = _history.where((m) => m.player1Id == rival || m.player2Id == rival).toList();
    if (games.isEmpty) return "Primer enfrentamiento entre ustedes";
    final w = games.where((m) => m.winnerId == me).length;
    final l = games.length - w;
    return "Se han enfrentado ${games.length} ${games.length == 1 ? "vez" : "veces"} · ${w == 1 ? "1 ganado" : "$w ganados"}, ${l == 1 ? "1 perdido" : "$l perdidos"}";
  }

  Future<void> _openTournament(String id) async {
    try {
      final t = await TournamentApi().getTournamentById(id);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: t);
      if (mounted) _load(silent: true);
    } catch (_) {}
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
      final history = await _playerApi.getPlayerMatchHistory(userId, limit: 40);
      if (mounted) {
        setState(() => _history = history.where((m) => m.status == "played" || m.status == "walkover").toList());
      }
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
              // Sonido al tocar botones (se guarda en el teléfono).
              ValueListenableBuilder<bool>(
                valueListenable: TapSound.enabled,
                builder: (_, on, __) => SwitchListTile(
                  secondary: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: AppColors.scorifyText),
                  title: const Text("Sonidos", style: TextStyle(color: AppColors.scorifyText)),
                  value: on,
                  activeThumbColor: AppColors.scorifyOnMint,
                  activeTrackColor: AppColors.scorifyMint,
                  onChanged: TapSound.setEnabled,
                ),
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
    if (m == null) return const SizedBox.shrink();
    final when = m.scheduledStartAt == null
        ? "Por definir"
        : "${_whenShort(m.scheduledStartAt!)}\n${m.scheduledStartAt!.hour.toString().padLeft(2, "0")}:${m.scheduledStartAt!.minute.toString().padLeft(2, "0")}";
    return HomeMatchCard(
      tournamentName: [m.tournamentName, if (stage.isNotEmpty) stage].join(" · "),
      myId: _profile?.idUser,
      myAvatarUrl: _profile?.avatarUrl,
      myClub: _profile?.club,
      opponentId: m.opponentId,
      opponentName: m.opponentName ?? "Por definir",
      opponentAvatarUrl: m.opponentAvatarUrl,
      opponentClub: m.opponentClub,
      when: when,
      table: m.tableNumber != null ? "Mesa ${m.tableNumber}" : "En cola",
      place: m.address,
      h2h: _h2h(m.opponentId),
      onDetail: () => Navigator.pushNamed(
        context,
        AppRoutes.matchDetail,
        arguments: {"matchType": m.matchType, "matchId": m.idMatch},
      ),
      onOpponent: m.opponentId == null
          ? null
          : () => Navigator.pushNamed(
                context,
                AppRoutes.playerProfile,
                arguments: {"userId": m.opponentId, "playerName": m.opponentName ?? "Jugador"},
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nm = _dashboard?.nextMatch;


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
                  // La tarjeta de partido (o la de sin partido) toma el alto
                  // que sobra, así llega hasta abajo en cualquier caso.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: staggerChildren([
                      HomeProfileRow(
                        userId: _profile?.idUser,
                        name: (_profile?.displayName.isNotEmpty ?? false) ? _profile!.displayName : "Jugador",
                        country: _profile?.country,
                        club: _profile?.club,
                        age: _profile?.age,
                        gender: _profile?.gender,
                        avatarUrl: _profile?.avatarUrl,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                      const SizedBox(height: 14),
                      if (_onboarding() != null) ...[
                        _onboarding()!,
                        const SizedBox(height: 12),
                      ],
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
                      if (nm != null) matches else _noMatchCard(),
                      if (nm != null && _myStanding != null && nm.matchType == "group") ...[
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
                      if (_highlight() != null) ...[
                        const SizedBox(height: 12),
                        _highlight()!,
                      ],
                      if (_week.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        HomeWeekCard(
                          onCalendar: () => AppShellScope.of(context)?.switchTab(1),
                          items: [
                            for (final e in _week)
                              HomeWeekItem(
                                day: const ["LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB", "DOM"][e.date.weekday - 1],
                                date: "${e.date.day}",
                                title: e.tournamentName,
                                subtitle: [e.categoryName, if ((e.location ?? "").trim().isNotEmpty) e.location!.trim()].join(" · "),
                                onTap: () => _openTournament(e.tournamentId),
                              ),
                          ],
                        ),
                      ],
                      if (_open.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        HomeOpenTournamentsCard(
                          onAll: () => AppShellScope.of(context)?.switchTab(3),
                          items: [
                            for (final t in _open)
                              HomeOpenItem(
                                name: t.tournamentName,
                                when: _dateShort(t.eventDate),
                                place: t.address ?? t.region,
                                onTap: () async {
                                  await Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: t);
                                  if (mounted) _load(silent: true);
                                },
                              ),
                          ],
                        ),
                      ],
                    ]),
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

  void _go(int page, double w) {
    _controller.animateTo(page * w, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
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
            // ‹ puntitos › (con muchos partidos, "3 / 12" en vez de puntitos).
            Row(
              children: [
                PagerButton(next: false, onTap: _page > 0 ? () => _go(_page - 1, w) : null),
                Expanded(
                  child: pages.length > 6
                      ? Center(
                          child: Text(
                            "${_page + 1} / ${pages.length}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < pages.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _page ? AppColors.scorifyMint : AppColors.scorifySurface2,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                ),
                PagerButton(next: true, onTap: _page < pages.length - 1 ? () => _go(_page + 1, w) : null),
              ],
            ),
          ],
        );
      },
    );
  }
}
