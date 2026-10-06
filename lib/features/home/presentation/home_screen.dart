import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/shell/shell_preload.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/home/widget/home_v2.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/calendar/api/calendar_api.dart";
import "package:myttmi/features/calendar/models/calendar_event.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/core/ui/stagger_in.dart";
import 'package:flutter/material.dart';
import "package:myttmi/features/home/widget/home_layout.dart";
import "package:myttmi/core/ui/side_panel_route.dart";
import "package:myttmi/features/notifications/presentation/notifications_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/features/player/models/player_dashboard_model.dart';
import 'package:myttmi/features/player/models/player_category_view_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/notifications/api/notifications_api.dart';

import '../../../routes/app_routes.dart';

import '../widget/spin_header.dart';
import "package:myttmi/features/referee/referee_api.dart";
import "package:myttmi/features/referee/referee_screen.dart";
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
  // Modo día de torneo: mi fila en la tabla de mi grupo (del próximo
  // partido de grupo) y cuántos son en el grupo.
  PlayerStanding? _myStanding;
  // Partidos que me toca arbitrar (asignados por el organizador o por QR).
  List<RefereeMatch> _refMatches = const [];
  // Sin partido asignado: el próximo campeonato en que estás inscrito, o
  // cuántos campeonatos tienen la inscripción abierta.
  // Inicio "hacia adelante": campeonatos con inscripción abierta, tus
  // eventos de esta semana y un logro positivo (último podio).
  List<CalendarEvent> _week = const [];
  List<CalendarEvent> _mine = const [];
  Tournament? _challenge;
  // Partidos jugados, del más reciente al más antiguo.
  List<PlayerMatchHistoryItem> _history = const [];
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
      ]);
    } catch (_) {
      // Silencioso: la pantalla igual se puede usar sin estos datos.
    } finally {
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
    var week = <CalendarEvent>[];
    var mineList = <CalendarEvent>[];
    final mine = <String>{};
    try {
      final events = await CalendarApi().myEvents(from: day.subtract(const Duration(days: 30)), to: day.add(const Duration(days: 180)));
      for (final e in events) {
        mine.add(e.tournamentId);
      }
      final pending = events.where((e) => !e.finished && !e.date.isBefore(day)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      week = pending.where((e) => e.date.isBefore(day.add(const Duration(days: 14)))).take(4).toList();
      // Un renglón por campeonato: en curso (aunque haya empezado antes) o por jugar.
      final seen = <String>{};
      final current = events.where((e) => !e.finished && (e.inProgress || !e.date.isBefore(day))).toList()
        ..sort((a, b) => a.inProgress == b.inProgress ? a.date.compareTo(b.date) : (a.inProgress ? -1 : 1));
      mineList = [for (final e in current) if (seen.add(e.tournamentId)) e].take(4).toList();
    } catch (_) {}
    Tournament? challenge;
    try {
      final page = await TournamentApi().fetchTournaments(limit: 50);
      final upcoming = page.items.where((t) {
        if (t.isCancelled) return false;
        final d = DateTime.tryParse(t.eventDate ?? "");
        return d == null || !d.isBefore(day);
      }).toList()
        ..sort((a, b) => (a.eventDate ?? "9").compareTo(b.eventDate ?? "9"));
      final mineT = upcoming.where((t) => t.categories.any((c) => c.isEnrolled && c.phase != "finished"));
      final openT = upcoming.where((t) => t.categories.any((c) => c.phase == "enrollment"));
      challenge = mineT.isNotEmpty ? mineT.first : (openT.isNotEmpty ? openT.first : null);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _week = week;
      _mine = mineList;
    });
  }


  /// "Sáb. 27 Sep".
  String _whenShort(DateTime d) {
    const days = ["Lun.", "Mar.", "Mié.", "Jue.", "Vie.", "Sáb.", "Dom."];
    const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return "${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}";
  }

  /// "Buenos días / Buenas tardes / Buenas noches, Ignacio 👋".
  String? _greeting() {
    final p = _profile;
    if (p == null) return null;
    final first = ((p.firstName ?? "").trim().isNotEmpty ? p.firstName! : p.displayName).trim().split(RegExp(r"\s+")).first;
    final h = DateTime.now().hour;
    final hi = h < 12 ? "Buenos días" : h < 20 ? "Buenas tardes" : "Buenas noches";
    return "$hi, $first 👋";
  }

  /// Frase del momento bajo el saludo.
  String _contextLine() {
    final nm = _dashboard?.nextMatch;
    if (nm != null) {
      if (nm.tableNumber != null) return "¡Te toca! Ve a la mesa ${nm.tableNumber}";
      final at = nm.scheduledStartAt;
      if (at != null && DateUtils.isSameDay(at, DateTime.now())) return "Tienes un partido hoy";
      return "Tienes un partido por jugar";
    }
    if (_mine.isNotEmpty) return _mine.length == 1 ? "Estás en 1 campeonato" : "Estás en ${_mine.length} campeonatos";
    return "Busca tu próximo campeonato";
  }

  /// "Domingo, 1 Jun 2025".
  static String _dateLong(String? iso) {
    final d = DateTime.tryParse(iso ?? "");
    if (d == null) return "Fecha por definir";
    const days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return "${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}";
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
      startsAt: m.scheduledStartAt,
      tableNumber: m.tableNumber,
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

    return Stack(
      children: [
        const Positioned.fill(child: _HomeBackground()),
        Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationPopups.unread,
            builder: (context, unread, _) => SpinHeader(
            notificationsCount: unread,
            // Panel lateral en vez de página completa; al cerrarlo se
            // refresca el contador de no leídas.
            onNotifications: () => Navigator.push(
              context,
              SidePanelRoute(child: const NotificationsScreen()),
            ).then((_) => _load()),
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
                  child: IntrinsicHeight(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: staggerChildren([
                      // Portada: toma el alto que sobra (las tarjetas quedan
                      // abajo, sin hueco); texto a la derecha de la foto.
                      Expanded(
                        child: ConstrainedBox(
                        // Alto mínimo; crece si el texto no cabe (sin desborde).
                        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.27),
                        // Abajo a la derecha: la zona oscura libre (solo
                        // líneas), sin tapar al jugador.
                        child: Align(
                          alignment: const Alignment(1, 0.75),
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.50,
                            child: HomeHeroText(
                              greeting: _greeting() ?? "Hola",
                              contextLine: _contextLine(),
                              onGreeting: () => Navigator.pushNamed(context, AppRoutes.profile),
                            ),
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 8),
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
                      if (nm != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      // La tarjeta grande siempre está: partido > campeonato > vacío.
                      if (nm == null && _challenge == null) ...[
                        HomeChallengeCard(
                          kicker: "PRÓXIMO PARTIDO",
                          name: "Sin partidos programados",
                          subtitle: "Aún no tienes partidos asignados.",
                          button: "Buscar campeonatos",
                          onTap: () => AppShellScope.of(context)?.switchTab(3, link: true),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (nm == null && _challenge != null) ...[
                        HomeChallengeCard(
                          name: _challenge!.tournamentName,
                          date: _dateLong(_challenge!.eventDate),
                          place: _challenge!.address ?? _challenge!.region,
                          players: _challenge!.categories.fold<int>(0, (n, c) => n + c.enrolledCount),
                          chip: _challenge!.categories.any((c) => c.isEnrolled) ? "Inscrito" : "En inscripción",
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: _challenge);
                            if (mounted) _load(silent: true);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: HomeTile(
                                icon: Icons.emoji_events_rounded,
                                value: "${_mine.length}",
                                caption: _mine.length == 1 ? "inscrito" : "inscritos",
                                title: "Mis campeonatos",
                                action: _mine.isEmpty ? "Explorar" : "Ver",
                                onTap: () => _mine.isEmpty
                                    ? AppShellScope.of(context)?.switchTab(3, link: true)
                                    : _openTournament(_mine.first.tournamentId),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: HomeTile(
                                icon: Icons.calendar_month_rounded,
                                value: "${_week.length}",
                                caption: "en 14 días",
                                title: "Próximos eventos",
                                action: "Calendario",
                                onTap: () => AppShellScope.of(context)?.switchTab(1, link: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    ),
      ],
    );
  }
}

/// Foto del Inicio (estilo FIFA): jugador a la izquierda, líneas hacia la
/// derecha. Oscurecida arriba (encabezado y saludo) y abajo (tarjetas y
/// barra de navegación) para que todo se lea.
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: h * 0.72,
          // Decodificada al ancho de la pantalla (no a 1080 px): menos trabajo al dibujar.
          child: Image(image: ResizeImage(const AssetImage("assets/images/home_bg.png"), width: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round()), fit: BoxFit.cover, alignment: Alignment(-0.7, -0.45)),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: h * 0.72,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99060E12), Color(0x00060E12), Color(0x00060E12), Color(0xFF060E12)],
                stops: [0, 0.2, 0.6, 1],
              ),
            ),
          ),
        ),
        // Oscurece la derecha: el texto de la portada se lee sobre la foto.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: h * 0.72,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x00060E12), Color(0x00060E12), Color(0xB3060E12)],
                stops: [0, 0.4, 0.85],
              ),
            ),
          ),
        ),
      ],
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
    final w = MediaQuery.sizeOf(context).width - 32;
    return Builder(
      builder: (context) {
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
