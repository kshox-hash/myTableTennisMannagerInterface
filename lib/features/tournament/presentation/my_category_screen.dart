import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/match_status_labels.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/section_header.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/routes/app_routes.dart";

const _playedStatuses = {"played", "walkover"};

class _CategoryData {
  final PlayerCategoryView view;
  final CategoryStandings generalStandings;
  final String? myUserId;
  _CategoryData({
    required this.view,
    required this.generalStandings,
    this.myUserId,
  });
}

class MyCategoryScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String categoryId;
  final String categoryLabel;

  const MyCategoryScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryId,
    required this.categoryLabel,
  });

  @override
  State<MyCategoryScreen> createState() => _MyCategoryScreenState();
}

class _MyCategoryScreenState extends State<MyCategoryScreen> {
  final _api = PlayerApi();
  late Future<_CategoryData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetchAll();
    });
  }

  Future<_CategoryData> _fetchAll() async {
    final results = await Future.wait([
      _api.getCategoryView(widget.tournamentId, widget.categoryId),
      _api.getCategoryStandings(widget.tournamentId, widget.categoryId),
      SessionStorage().getUserId(),
    ]);
    return _CategoryData(
      view: results[0] as PlayerCategoryView,
      generalStandings: results[1] as CategoryStandings,
      myUserId: results[2] as String?,
    );
  }

  void _goMatchTyped(PlayerMatch m, String type) {
    Navigator.pushNamed(
      context,
      AppRoutes.matchDetail,
      arguments: {"matchType": type, "matchId": m.idMatch},
    );
  }

  // El detalle de grupos y la llave completa del torneo ya se ven en
  // "Partidos" (con todas las categorías) — desde acá solo saltamos directo
  // a la pestaña correcta en vez de repetir esos datos en esta pantalla.
  void _goViewMore(String phase) {
    final toBracket = phase == "bracket" || phase == "finished";
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentMatches,
      arguments: {
        "tournamentId": widget.tournamentId,
        "tournamentName": widget.tournamentName,
        "initialMode": toBracket ? "bracket" : "groups",
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TopHeader(title: widget.categoryLabel),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<_CategoryData>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                          return const LoadingState();
                        }
                        if (snap.hasError) {
                          return ListView(
                            children: [
                              ErrorStateView(
                                message:
                                    "No pudimos cargar la categoría.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final data = snap.data!;
                        final view = data.view;
                        final isEnrolled =
                            view.myGroupName != null ||
                            view.myGroupMatches.isNotEmpty ||
                            view.myBracketMatches.isNotEmpty;
                        final generalStandings =
                            data.generalStandings.standings;

                        // Grupo + llave combinados, cada uno con su tipo (para el
                        // link al detalle) — separados por jugado/pendiente en vez
                        // de una sola lista mezclada.
                        final allMatches = [
                          for (final m in view.myGroupMatches)
                            (match: m, type: "group"),
                          for (final m in view.myBracketMatches)
                            (match: m, type: "bracket"),
                        ];
                        final results = allMatches
                            .where(
                              (t) => _playedStatuses.contains(t.match.status),
                            )
                            .toList();
                        final upcoming = allMatches
                            .where(
                              (t) => !_playedStatuses.contains(t.match.status),
                            )
                            .toList();

                        final isEmpty =
                            generalStandings.isEmpty && allMatches.isEmpty;

                        final me = view.standings
                            .where((x) => x.idUser == data.myUserId)
                            .firstOrNull;

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            _CategoryHero(
                              tournamentName: widget.tournamentName,
                              categoryLabel: widget.categoryLabel,
                              view: view,
                              isEnrolled: isEnrolled,
                              me: me,
                            ),

                            if (view.phase == "groups" &&
                                view.standings.isNotEmpty) ...[
                              _Section(
                                view.myGroupName != null
                                    ? "Tu ${_groupLabel(view.myGroupName!).toLowerCase()}"
                                    : "Tu grupo",
                                trailing: TextButton(
                                  onPressed: () => _goViewMore(view.phase),
                                  child: const Text(
                                    "Ver todos los grupos",
                                    style: TextStyle(
                                      fontFamily: AppTypography.body,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.scorifyMint,
                                    ),
                                  ),
                                ),
                              ),
                              _GroupTable(
                                standings: view.standings,
                                myUserId: data.myUserId,
                              ),
                            ],

                            if (generalStandings.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              SectionHeader(
                                title: data.generalStandings.source == "bracket"
                                    ? "Posiciones finales"
                                    : "Tabla general",
                              ),
                              const SizedBox(height: 10),
                              _GeneralStandingsList(
                                standings: generalStandings,
                                myUserId: data.myUserId,
                              ),
                            ],

                            if (view.phase == "bracket" ||
                                view.phase == "finished") ...[
                              const SizedBox(height: 22),
                              GlassCard(
                                onTap: () => _goViewMore(view.phase),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_tree_outlined,
                                      color: AppColors.scorifyMint,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        view.phase == "groups"
                                            ? "Ver todos los grupos"
                                            : "Ver llave completa",
                                        style: AppTypography.h2,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.scorifyTextFaint,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Mi recorrido: ronda a ronda por la llave, con el
                            // resultado de cada una (antes había que buscarlo en
                            // el cuadro completo).
                            if (view.myBracketMatches.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              const SectionHeader(
                                title: "Mi recorrido en la llave",
                              ),
                              const SizedBox(height: 10),
                              _JourneyCard(
                                matches: view.myBracketMatches,
                                totalRounds: view.bracketTotalRounds,
                                myUserId: data.myUserId,
                              ),
                            ],

                            if (results.isNotEmpty) ...[
                              _Section("Resultados (${results.length})"),
                              ...results.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _MatchCard(
                                    match: t.match,
                                    type: t.type,
                                    myUserId: data.myUserId,
                                    onTap: () => _goMatchTyped(t.match, t.type),
                                  ),
                                ),
                              ),
                            ],

                            if (upcoming.isNotEmpty) ...[
                              const _Section("Próximos partidos"),
                              ...upcoming.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _MatchCard(
                                    match: t.match,
                                    type: t.type,
                                    myUserId: data.myUserId,
                                    onTap: () => _goMatchTyped(t.match, t.type),
                                  ),
                                ),
                              ),
                            ],

                            if (isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: EmptyState(
                                  icon: Icons.groups_outlined,
                                  message:
                                      "Todavía no hay grupos ni llave para esta categoría.",
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneralStandingsList extends StatelessWidget {
  final List<CategoryStandingRow> standings;
  final String? myUserId;
  const _GeneralStandingsList({required this.standings, this.myUserId});

  @override
  Widget build(BuildContext context) {
    final sorted = standings.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: sorted.map((s) {
          final isMe = s.idUser == myUserId;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.scorifyMint.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.position == 1
                        ? AppColors.scorifyMint
                        : Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${s.position}",
                    style: AppTypography.mono14.copyWith(
                      fontWeight: FontWeight.w700,
                      color: s.position == 1
                          ? AppColors.scorifyOnMint
                          : AppColors.scorifyText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.playerName,
                        style: isMe ? AppTypography.h2 : AppTypography.bodyText,
                      ),
                      if (s.clubName != null)
                        Text(s.clubName!, style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
                if (s.position == 1)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.scorifyMint,
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final List<PlayerMatch> matches;
  final int? totalRounds;
  final String? myUserId;
  const _JourneyCard({
    required this.matches,
    required this.totalRounds,
    required this.myUserId,
  });

  String _roundLabel(int? round) {
    if (round == null) return "Llave";
    if (round == 0) return "Pre-llave";
    final total = totalRounds;
    if (total == null) return "Ronda $round";
    switch (total - round) {
      case 0:
        return "Final";
      case 1:
        return "Semifinal";
      case 2:
        return "Cuartos";
      case 3:
        return "Octavos";
      default:
        return "Ronda $round";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...matches]
      ..sort((a, b) => (a.round ?? 0).compareTo(b.round ?? 0));
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++)
            _step(context, sorted[i], i == sorted.length - 1),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, PlayerMatch m, bool last) {
    final done = m.status == "played" || m.status == "walkover";
    final won = done && m.winnerId != null && m.winnerId == myUserId;
    final lost = done && !won;
    final color = won
        ? AppColors.scorifyButterfly
        : lost
        ? AppColors.scorifyNegative
        : AppColors.scorifyMint;
    final mine = m.mySlot == "player1" ? m.setsPlayer1 : m.setsPlayer2;
    final theirs = m.mySlot == "player1" ? m.setsPlayer2 : m.setsPlayer1;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.matchDetail,
        arguments: {"matchType": "bracket", "matchId": m.idMatch},
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Línea de tiempo: punto de color + conector hacia la siguiente ronda.
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.scorifyTextMuted.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _roundLabel(m.round).toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "vs ${m.opponentName ?? "Por definir"}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.scorifyText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      done
                          ? "$mine-$theirs"
                          : (m.tableNumber != null
                                ? "Mesa ${m.tableNumber}"
                                : "Por jugar"),
                      style: TextStyle(
                        color: done ? color : AppColors.scorifyTextMuted,
                        fontSize: done ? 16 : 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diseño de "Mi categoría" (mismo estilo que el detalle del campeonato) ──

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w500,
  color: AppColors.scorifyTextMuted,
);

// "GR-3" → "Grupo 3"; cualquier otro nombre se muestra tal cual con "Grupo".
String _groupLabel(String name) {
  final m = RegExp(
    r"^GR-?(\w+)$",
    caseSensitive: false,
  ).firstMatch(name.trim());
  return "Grupo ${m != null ? m.group(1) : name}";
}

void _openProfile(BuildContext context, String? userId, String? name) {
  if (userId == null || userId.isEmpty) return;
  Navigator.pushNamed(
    context,
    AppRoutes.playerProfile,
    arguments: {"userId": userId, "playerName": name},
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill(this.label, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
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

class _Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _Section(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.scorifyText,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class _CategoryHero extends StatelessWidget {
  final String tournamentName;
  final String categoryLabel;
  final PlayerCategoryView view;
  final bool isEnrolled;
  final PlayerStanding? me;

  const _CategoryHero({
    required this.tournamentName,
    required this.categoryLabel,
    required this.view,
    required this.isEnrolled,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    final (phaseBg, phaseFg) = switch (view.phase) {
      "groups" => (AppColors.scorifyButterfly, AppColors.scorifyOnButterfly),
      "bracket" => (AppColors.scorifyPending, AppColors.scorifyOnButterfly),
      "finished" => (AppColors.scorifySurface2, AppColors.scorifyTextMuted),
      _ => (AppColors.scorifyMint, AppColors.scorifyOnMint),
    };
    final phaseText = switch (view.phase) {
      "groups" => "Fase de grupos",
      "bracket" => "Llave",
      "finished" => "Finalizada",
      _ => "Inscripciones",
    };
    final s = me;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(phaseText, bg: phaseBg, fg: phaseFg),
              if (view.myGroupName != null)
                _Pill(
                  _groupLabel(view.myGroupName!),
                  bg: AppColors.scorifySurface2,
                  fg: AppColors.scorifyText,
                ),
              if (!isEnrolled)
                const _Pill(
                  "Viendo como espectador",
                  bg: AppColors.scorifySurface2,
                  fg: AppColors.scorifyTextMuted,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            categoryLabel,
            style: const TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.scorifyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(tournamentName, style: _muted.copyWith(fontSize: 13.5)),
          if (s != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.scorifySurface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _Kpi(
                    value: s.position != null ? "${s.position}°" : "–",
                    label: "Posición",
                  ),
                  _Kpi(value: "${s.played}", label: "Jugados"),
                  _Kpi(
                    value: "${s.won}",
                    label: "Ganados",
                    color: AppColors.scorifyButterfly,
                  ),
                  _Kpi(value: "${s.lost}", label: "Perdidos"),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Kpi({
    required this.value,
    required this.label,
    this.color = AppColors.scorifyText,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: _muted.copyWith(fontSize: 11.5)),
      ],
    ),
  );
}

/// Tabla del grupo del jugador: tocar a alguien abre su perfil.
class _GroupTable extends StatelessWidget {
  final List<PlayerStanding> standings;
  final String? myUserId;
  const _GroupTable({required this.standings, this.myUserId});

  @override
  Widget build(BuildContext context) {
    // Mientras nadie ha jugado, el grupo se muestra en el mismo orden en que
    // se armó (como lo manda el servidor); con partidos jugados, por posición.
    final anyPlayed = standings.any((x) => x.played > 0);
    final rows = standings.toList();
    if (anyPlayed) {
      rows.sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));
    }
    const head = TextStyle(
      fontFamily: AppTypography.body,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.scorifyTextMuted,
    );
    Widget num(String v, {bool strong = false}) => SizedBox(
      width: 30,
      child: Text(
        v,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 13,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          color: strong ? AppColors.scorifyText : AppColors.scorifyTextMuted,
        ),
      ),
    );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text("#", style: head)),
                SizedBox(width: 36),
                Expanded(child: Text("Jugador", style: head)),
                SizedBox(
                  width: 30,
                  child: Text("PJ", textAlign: TextAlign.center, style: head),
                ),
                SizedBox(
                  width: 30,
                  child: Text("G", textAlign: TextAlign.center, style: head),
                ),
                SizedBox(
                  width: 30,
                  child: Text("P", textAlign: TextAlign.center, style: head),
                ),
                SizedBox(
                  width: 38,
                  child: Text("Sets", textAlign: TextAlign.center, style: head),
                ),
              ],
            ),
          ),
          for (final s in rows)
            Material(
              color: s.idUser == myUserId
                  ? AppColors.scorifyMint.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: s.idUser == myUserId
                    ? null
                    : () => _openProfile(context, s.idUser, s.playerName),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          "${s.position ?? "–"}",
                          style: TextStyle(
                            fontFamily: AppTypography.body,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: s.qualifiedToBracket
                                ? AppColors.scorifyButterfly
                                : AppColors.scorifyText,
                          ),
                        ),
                      ),
                      ClipOval(child: Identicon(seed: s.idUser, size: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.idUser == myUserId ? "Tú" : s.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.scorifyText,
                          ),
                        ),
                      ),
                      num("${s.played}"),
                      num("${s.won}", strong: true),
                      num("${s.lost}"),
                      SizedBox(
                        width: 38,
                        child: Text(
                          "${s.setsFor}-${s.setsAgainst}",
                          textAlign: TextAlign.center,
                          style: _muted.copyWith(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de partido "Tú vs rival": tocar la tarjeta abre el partido y
/// tocar al rival abre su perfil.
class _MatchCard extends StatelessWidget {
  final PlayerMatch match;
  final String type;
  final String? myUserId;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.type,
    required this.myUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = match;
    final played = _playedStatuses.contains(m.status);
    final mySets = m.mySlot == "player1" ? m.setsPlayer1 : m.setsPlayer2;
    final theirSets = m.mySlot == "player1" ? m.setsPlayer2 : m.setsPlayer1;
    final iWon = played && m.winnerId != null && m.winnerId == myUserId;
    final (pillText, pillBg, pillFg) = played
        ? (iWon
              ? (
                  "Ganaste",
                  AppColors.scorifyButterfly,
                  AppColors.scorifyOnButterfly,
                )
              : ("Perdiste", AppColors.scorifyNegative, Colors.white))
        : m.tableNumber != null
        ? (
            "En mesa ${m.tableNumber}",
            AppColors.scorifyMint,
            AppColors.scorifyOnMint,
          )
        : (
            matchStatusLabel[m.status] ?? m.status,
            AppColors.scorifySurface2,
            AppColors.scorifyTextMuted,
          );
    final meta = [
      type == "bracket" ? "Llave" : "Fase de grupos",
      if (type == "bracket" && m.round != null) matchRoundLabel(m.round!),
      "Partido ${m.matchNumber}",
    ].join(" · ");

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(meta, style: _muted)),
              _Pill(pillText, bg: pillBg, fg: pillFg),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Side(userId: myUserId, name: "Tú"),
              ),
              SizedBox(
                width: 84,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    played ? "$mySets - $theirSets" : "VS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: played ? 24 : 18,
                      fontWeight: FontWeight.w800,
                      color: played
                          ? AppColors.scorifyText
                          : AppColors.scorifyTextMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _Side(
                  userId: m.opponentId,
                  name: m.opponentName ?? "Por definir",
                  subtitle: m.opponentId != null ? "Ver perfil" : null,
                  onTap: m.opponentId != null
                      ? () =>
                            _openProfile(context, m.opponentId, m.opponentName)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String? userId;
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;
  const _Side({
    required this.userId,
    required this.name,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final id = userId;
    final content = Column(
      children: [
        ClipOval(
          child: id != null
              ? Identicon(seed: id, size: 44)
              : Container(
                  width: 44,
                  height: 44,
                  color: AppColors.scorifySurface2,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.scorifyTextMuted,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.scorifyText,
            height: 1.25,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.scorifyMint,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle!,
                style: _muted.copyWith(
                  color: AppColors.scorifyMint,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(2), child: content),
    );
  }
}
