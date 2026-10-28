import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/features/home/presentation/my_matches_screen.dart";
import "package:myttmi/core/constants/app_typography.dart";
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
  // Mi fila en la tabla de CADA categoría donde estoy jugando grupos (antes
  // solo la del próximo partido destacado: con 3 categorías se veía una).
  List<({PlayerNextMatch match, PlayerStanding standing, int size})> _myGroups = const [];
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
        _loadGroups(),
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
      mineList = [for (final e in current) if (seen.add(e.tournamentId)) e];
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

  /// Estoy jugando ahora: alguno de mis próximos partidos ya tiene mesa.
  bool get _playingNow {
    final d = _dashboard;
    if (d == null) return false;
    return [if (d.nextMatch != null) d.nextMatch!, ...d.otherNextMatches].any((m) => m.tableNumber != null);
  }

  /// Lista de los partidos que me toca arbitrar, para elegir uno.
  Future<RefereeMatch?> _pickRefereeMatch() {
    return showModalBottomSheet<RefereeMatch>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PanelTitleBar(title: "Partidos para arbitrar"),
            const SizedBox(height: 6),
            for (final r in _refMatches)
              ListTile(
                leading: Icon(Icons.scoreboard_rounded, color: r.tableNumber != null ? AppColors.scorifyLive : AppColors.scorifyMint),
                title: Text("${r.player1Name} vs ${r.player2Name}",
                    style: const TextStyle(color: AppColors.scorifyText, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [r.tableNumber != null ? "Mesa ${r.tableNumber}" : "Esperando mesa", r.categoryDisplay].join(" · "),
                  style: const TextStyle(color: AppColors.scorifyTextMuted),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextFaint),
                onTap: () => Navigator.pop(sheet, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Mi campeonato en curso (grupos o llave), si hay — aunque ya no me
  /// quede partido por jugar.
  CalendarEvent? get _live {
    for (final e in _mine) {
      if (e.inProgress) return e;
    }
    return null;
  }

  /// Con varios campeonatos inscritos, "Ver" deja elegir cuál abrir (antes
  /// abría siempre el primero y el resto no se podía ver).
  Future<void> _pickTournament() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PanelTitleBar(title: "Mis campeonatos"),
            const SizedBox(height: 6),
            for (final e in _mine)
              ListTile(
                leading: Icon(
                  e.inProgress ? Icons.sports_tennis_rounded : Icons.event_rounded,
                  color: e.inProgress ? AppColors.scorifyLive : AppColors.scorifyMint,
                ),
                title: Text(e.tournamentName, style: const TextStyle(color: AppColors.scorifyText, fontWeight: FontWeight.w600)),
                subtitle: Text(e.inProgress ? "En juego" : "Por jugar", style: const TextStyle(color: AppColors.scorifyTextMuted)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextFaint),
                onTap: () => Navigator.pop(sheet, e.tournamentId),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (id != null && mounted) _openTournament(id);
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
  Future<void> _loadGroups() async {
    final me = _profile?.idUser;
    final d = _dashboard;
    if (me == null || d == null) return;
    // Un partido de grupo por categoría (próximo + los de las otras).
    final seen = <String>{};
    final groupMatches = [if (d.nextMatch != null) d.nextMatch!, ...d.otherNextMatches]
        .where((m) => m.matchType == "group" && seen.add(m.idCategory))
        .toList();
    try {
      final views = await Future.wait(groupMatches.map((m) => _playerApi.getCategoryView(m.idTournament, m.idCategory)));
      final out = <({PlayerNextMatch match, PlayerStanding standing, int size})>[];
      for (var i = 0; i < groupMatches.length; i++) {
        final mine = views[i].standings.where((r) => r.idUser == me);
        if (mine.isNotEmpty) out.add((match: groupMatches[i], standing: mine.first, size: views[i].standings.length));
      }
      if (mounted) setState(() => _myGroups = out);
    } catch (_) {}
  }

  void _openCategory(PlayerNextMatch m) => Navigator.pushNamed(
        context,
        AppRoutes.myCategory,
        arguments: {
          "tournamentId": m.idTournament,
          "tournamentName": m.tournamentName,
          "categoryId": m.idCategory,
          "categoryLabel": m.categoryDisplay,
        },
      );

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
      // "¿Cuánto me falta?": el servidor ya manda la posición en la cola y
      // la mesa que bloquea al rival — antes se mostraba solo "En cola".
      table: m.tableNumber != null
          ? "Mesa ${m.tableNumber}"
          : m.blockingTableNumber != null
              ? "Tras mesa ${m.blockingTableNumber}"
              : m.queuePosition != null
                  ? (m.queuePosition! <= 1 ? "Eres el próximo" : "Faltan ${m.queuePosition! - 1}")
                  : "En cola",
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
        Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
          // Un solo scroll con el encabezado adentro (sube con el contenido).
          // El contenido llena exactamente la pantalla (alto mínimo =
          // pantalla), así que solo se desplaza si de verdad no cabe; antes,
          // con el encabezado en un scroll aparte, siempre se podía subir
          // la pantalla aunque sobrara espacio.
          child: LayoutBuilder(
              // Deslizar hacia abajo recarga el inicio.
              builder: (context, box) => RefreshIndicator(
                color: AppColors.scorifyMint,
                onRefresh: _load,
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 28),
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
                      ...staggerChildren([
                      // Sin saludo grande arriba ("Buenas noches, Ignacio"): ocupaba
                      // un tercio de la pantalla y empujaba los partidos hacia abajo.
                      // Mientras juego en una mesa no se ofrece arbitrar: primero
                      // mi partido (el servidor tampoco deja estar en dos mesas).
                      // Estructura fija del Inicio: arbitraje → próximo partido →
                      // tus grupos → campeonato → accesos. Cada sección está
                      // siempre; sin datos muestra "No se registran…" (antes se
                      // escondía y el Inicio de alguien nuevo quedaba vacío).
                      if (!_playingNow) ...[
                        if (_refMatches.isEmpty)
                          const HomeEmptyCard(
                            title: "Arbitraje",
                            icon: Icons.scoreboard_rounded,
                            message: "No se registran partidos para arbitrar",
                            hint: "Cuando un organizador te asigne un partido como árbitro, aparecerá aquí.",
                          )
                        else
                        HomeRefereeCard(
                          title: "${_refMatches.first.player1Name} vs ${_refMatches.first.player2Name}",
                          subtitle: [
                            _refMatches.first.tableNumber != null ? "Mesa ${_refMatches.first.tableNumber}" : "Esperando mesa",
                            _refMatches.first.categoryDisplay,
                            if (_refMatches.length > 1) "+${_refMatches.length - 1} más",
                          ].join(" · "),
                          // Con varios partidos por arbitrar se elige cuál (antes
                          // abría siempre el primero y "+N más" no se podía tocar).
                          onTap: () async {
                            final r = _refMatches.length == 1 ? _refMatches.first : await _pickRefereeMatch();
                            if (r == null || !context.mounted) return;
                            await Navigator.push(
                              context,
                              CyberPageRoute(builder: (_) => RefereeScreen(matchType: r.matchType, matchId: r.idMatch)),
                            );
                            if (mounted) _load(silent: true);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (nm == null) ...[
                        HomeEmptyCard(
                          title: "Próximo partido",
                          icon: Icons.calendar_month_rounded,
                          message: "No se registran partidos programados",
                          hint: _live != null
                              ? "Tu campeonato está en curso: tu próximo partido aparecerá apenas lo programen."
                              : "Inscríbete en un campeonato y aquí verás tu próximo partido, la mesa y tu rival.",
                          action: _live == null ? "Buscar campeonatos" : null,
                          onAction: () => AppShellScope.of(context)?.switchTab(3, link: true),
                        ),
                      ] else ...[
                        matches,
                        // Más de un partido por jugar: acceso a la lista completa.
                        if ((_dashboard?.otherNextMatches.length ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          AppButton.outline(
                            label: "Ver todos mis partidos",
                            icon: Icons.format_list_bulleted_rounded,
                            onPressed: () async {
                              final d = _dashboard!;
                              final ids = {d.nextMatch!.idTournament, ...d.otherNextMatches.map((m) => m.idTournament)}.toList();
                              await Navigator.push(
                                context,
                                CyberPageRoute(builder: (_) => MyMatchesScreen(myUserId: _profile?.idUser ?? "", tournamentIds: ids)),
                              );
                              if (mounted) _load(silent: true);
                            },
                          ),
                        ],
                      ],
                      // Una categoría: la tarjeta grande de siempre. Varias: una
                      // fila por categoría. Ninguna: el panel vacío.
                      ...[
                        if (_myGroups.isEmpty) ...[
                          const SizedBox(height: 12),
                          const HomeEmptyCard(
                            title: "Tus grupos",
                            icon: Icons.groups_rounded,
                            message: "No se registran grupos",
                            hint: "Cuando empiece la fase de grupos de tu campeonato verás aquí tu posición y tus resultados.",
                          ),
                        ] else if (_myGroups.length == 1) ...[
                          const SizedBox(height: 12),
                          HomeGroupCard(
                            groupName: _myGroups.first.match.groupName ?? "",
                            position: _myGroups.first.standing.played == 0 ? null : _myGroups.first.standing.position,
                            total: _myGroups.first.size,
                            won: _myGroups.first.standing.won,
                            lost: _myGroups.first.standing.lost,
                            setsFor: _myGroups.first.standing.setsFor,
                            setsAgainst: _myGroups.first.standing.setsAgainst,
                            onTap: () => _openCategory(_myGroups.first.match),
                          ),
                        ] else if (_myGroups.length > 1) ...[
                          const SizedBox(height: 12),
                          _MyGroupsCard(groups: _myGroups, onOpen: _openCategory),
                        ],
                        const SizedBox(height: 12),
                      ],
                      // La tarjeta grande siempre está: partido > campeonato en curso >
                      // próximo campeonato > vacío. "En curso" viene de MIS inscripciones
                      // (calendario): antes, al jugar mis partidos, el campeonato
                      // desaparecía del Inicio porque se buscaba en la lista general
                      // (filtrada por región y solo con torneos por empezar).
                      if (nm == null && _live != null) ...[
                        HomeChallengeCard(
                          kicker: "CAMPEONATO EN CURSO",
                          name: _live!.tournamentName,
                          subtitle: _live!.categoryName,
                          place: _live!.location,
                          chip: "En juego",
                          button: "Ver mi categoría",
                          onTap: () async {
                            final e = _live!;
                            await Navigator.pushNamed(context, AppRoutes.myCategory, arguments: {
                              "tournamentId": e.tournamentId,
                              "tournamentName": e.tournamentName,
                              "categoryId": e.categoryId,
                              "categoryLabel": e.categoryName,
                            });
                            if (mounted) _load(silent: true);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (nm == null && _live == null && _challenge != null) ...[
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
                                gradient: homeGradientTeal,
                                icon: Icons.emoji_events_rounded,
                                value: "${_mine.length}",
                                caption: _mine.length == 1 ? "inscrito" : "inscritos",
                                title: "Mis campeonatos",
                                action: _mine.isEmpty ? "Explorar" : "Ver",
                                onTap: () => _mine.isEmpty
                                    ? AppShellScope.of(context)?.switchTab(3, link: true)
                                    : _mine.length == 1
                                        ? _openTournament(_mine.first.tournamentId)
                                        : _pickTournament(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: HomeTile(
                                gradient: homeGradientEmerald,
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
                    ],
                  ),
                  ),
                ),
              ),
              ),
            ),
    ),
      ],
    );
  }
}

/// Foto del Inicio (estilo FIFA): jugador a la izquierda, líneas hacia la
/// derecha. Oscurecida arriba (encabezado y saludo) y abajo (tarjetas y
/// barra de navegación) para que todo se lea.
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
                                  borderRadius: BorderRadius.circular(Panel.buttonRadius),
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

/// "Tus grupos": una fila por categoría en la que juego grupos — grupo,
/// posición y partidos ganados/perdidos. Tocando la fila se abre esa categoría.
class _MyGroupsCard extends StatelessWidget {
  final List<({PlayerNextMatch match, PlayerStanding standing, int size})> groups;
  final ValueChanged<PlayerNextMatch> onOpen;
  const _MyGroupsCard({required this.groups, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeCardTitle(icon: Icons.groups_rounded, title: "Tus grupos"),
          const SizedBox(height: 10),
          for (final g in groups)
            InkWell(
              borderRadius: BorderRadius.circular(Panel.radius),
              onTap: () => onOpen(g.match),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: panelBox(),
                      child: Text(
                        g.standing.played == 0 || g.standing.position == null ? "–" : "${g.standing.position}°",
                        style: const TextStyle(fontFamily: AppTypography.display, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.scorifyText, height: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.match.categoryDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            "${(g.match.groupName ?? "Grupo").replaceFirst(RegExp(r"^GR-?", caseSensitive: false), "Grupo ")} · de ${g.size}",
                            style: AppTypography.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    Text("${g.standing.won}G · ${g.standing.lost}P",
                        style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextFaint),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
