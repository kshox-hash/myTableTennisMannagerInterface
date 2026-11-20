import "package:myttmi/core/monitoring.dart";
import "package:myttmi/core/clubs/club_crests.dart";
import "package:myttmi/core/ui/stagger_in.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/ui/card_border.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:url_launcher/url_launcher.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:share_plus/share_plus.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/confirm_dialog.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/routes/app_routes.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";

const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
const _weekdays = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"];

// "sábado 4 oct · 10:00"
String? _formatWhen(String? date, String? time) {
  final d = DateTime.tryParse(date ?? "");
  if (d == null) return null;
  final hhmm = (time ?? "").length >= 5 ? time!.substring(0, 5) : null;
  final day = "${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}";
  return hhmm == null ? day : "$day · $hhmm hrs";
}

// Campeonato de varios días: "Sáb 14 – Dom 15 Dic 2026 · 10:00 hrs".
String? _formatWhenRange(String? date, String? end, String? time) {
  final d = DateTime.tryParse(date ?? "");
  final e = DateTime.tryParse(end ?? "");
  if (d == null || e == null || !e.isAfter(d)) return _formatWhen(date, time);
  final hhmm = (time ?? "").length >= 5 ? time!.substring(0, 5) : null;
  final from = d.month == e.month ? "${_weekdays[d.weekday - 1]} ${d.day}" : "${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}";
  final to = "${_weekdays[e.weekday - 1]} ${e.day} ${_months[e.month - 1]} ${e.year}";
  return hhmm == null ? "$from – $to" : "$from – $to · $hhmm hrs";
}

// Día de juego de una categoría: "Sáb 14 Dic · 10:00 hrs".
String? _categoryDay(String? date, String? time) {
  final d = DateTime.tryParse(date ?? "");
  if (d == null) return null;
  final hhmm = (time ?? "").length >= 5 ? time!.substring(0, 5) : null;
  final day = "${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}";
  return hhmm == null ? day : "$day · $hhmm hrs";
}

// 5000 → "$5.000"
String _money(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(".");
    b.write(s[i]);
  }
  return "\$$b";
}

String _levelLabel(String l) => switch (l) {
      "regional" => "regional",
      "nacional" => "nacional",
      _ => "local",
    };

String _genderLabel(String g) => switch (g) {
      "male" => "Masculino",
      "female" => "Femenino",
      "mixed" => "Mixto",
      _ => g,
    };

/// La categoría acepta inscripciones online: en inscripciones y abierta, o
/// en grupos con la inscripción reabierta por el organizador (el servidor
/// la acepta hasta que se arma la llave).
bool _acceptsEnrollment(TournamentCategory c) =>
    c.status == "active" && (c.phase == "enrollment" || c.phase == "groups");

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final TournamentApi api = TournamentApi();
  final PlayerApi _playerApi = PlayerApi();
  late Tournament _tournament;
  List<TournamentParticipant> _participants = [];
  bool _participantsLoaded = false;
  String? _subscribingId;

  /// Con más de estas categorías se muestran como filas compactas.
  static const _compactFrom = 3;
  /// Con más de estas, aparece el filtro (Todas / Damas / Varones / Abiertas).
  static const _filtersFrom = 6;
  String _catFilter = "all";
  /// Categoría abierta: null = la por defecto (la primera tuya), "" = ninguna.
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _refresh();
  }

  /// Filtradas y con las tuyas primero (el resto en el orden del organizador).
  List<TournamentCategory> _visibleCats(List<TournamentCategory> cats) {
    final out = cats.where((c) => switch (_catFilter) {
          "female" => c.gender == "female",
          "male" => c.gender == "male",
          "open" => !_tournament.isCancelled && _acceptsEnrollment(c),
          _ => true,
        }).toList();
    final mine = out.where((c) => c.isEnrolled).toList();
    return [...mine, ...out.where((c) => !c.isEnrolled)];
  }

  String? _expandedCatId(List<TournamentCategory> cats) {
    if (_expandedId != null) return _expandedId!.isEmpty ? null : _expandedId;
    for (final c in cats) {
      if (c.isEnrolled) return c.idCategory;
    }
    return null;
  }

  // Trae el torneo fresco (cupos/inscritos al día) y la lista de inscritos.
  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        api.getTournamentById(_tournament.idTournament),
        _playerApi.getTournamentParticipants(_tournament.idTournament),
      ]);
      if (!mounted) return;
      setState(() {
        _tournament = results[0] as Tournament;
        _participants = results[1] as List<TournamentParticipant>;
        _participantsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _participantsLoaded = true);
    }
  }

  // El campeonato "empezó" cuando alguna categoría salió de inscripciones
  // (grupos generados, llave o terminada). Antes de eso no hay partidos ni
  // mesas que mirar, así que esos accesos se esconden.
  bool get _started => _tournament.categories.any((c) => c.phase != "enrollment");

  /// Alguna categoría acepta inscripciones ahora (misma regla que el botón
  /// "Inscribirme" de cada categoría).
  bool get _anyOpen => !_tournament.isCancelled && _tournament.categories.any(_acceptsEnrollment);

  Future<void> _unsubscribe(TournamentCategory c) async {
    final ok = await confirmAction(
      context,
      title: "Anular inscripción",
      message: "¿Seguro que quieres anular tu inscripción en ${c.categoryLabel}? Puedes volver a inscribirte mientras sigan abiertas las inscripciones.",
      confirmLabel: "Anular",
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _subscribingId = c.idCategory);
    try {
      await api.unsubscribeFromCategory(tournamentId: _tournament.idTournament, categoryId: c.idCategory);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      showToast(context, "Anulaste tu inscripción en ${c.categoryLabel}");
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _subscribingId = null);
    }
  }

  Future<void> _subscribe(TournamentCategory c) async {
    final ok = await confirmAction(
      context,
      title: "Confirmar inscripción",
      message: "¿Quieres inscribirte en ${c.categoryLabel} de ${_tournament.tournamentName}?\n\n"
          "Inscripción: ${c.inscriptionPrice > 0 ? _money(c.inscriptionPrice) : "Gratis"}",
      confirmLabel: "Inscribirme",
    );
    if (!ok || !mounted) return;
    setState(() => _subscribingId = c.idCategory);
    try {
      await api.subscribeToCategory(
        tournamentId: _tournament.idTournament,
        categoryId: c.idCategory,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      Monitoring.log("inscripcion", {"categoria": c.categoryLabel});
      showToast(context, "Quedaste inscrito en ${c.categoryLabel}");
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _subscribingId = null);
    }
  }

  void _goMyCategory(TournamentCategory c) {
    Navigator.pushNamed(
      context,
      AppRoutes.myCategory,
      arguments: {
        "tournamentId": _tournament.idTournament,
        "tournamentName": _tournament.tournamentName,
        "categoryId": c.idCategory,
        "categoryLabel": c.categoryLabel,
      },
    );
  }

  void _go(String route) {
    Navigator.pushNamed(
      context,
      route,
      arguments: {
        "tournamentId": _tournament.idTournament,
        "tournamentName": _tournament.tournamentName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _tournament;
    final cats = t.categories;

    final header = TopHeader(
      title: t.isLeague ? "Liga" : "Campeonato",
      actions: [
        // Los campeonatos son privados: se suman jugadores
        // compartiendo este link (abre la app si la tienen).
        HeaderIconButton(
          icon: Icons.ios_share_rounded,
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text: "${t.tournamentName}\n${AppConfig.webBaseUrl}/torneos/${t.idTournament}",
              subject: t.tournamentName,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        // Sin SafeArea arriba: la tarjeta con foto llega hasta el borde
        // superior, detrás del encabezado (sin margen arriba ni a los lados).
        child: SafeArea(
          top: false,
          child: ScrollingHeaderPage(
              header: _participantsLoaded
                  ? [_HeroCard(tournament: t, started: _started, anyOpen: _anyOpen, header: header)]
                  : [
                      SizedBox(height: MediaQuery.paddingOf(context).top + 16),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: header),
                      const SizedBox(height: 14),
                    ],
              // Primera carga: esqueleto en vez de los datos de la lista (cupos
              // e inscritos viejos que después saltan).
              body: !_participantsLoaded
                      ? const LoadingState()
                      : RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 14, bottom: 24),
                      children: staggerChildren([
                        for (final w in <Widget>[
                        // Seguir como visita: solo si no juega (el inscrito ya
                        // recibe sus propios avisos) y el campeonato sigue en pie.
                        if (!t.isCancelled && !cats.any((c) => c.isEnrolled)) ...[
                          _FollowCard(tournamentId: t.idTournament),
                          const SizedBox(height: 14),
                        ],
                        // Liga: la tabla y las fechas viven en su página (igual que en la web).
                        if (t.isLeague) ...[
                          _QuickLink(
                            icon: Icons.leaderboard_rounded,
                            label: "Ver tabla de la liga",
                            onTap: () => launchUrl(
                              Uri.parse("${AppConfig.webBaseUrl}/ligas/${t.idTournament}"),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_started) ...[
                          Row(
                            children: [
                              Expanded(child: _QuickLink(icon: Icons.sports_tennis_rounded, label: "Partidos", onTap: () => _go(AppRoutes.tournamentMatches))),
                              const SizedBox(width: 10),
                              Expanded(child: _QuickLink(icon: Icons.people_alt_rounded, label: "Jugadores", onTap: () => _go(AppRoutes.tournamentPlayers))),
                            ],
                          ),
                        ] else if (!t.isCancelled)
                          _NoticeBanner(
                            text: _anyOpen
                                ? "Inscripciones abiertas. Los grupos, partidos y mesas aparecen cuando el organizador cierre las inscripciones."
                                : "Inscripciones cerradas. Los grupos, partidos y mesas aparecen cuando el organizador arme los grupos.",
                          ),
                        const SizedBox(height: 20),
                        const _SectionLabel("Categorías"),
                        const SizedBox(height: 12),
                        if (cats.isEmpty)
                          Text("Este campeonato no tiene categorías aún.", style: AppTypography.bodyMuted)
                        // Muchas categorías: filtro + filas compactas que se
                        // abren al tocarlas (una a la vez); las tuyas primero.
                        else if (cats.length > _compactFrom) ...[
                          if (cats.length > _filtersFrom) ...[
                            _CategoryFilterBar(value: _catFilter, onChanged: (v) => setState(() => _catFilter = v)),
                            const SizedBox(height: 12),
                          ],
                          if (_visibleCats(cats).isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text("No hay categorías con este filtro.", style: AppTypography.bodyMuted),
                            ),
                          for (final c in _visibleCats(cats)) ...[
                            if (_expandedCatId(cats) == c.idCategory) ...[
                              _CategoryRow(
                                category: c,
                                enrolled: _participants.where((p) => p.idCategory == c.idCategory).length,
                                cancelled: t.isCancelled,
                                expanded: true,
                                onTap: () => setState(() => _expandedId = ""),
                              ),
                              _CategoryCard(
                                tournamentId: t.idTournament,
                                category: c,
                                tournamentCancelled: t.isCancelled,
                                participants: _participants.where((p) => p.idCategory == c.idCategory).toList(),
                                participantsLoaded: _participantsLoaded,
                                subscribing: _subscribingId == c.idCategory,
                                onSubscribe: () => _subscribe(c),
                                onUnsubscribe: () => _unsubscribe(c),
                                onOpen: () => _goMyCategory(c),
                                onSeeAll: () => _go(AppRoutes.tournamentPlayers),
                              ),
                              const SizedBox(height: 8),
                            ] else ...[
                              _CategoryRow(
                                category: c,
                                enrolled: _participants.where((p) => p.idCategory == c.idCategory).length,
                                cancelled: t.isCancelled,
                                expanded: false,
                                onTap: () => setState(() => _expandedId = c.idCategory),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ],
                        ]
                        else
                          for (final c in cats) ...[
                            _CategoryCard(
                              tournamentId: t.idTournament,
                              category: c,
                              tournamentCancelled: t.isCancelled,
                              participants: _participants.where((p) => p.idCategory == c.idCategory).toList(),
                              participantsLoaded: _participantsLoaded,
                              subscribing: _subscribingId == c.idCategory,
                              onSubscribe: () => _subscribe(c),
                              onUnsubscribe: () => _unsubscribe(c),
                              onOpen: () => _goMyCategory(c),
                              onSeeAll: () => _go(AppRoutes.tournamentPlayers),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ]) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: w),
                      ]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Abre WhatsApp con el organizador (número chileno sin +56 se completa).
Future<void> _whatsApp(BuildContext context, Tournament t) async {
  var digits = (t.contactPhone ?? "").replaceAll(RegExp(r"\D"), "");
  if (digits.length == 9 && digits.startsWith("9")) digits = "56$digits";
  final text = Uri.encodeComponent("Hola, te escribo por el campeonato ${t.tournamentName}.");
  final ok = await launchUrl(Uri.parse("https://wa.me/$digits?text=$text"), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showToast(context, "No se pudo abrir WhatsApp.", error: true);
}

class _HeroCard extends StatelessWidget {
  final Tournament tournament;
  final bool started;
  final bool anyOpen;
  /// Encabezado (← Campeonato · compartir) que va encima de la foto.
  final Widget header;
  const _HeroCard({required this.tournament, required this.started, required this.anyOpen, required this.header});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final when = _formatWhenRange(t.eventDate, t.endDate, t.eventTime);
    final enrolled = t.categories.fold<int>(0, (s, c) => s + c.enrolledCount);
    final allFinite = t.categories.isNotEmpty && t.categories.every((c) => c.quotas != null);
    final quota = allFinite ? t.categories.fold<int>(0, (s, c) => s + (c.quotas ?? 0)) : null;
    final allFinished = t.categories.isNotEmpty && t.categories.every((c) => c.phase == "finished");
    final (chipLabel, chipBg, chipFg) = t.isCancelled
        ? ("Cancelado", AppColors.scorifyNegative, Colors.white)
        : allFinished
            ? ("Finalizado", AppColors.scorifySurface2, AppColors.scorifyTextMuted)
            : started
                ? ("En juego", AppColors.scorifyButterfly, AppColors.scorifyOnButterfly)
                : anyOpen
                    ? ("Inscripciones abiertas", AppColors.scorifyMint, AppColors.scorifyOnMint)
                    : ("Inscripciones cerradas", AppColors.scorifyPending, AppColors.scorifyOnMint);

    // Cabecera de borde a borde con el encabezado arriba; abajo termina con un
    // filete, sin esquinas redondeadas.
    final topInset = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.scorifyCardBorderStrong))),
      child: GlassCard(
      // Sin foto (solo el login la tiene): fondo de la página y filete abajo.
      fillColor: Colors.transparent,
      square: true,
      padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: chipLabel, bg: chipBg, fg: chipFg),
              // Si suma puntos y de qué nivel (lo define el organizador).
              _Pill(
                label: t.isRanked ? "Puntúa · nivel ${_levelLabel(t.rankingLevel)}" : "No puntúa para el ranking",
                bg: AppColors.scorifySurface2,
                fg: t.isRanked ? AppColors.scorifyText : AppColors.scorifyTextMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.tournamentName,
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
              color: AppColors.scorifyInk,
              // Sombra solo en oscuro (en claro ensuciaba el título).
              shadows: AppColors.isLight ? null : const [Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2))],
            ),
          ),
          const SizedBox(height: 10),
          // Filete de acento bajo el título (azul de marca → hielo).
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: [AppColors.scorifyMint, AppColors.scorifyCyan]),
            ),
          ),
          const SizedBox(height: 14),
          if (when != null) _InfoRow(icon: Icons.calendar_today_rounded, text: when),
          // La dirección abre Google Maps (cómo llegar al gimnasio).
          if ((t.address ?? "").trim().isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(Panel.radius),
              onTap: () => launchUrl(
                Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent([t.address, t.region].whereType<String>().join(", "))}"),
                mode: LaunchMode.externalApplication,
              ),
              child: Row(
                children: [
                  Expanded(child: _InfoRow(icon: Icons.place_rounded, text: t.address!)),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8, left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.scorifyMint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.scorifyMint.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Cómo llegar", style: _meta.copyWith(color: AppColors.scorifyCyan, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(Icons.north_east_rounded, size: 13, color: AppColors.scorifyCyan),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if ((t.region ?? "").trim().isNotEmpty) _InfoRow(icon: Icons.map_rounded, text: t.region!),
          if ((t.description ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(t.description!, style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: 16),
          // Franja de cifras: vidrio oscuro con filete azul arriba y divisores.
          ClipRRect(
            borderRadius: BorderRadius.circular(Panel.radius),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.isLight ? AppColors.scorifyCardFill : const Color(0x8C070B12),
                borderRadius: BorderRadius.circular(Panel.radius),
                border: Border.all(color: AppColors.scorifyCardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.scorifyMint.withValues(alpha: 0),
                        AppColors.scorifyMint,
                        AppColors.scorifyMint.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _Kpi(value: "${t.categories.length}", label: t.categories.length == 1 ? "Categoría" : "Categorías"),
                          VerticalDivider(width: 1, thickness: 1, color: AppColors.scorifyCardBorder),
                          _Kpi(value: "$enrolled", label: enrolled == 1 ? "Inscrito" : "Inscritos"),
                          VerticalDivider(width: 1, thickness: 1, color: AppColors.scorifyCardBorder),
                          _Kpi(value: quota != null ? "$quota" : "∞", label: "Cupos"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contacto con el organizador (si dejó su WhatsApp en la web).
          if ((t.contactPhone ?? "").replaceAll(RegExp(r"\D"), "").length >= 8) ...[
            const SizedBox(height: 12),
            AppButton.outline(
              label: "Escribir al organizador",
              icon: Icons.chat_rounded,
              onPressed: () => _whatsApp(context, t),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String tournamentId;
  final TournamentCategory category;
  final bool tournamentCancelled;
  final List<TournamentParticipant> participants;
  final bool participantsLoaded;
  final bool subscribing;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;
  final VoidCallback onOpen;
  /// Lista completa de inscritos (pantalla aparte): la tarjeta muestra a
  /// lo más [_maxInline] para no estirarse con 50 jugadores.
  final VoidCallback onSeeAll;

  const _CategoryCard({
    required this.tournamentId,
    required this.category,
    this.tournamentCancelled = false,
    required this.participants,
    required this.participantsLoaded,
    required this.subscribing,
    required this.onSubscribe,
    required this.onUnsubscribe,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;
  static const _maxInline = 8;
  // Categoría terminada: los 3 primeros, para mostrar el podio en la
  // tarjeta (lo primero que quiere saber quien mira: quién ganó).
  List<CategoryStandingRow>? _podium;

  @override
  void initState() {
    super.initState();
    if (widget.category.phase == "finished") {
      ClubCrests.load(widget.tournamentId, widget.category.idCategory);
      PlayerApi().getCategoryStandings(widget.tournamentId, widget.category.idCategory).then((r) {
        if (!mounted) return;
        final top = r.standings.where((s) => s.position <= 3).toList()..sort((a, b) => a.position.compareTo(b.position));
        setState(() => _podium = top);
      }).catchError((_) {});
    }
  }

  Widget _podiumBlock() {
    final p = _podium!;
    final champ = p.where((r) => r.position == 1).firstOrNull;
    final rest = p.where((r) => r.position != 1).toList();
    const gold = Color(0xFFE6B94C), silver = Color(0xFFC0C7CF), bronze = Color(0xFFCD8B55);
    Color medal(int pos) => pos == 1 ? gold : pos == 2 ? silver : bronze;
    return Container(
      // Más oscuro que la tarjeta: el podio se despega.
      decoration: BoxDecoration(color: AppColors.isLight ? const Color(0xFFF4F4F6) : const Color(0xFF0F1620), borderRadius: BorderRadius.circular(Panel.radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campeón: lo que más se quiere saber, destacado.
          if (champ != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              // Dorado oscuro sólido con filo dorado a la izquierda (antes un tinte que se veía gris).
              decoration: BoxDecoration(
                color: AppColors.isLight ? Color(0xFFFFF4DA) : Color(0xFF2A2210),
                border: Border(left: BorderSide(color: gold, width: 3)),
              ),
              child: Row(
                children: [
                  // Ícono (no emoji): copa dorada dentro de un círculo con tinte.
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: gold.withValues(alpha: 0.18)),
                    child: const Icon(Icons.emoji_events_rounded, color: gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CAMPEÓN", style: _meta.copyWith(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: gold)),
                        const SizedBox(height: 2),
                        Text(champ.playerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppTypography.body, fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                        ClubLine(idUser: champ.idUser, club: champ.clubName, style: _meta.copyWith(fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 2.º y 3.º: filas compactas, el puesto en su color de medalla.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Column(
              children: [
                for (final r in rest)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: medal(r.position).withValues(alpha: 0.18)),
                          child: Text("${r.position}", style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w800, color: medal(r.position))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.playerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                              ClubLine(idUser: r.idUser, club: r.clubName, crestSize: 12, style: _meta.copyWith(fontSize: 11, color: AppColors.scorifyTextFaint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final players = widget.participants;
    final enrolledCount = widget.participantsLoaded ? players.length : c.enrolledCount;
    // Inscripción online: solo con la categoría sin empezar Y abierta. El
    // organizador puede cerrarla antes de empezar (para armar la siembra):
    // antes la app seguía ofreciendo "Inscribirme" y el servidor lo rechazaba.
    // En fase de grupos se cierra sola al empezar, pero el organizador puede
    // reabrirla (hasta armar la llave): entonces también se ofrece.
    final closedByOrganizer = c.phase == "enrollment" && c.status != "active";
    final lateOpen = c.phase == "groups" && c.status == "active";
    // Campeonato cancelado: nadie se inscribe (el servidor lo rechaza).
    final inEnrollment = !widget.tournamentCancelled && _acceptsEnrollment(c);
    final full = c.quotas != null && enrolledCount >= c.quotas!;
    final (phaseLabel, phaseColor) = switch (c.phase) {
      _ when widget.tournamentCancelled => ("Cancelada", AppColors.scorifyNegative),
      "enrollment" when closedByOrganizer => ("Inscripciones cerradas", AppColors.scorifyPending),
      "enrollment" => ("Inscripciones", AppColors.scorifyMint),
      "groups" when lateOpen => ("Grupos · inscripciones abiertas", AppColors.scorifyMint),
      "groups" => ("Fase de grupos", AppColors.scorifyButterfly),
      "bracket" => ("Llave", AppColors.scorifyPending),
      "finished" => ("Finalizada", AppColors.scorifyTextMuted),
      _ => (c.phase, AppColors.scorifyTextMuted),
    };

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  c.categoryLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.scorifyText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: phaseColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(phaseLabel, style: _meta.copyWith(color: phaseColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Fact(label: "Género", value: _genderLabel(c.gender)),
              _Fact(label: "Inscripción", value: c.inscriptionPrice > 0 ? _money(c.inscriptionPrice) : "Gratis"),
              _Fact(label: "Cupos", value: c.quotas != null ? "$enrolledCount / ${c.quotas}" : "Sin límite"),
            ],
          ),
          if (_categoryDay(c.playDate, c.startTime) != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event_rounded, size: 15, color: AppColors.scorifyMint),
                const SizedBox(width: 6),
                Text(
                  "Se juega: ${_categoryDay(c.playDate, c.startTime)}",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                ),
              ],
            ),
          ],
          if (c.quotas != null && c.quotas! > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(Panel.radius),
              child: LinearProgressIndicator(
                value: (enrolledCount / c.quotas!).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.scorifySurface2,
                color: full ? AppColors.scorifyPending : AppColors.scorifyButterfly,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_podium != null && _podium!.isNotEmpty) ...[
            _podiumBlock(),
            const SizedBox(height: 12),
          ],
          // El botón va antes de la lista: al desplegar los inscritos no se
          // corre hacia abajo.
          _actions(inEnrollment, full),
          const SizedBox(height: 14),
          _playersBlock(enrolledCount),
        ],
      ),
    );
  }

  Widget _playersBlock(int count) {
    final players = widget.participants;
    if (!widget.participantsLoaded) {
      return Text("Cargando inscritos…", style: _meta);
    }
    if (players.isEmpty) {
      return Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.scorifyTextMuted),
          const SizedBox(width: 8),
          Expanded(child: Text("Aún no hay inscritos. ¡Sé el primero!", style: _meta)),
        ],
      );
    }
    final shown = players.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(Panel.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 30.0 + (shown.length - 1) * 20.0,
                  height: 30,
                  child: Stack(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        Positioned(left: i * 20.0, child: _PlayerAvatar(player: shown[i], size: 26)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "$count ${count == 1 ? "inscrito" : "inscritos"}",
                    style: _meta.copyWith(color: AppColors.scorifyText, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_expanded ? "Ocultar" : "Ver lista", style: _meta.copyWith(color: AppColors.scorifyMint, fontWeight: FontWeight.w600)),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.scorifyMint,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < players.length && i < _maxInline; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                          decoration: panelBox(),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text("${i + 1}", style: _meta),
                              ),
                              _PlayerAvatar(player: players[i], size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      players[i].playerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTypography.body,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.scorifyText,
                                      ),
                                    ),
                                    Text(
                                      (players[i].clubName ?? "").trim().isEmpty ? "Sin club" : players[i].clubName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _meta,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: "Ver perfil",
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.visibility_rounded, size: 20, color: AppColors.scorifyMint),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.playerProfile,
                                  arguments: {"userId": players[i].idUser, "playerName": players[i].playerName},
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (players.length > _maxInline)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.onSeeAll,
                            icon: Icon(Icons.people_alt_rounded, size: 18, color: AppColors.scorifyMint),
                            label: Text(
                              "Ver los ${players.length} inscritos",
                              style: _meta.copyWith(color: AppColors.scorifyMint, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _actions(bool inEnrollment, bool full) {
    final c = widget.category;
    if (c.isEnrolled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: "Estás inscrito ✓", bg: Color(0x332FD67B), fg: AppColors.scorifyButterfly),
              // Pago de la inscripción (lo marca el organizador en la mesa de control).
              c.isPaid
                  ? _Pill(label: "Inscripción pagada ✓", bg: AppColors.scorifyButterfly, fg: AppColors.scorifyOnButterfly)
                  : _Pill(
                      label: c.inscriptionPrice > 0 ? "Pago pendiente · ${_money(c.inscriptionPrice)}" : "Inscripción gratis",
                      bg: c.inscriptionPrice > 0 ? const Color(0x33EAB308) : AppColors.scorifySurface2,
                      fg: c.inscriptionPrice > 0 ? AppColors.scorifyPending : AppColors.scorifyTextMuted,
                    ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Anular: solo antes de armar los grupos (con grupos el servidor
              // lo rechaza: "habla con el organizador"), aunque la inscripción
              // esté cerrada o reabierta.
              if (c.phase == "enrollment" && !widget.tournamentCancelled)
                TextButton(
                  onPressed: widget.subscribing ? null : widget.onUnsubscribe,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  child: Text("Anular inscripción", style: _meta.copyWith(color: AppColors.scorifyNegative, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              // Con grupos o llave hay algo que mirar (también si la
              // inscripción se reabrió en fase de grupos).
              if (c.phase != "enrollment")
                TextButton(
                  onPressed: widget.onOpen,
                  child: Text("Ver resumen de la categoría", style: _meta.copyWith(color: AppColors.scorifyMint, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      );
    }
    // No cumple el género o la edad de la categoría: se dice antes de
    // intentar (antes el botón estaba activo y recién al tocarlo salía el
    // error). Si solo le falta completar el perfil, se lo lleva a completarlo.
    final reason = c.ineligibleReason;
    if (inEnrollment && reason != null) {
      final needsProfile = reason == "GENDER_REQUIRED" || reason == "BIRTH_DATE_REQUIRED";
      final text = switch (reason) {
        "GENDER_MISMATCH" => c.gender == "female" ? "Categoría solo para damas" : "Categoría solo para varones",
        "AGE_NOT_ELIGIBLE" => "No cumples el rango de edad de esta categoría",
        "GENDER_REQUIRED" => "Completa tu género en tu perfil para inscribirte",
        _ => "Completa tu fecha de nacimiento en tu perfil para inscribirte",
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(needsProfile ? Icons.info_outline_rounded : Icons.block_rounded, size: 16, color: AppColors.scorifyTextMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: _meta.copyWith(color: AppColors.scorifyTextMuted, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          needsProfile
              ? AppButton.outline(
                  label: "Completar mi perfil",
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                )
              : const AppButton(label: "No disponible para ti", onPressed: null),
        ],
      );
    }
    if (widget.tournamentCancelled) {
      return const AppButton(label: "Campeonato cancelado", onPressed: null);
    }
    if (inEnrollment) {
      return AppButton(
        label: full ? "Cupos completos" : "Inscribirme",
        onPressed: full ? null : widget.onSubscribe,
        loading: widget.subscribing,
      );
    }
    // Cerrada antes de empezar: todavía no hay grupos que mirar.
    if (c.phase == "enrollment") {
      return const AppButton(label: "Inscripciones cerradas", onPressed: null);
    }
    return AppButton.outline(
      label: "Ver grupos y resultados",
      icon: Icons.groups_rounded,
      onPressed: widget.onOpen,
    );
  }
}

TextStyle get _meta => TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.scorifyTextMuted,
);

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.scorifyMint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.scorifyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  const _Kpi({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.display, letterSpacing: -0.5,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: AppColors.scorifyInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: _meta.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.scorifyTextMuted),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _meta.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.scorifyTextFaint)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.scorifyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  // Estilo panel: etiqueta con filete del color (antes píldora teñida).
  @override
  Widget build(BuildContext context) => PanelChip.fromColors(label: label, bg: bg, fg: fg);
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CardBorder(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(Panel.radius)), child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Panel.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Panel.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Ícono en un círculo azul translúcido con filete (más "pro").
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.scorifyMint.withValues(alpha: 0.28), AppColors.scorifyMintDark.withValues(alpha: 0.12)],
                  ),
                  border: Border.all(color: AppColors.scorifyMint.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: AppColors.scorifyMint.withValues(alpha: 0.25), blurRadius: 14)],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.scorifyText,
                ),
              ),
            ],
          ),
        ),
      ),
    )));
  }
}

class _NoticeBanner extends StatelessWidget {
  final String text;
  const _NoticeBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scorifyMint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Panel.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.scorifyMint),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _meta.copyWith(color: AppColors.scorifyText, height: 1.4))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    // Mismo título de sección que el resto de la app (mayúsculas azul hielo).
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTypography.body,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: AppColors.scorifySection,
      ),
    );
  }
}

// Foto del jugador si subió una; si no, el mismo avatar generado (Identicon)
// que se usa en su perfil.
class _PlayerAvatar extends StatelessWidget {
  final TournamentParticipant player;
  final double size;
  const _PlayerAvatar({required this.player, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, shape: BoxShape.circle),
      child: UserAvatar(userId: player.idUser, url: player.avatarUrl, size: size),
    );
  }
}

/// "Seguir campeonato" para quien no juega (familia, compañeros de club,
/// fans): sin inscribirse, recibe un aviso cuando empieza cada categoría,
/// cuando sale la llave, cuando hay campeón y si cambia la fecha, el lugar o
/// se cancela. Grupos y resultados ya se podían mirar; esto suma los avisos.
class _FollowCard extends StatefulWidget {
  final String tournamentId;
  const _FollowCard({required this.tournamentId});

  @override
  State<_FollowCard> createState() => _FollowCardState();
}

class _FollowCardState extends State<_FollowCard> {
  bool? _following;
  int _followers = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    TournamentApi().getFollow(widget.tournamentId).then((r) {
      if (!mounted) return;
      setState(() {
        _following = r.following;
        _followers = r.followers;
      });
    }).catchError((_) {
      if (mounted) setState(() => _following = false);
    });
  }

  Future<void> _toggle() async {
    final next = !(_following ?? false);
    setState(() => _busy = true);
    try {
      await TournamentApi().setFollow(widget.tournamentId, next);
      if (!mounted) return;
      setState(() {
        _following = next;
        _followers = (_followers + (next ? 1 : -1)).clamp(0, 1 << 30);
      });
      if (next) {
        showToast(context, "Te avisaremos de los grupos, la llave y los campeones");
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = _following ?? false;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Icon(
            following ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
            color: AppColors.scorifyMint,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  following ? "Sigues este campeonato" : "¿No juegas? Síguelo",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
                ),
                const SizedBox(height: 2),
                Text(
                  following
                      ? "Te avisamos cuando empiece cada categoría, salga la llave y haya campeones."
                      : "Recibe avisos de los grupos, la llave y los campeones sin inscribirte."
                          "${_followers > 0 ? " · $_followers ${_followers == 1 ? "lo sigue" : "lo siguen"}" : ""}",
                  style: _meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: _following == null
                ? SizedBox(width: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.scorifyMint))))
                : TextButton(
                    onPressed: _busy ? null : _toggle,
                    style: TextButton.styleFrom(
                      backgroundColor: following ? AppColors.scorifySurface2 : AppColors.scorifyMint,
                      foregroundColor: following ? AppColors.scorifyText : AppColors.scorifyOnMint,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Panel.buttonRadius))),
                      textStyle: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: Text(following ? "Siguiendo ✓" : "Seguir"),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fase de la categoría para mostrarla (texto corto y color del punto).
(String, Color) _phaseOf(TournamentCategory c, bool cancelled) {
  final closedByOrganizer = c.phase == "enrollment" && c.status != "active";
  final lateOpen = c.phase == "groups" && c.status == "active";
  return switch (c.phase) {
    _ when cancelled => ("Cancelada", AppColors.scorifyNegative),
    "enrollment" when closedByOrganizer => ("Inscripción cerrada", AppColors.scorifyPending),
    "enrollment" => ("Inscripciones", AppColors.scorifyMint),
    "groups" when lateOpen => ("Grupos · abierta", AppColors.scorifyMint),
    "groups" => ("Grupos", AppColors.scorifyButterfly),
    "bracket" => ("Llave", AppColors.scorifyPending),
    "finished" => ("Finalizada", AppColors.scorifyTextMuted),
    _ => (c.phase, AppColors.scorifyTextMuted),
  };
}

/// Fila compacta de una categoría (cuando hay muchas): nombre y género a la
/// izquierda; fase, inscritos y flecha a la derecha. Al tocarla se abre la
/// tarjeta completa debajo.
class _CategoryRow extends StatelessWidget {
  final TournamentCategory category;
  final int enrolled;
  final bool cancelled;
  final bool expanded;
  final VoidCallback onTap;
  const _CategoryRow({
    required this.category,
    required this.enrolled,
    required this.cancelled,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = category;
    final (phase, phaseColor) = _phaseOf(c, cancelled);
    final count = c.quotas != null ? "$enrolled/${c.quotas}" : "$enrolled";
    return Material(
      color: expanded ? AppColors.scorifySelected : AppColors.scorifyCardFill,
      shape: Border.all(color: expanded ? AppColors.scorifyCardBorderStrong : AppColors.scorifyHairline),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.categoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.scorifyInk),
                          ),
                        ),
                        if (c.isEnrolled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.scorifyMint.withValues(alpha: 0.18),
                            child: Text("Juegas",
                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.scorifyCyan)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_genderLabel(c.gender), style: _meta.copyWith(color: AppColors.scorifyTextMuted)),
                        Text("  ·  ", style: _meta.copyWith(color: AppColors.scorifyTextFaint)),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: phaseColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(phase,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _meta.copyWith(color: phaseColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(count, style: TextStyle(fontFamily: AppTypography.display, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scorifyInk)),
                  Text("inscritos", style: _meta.copyWith(fontSize: 10, color: AppColors.scorifyTextFaint)),
                ],
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.expand_more_rounded, color: AppColors.scorifyTextMuted, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtro de categorías (igual que los filtros de Campeonatos): barra negra
/// con filete; la elegida en blanco con una línea azul abajo.
class _CategoryFilterBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CategoryFilterBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const opts = {"all": "Todas", "female": "Damas", "male": "Varones", "open": "Abiertas"};
    return Container(
      decoration: BoxDecoration(color: AppColors.scorifyCardFill, border: Border.all(color: AppColors.scorifyHairline)),
      child: Row(
        children: [
          for (final e in opts.entries) ...[
            if (e.key != "all") Container(width: 1, height: 20, color: AppColors.scorifyHairline),
            Expanded(
              child: InkWell(
                onTap: () => onChanged(e.key),
                child: Container(
                  height: 40,
                  color: value == e.key ? AppColors.scorifySelected : Colors.transparent,
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: AppTypography.body,
                            fontSize: 13,
                            fontWeight: value == e.key ? FontWeight.w700 : FontWeight.w600,
                            color: value == e.key ? AppColors.scorifyInk : AppColors.scorifyTextMuted,
                          ),
                        ),
                      ),
                      if (value == e.key)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.scorifyMint,
                              boxShadow: [BoxShadow(color: AppColors.scorifyMint.withValues(alpha: 0.7), blurRadius: 8)],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
