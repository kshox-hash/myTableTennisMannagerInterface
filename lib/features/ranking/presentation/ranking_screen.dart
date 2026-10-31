import 'package:myttmi/core/ui/app_button.dart';
import 'package:myttmi/core/ui/category_filter.dart';
import 'package:myttmi/core/ui/section_card.dart';
import "package:myttmi/core/ui/panel_style.dart";
import 'package:myttmi/core/ui/page_skeleton.dart';
import "package:myttmi/core/ui/user_avatar.dart";
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/core/ui/glass_card.dart';
import 'package:myttmi/core/ui/list_states.dart';
import 'package:myttmi/core/ui/top_header.dart';
import 'package:myttmi/features/ranking/api/ranking_api.dart';
import 'package:myttmi/features/ranking/models/ranking_model.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';
import 'package:myttmi/routes/app_routes.dart';

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  color: AppColors.scorifyTextMuted,
);

void _openProfile(BuildContext context, RankingEntry p) {
  Navigator.pushNamed(
    context,
    AppRoutes.playerProfile,
    arguments: {"userId": p.idUser, "playerName": p.name},
  );
}

class RankingScreen extends StatefulWidget {
  // false cuando vive embebido dentro de una sub-pestaña (p.ej. "Mi
  // rendimiento") que ya muestra su propio encabezado.
  final bool showHeader;

  const RankingScreen({super.key, this.showHeader = true});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TabAutoRefreshMixin<RankingScreen> {
  @override
  int get tabIndex => 4;

  @override
  // Al volver a la pestaña se actualiza en silencio (sin esqueleto).
  void onTabActivated() => _load(silent: true);

  final TextEditingController _search = TextEditingController();
  final _api = RankingApi();

  List<RankingEntry> _entries = [];
  // Ranking elegido: null = general; si no, el id del organizador.
  String? _organizerId;
  // Oro y Plata son rankings separados.
  String _copa = "oro";
  // Rankings que puedo elegir aparte del general (uno por organizador).
  List<RankingScope> _scopes = [];
  // Campeonatos que forman el ranking elegido.
  List<RankingTournament> _tournaments = [];
  String? _myUserId;
  bool _loading = true;
  // Primera carga: esqueleto de la página entera (después, recargas en silencio).
  bool _loadedOnce = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });
    try {
      final org = _organizerId;
      final copa = _copa;
      final results = await Future.wait([
        _api.getGlobal(organizerId: org, copa: copa),
        SessionStorage().getUserId(),
        // Si estas dos fallan el ranking igual se muestra.
        _api.getScopes().catchError((_) => <RankingScope>[]),
        _api.getTournaments(organizerId: org, copa: copa).catchError((_) => <RankingTournament>[]),
      ]);
      if (!mounted || org != _organizerId || copa != _copa) return;
      setState(() {
        _entries = results[0] as List<RankingEntry>;
        _myUserId = results[1] as String?;
        _scopes = results[2] as List<RankingScope>;
        _tournaments = results[3] as List<RankingTournament>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadedOnce = true;
        });
      }
    }
  }

  String get _scopeName {
    if (_organizerId == null) return "General";
    return _scopes.where((x) => x.organizerId == _organizerId).firstOrNull?.name ?? "Organizador";
  }

  /// "Basado en 2 campeonatos: Copa X, Torneo Y".
  String get _basisText {
    final n = _tournaments.length;
    final names = _tournaments.take(2).map((t) => t.name).join(", ");
    final more = n > 2 ? " y ${n - 2} más" : "";
    return "Basado en $n ${n == 1 ? "campeonato terminado" : "campeonatos terminados"}: $names$more.";
  }

  Future<void> _pickScope() async {
    final picked = await showOptionsSheet<String?>(
      context,
      title: "Elegir ranking",
      options: [
        (value: null, label: "General (toda la plataforma)"),
        for (final x in _scopes) (value: x.organizerId, label: "${x.name} · ${x.tournaments} ${x.tournaments == 1 ? "campeonato" : "campeonatos"}"),
      ],
      selected: _organizerId,
    );
    if (picked == null || picked.value == _organizerId) return;
    setState(() => _organizerId = picked.value);
    _load();
  }

  Widget _copaTab(String copa, String label) {
    final selected = _copa == copa;
    return Expanded(
      child: DecoratedBox(
        decoration: selectedPillDecoration(selected),
        child: InkWell(
          onTap: selected
              ? null
              : () {
                  setState(() => _copa = copa);
                  _load();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
            ),
          ),
        ),
      ),
    );
  }

  /// De dónde salen los puntos de un jugador en el ranking elegido.
  void _showBreakdown(RankingEntry p) {
    final future = _api.getBreakdown(p.idUser, organizerId: _organizerId, copa: _copa);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelTitleBar(
                title: p.name,
                icon: Icons.leaderboard_rounded,
                trailing: PanelChip(label: "${p.rankingPoints} pts", color: AppColors.scorifyMint, fontSize: 11.5),
              ),
              Flexible(
                child: FutureBuilder<List<RankingResult>>(
                  future: future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.scorifyMint)));
                    }
                    final rows = snap.data ?? const <RankingResult>[];
                    if (rows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No se registran campeonatos con puntos.", style: _muted),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      children: dividedRows([
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.tournamentName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                                      const SizedBox(height: 2),
                                      Text(
                                        [r.round, if (r.category.isNotEmpty) r.category, _levelName(r.level)].join(" · "),
                                        style: _muted,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PanelChip(label: "+${r.points} pts", color: AppColors.scorifyButterfly, fontSize: 12),
                              ],
                            ),
                          ),
                      ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: AppButton.outline(
                  label: "Ver perfil",
                  icon: Icons.person_rounded,
                  onPressed: () {
                    Navigator.pop(sheet);
                    _openProfile(context, p);
                  },
                  height: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _levelName(String level) => switch (level) {
        "regional" => "Regional",
        "nacional" => "Nacional",
        _ => "Local",
      };

  /// Cómo se arma el ranking (mismo cálculo que el servidor, ver
  /// ranking/ittf_points.ts del backend).
  void _showHowItWorks(BuildContext context) {
    const rows = [
      ("Campeón", "125", "400", "1000"),
      ("Final", "90", "280", "700"),
      ("Semifinal", "45", "140", "350"),
      ("Cuartos", "25", "70", "175"),
      ("Octavos", "15", "35", "90"),
      ("16avos", "8", "4", "15"),
    ];
    Widget cell(String t, {bool head = false, bool first = false}) => Expanded(
          flex: first ? 4 : 3,
          child: Text(
            t,
            textAlign: first ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 12.5,
              fontWeight: head || first ? FontWeight.w700 : FontWeight.w500,
              color: head ? AppColors.scorifyTextMuted : AppColors.scorifyText,
            ),
          ),
        );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PanelTitleBar(title: "¿Cómo se calcula el ranking?", icon: Icons.leaderboard_rounded),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Es el ranking general de MyTTM. Oro y Plata son tablas separadas: los puntos de una no suman en la otra, y el sembrado usa solo Oro. "
                      "Suman solo los campeonatos que su organizador marcó como puntuables, terminados en los últimos 12 meses.\n\n"
                      "Los puntos se ganan por la ronda a la que llegas en la llave (la fase de grupos no da puntos; en grupo único cuenta tu puesto final). "
                      "Si juegas varias categorías de un mismo campeonato, cuenta solo tu mejor resultado.",
                      style: AppTypography.bodyMuted.copyWith(fontSize: 13, height: 1.45),
                    ),
                    if (_tournaments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_basisText, style: AppTypography.bodyMuted.copyWith(fontSize: 13, height: 1.45, color: AppColors.scorifyText)),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: panelBox(),
                      child: Column(
                        children: [
                          Row(children: [cell("Ronda", head: true, first: true), cell("Local", head: true), cell("Regional", head: true), cell("Nacional", head: true)]),
                          const SizedBox(height: 8),
                          for (final r in rows) ...[
                            const Divider(height: 12, color: Panel.fieldBorder),
                            Row(children: [cell(r.$1, first: true), cell(r.$2), cell(r.$3), cell(r.$4)]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "El nivel (local, regional o nacional) lo elige el organizador al crear el campeonato. Los campeonatos finalizados antes de tiempo no dan puntos.",
                      style: AppTypography.bodyMuted.copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedOnce) return const PageSkeleton();
    final query = _search.text.toLowerCase();
    final filtered = _entries
        .where((p) => p.name.toLowerCase().contains(query) || (p.clubName ?? "").toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.rankingPosition.compareTo(b.rankingPosition));

    // El podio solo con la tabla completa (sin buscar).
    final podium = query.isEmpty ? filtered.where((p) => p.rankingPosition <= 3).toList() : <RankingEntry>[];
    final rest = query.isEmpty ? filtered.where((p) => p.rankingPosition > 3).toList() : filtered;
    final me = _entries.where((p) => p.idUser == _myUserId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ScrollingHeaderPage(
        header: [
          const SizedBox(height: 16),
          if (widget.showHeader) ...[
            TopHeader(title: "Ranking", subtitle: "${_organizerId == null ? "Ranking MyTTM" : "Ranking de $_scopeName"} · últimos 12 meses", showBack: false),
            const SizedBox(height: 10),
          ],
          Row(children: [_copaTab("oro", "🥇 Oro"), const SizedBox(width: 8), _copaTab("plata", "🥈 Plata")]),
          const SizedBox(height: 8),
          // Cabecera compacta: qué ranking (si hay más de uno) y el buscador
          // con "?" al lado. La explicación larga y en qué campeonatos se
          // basa van en el panel del "?" (antes, dos bloques de texto acá
          // rompían el diseño).
          if (_scopes.isNotEmpty) ...[
            FilterDropdown(
              icon: Icons.leaderboard_rounded,
              label: _scopeName,
              onTap: _pickScope,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.bodyText,
                  decoration: InputDecoration(
                    hintText: "Buscar jugador o club",
                    hintStyle: AppTypography.bodyMuted,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.scorifyInput,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.scorifyTextMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(Panel.radius), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Panel.radius),
                      borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: "¿Cómo se calcula?",
                child: InkWell(
                  onTap: () => _showHowItWorks(context),
                  borderRadius: BorderRadius.circular(Panel.radius),
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: panelBox(),
                    child: const Icon(Icons.help_outline_rounded, size: 21, color: AppColors.scorifyMint),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        body: _loading
                ? const LoadingState()
                : _error != null
                    ? ErrorStateView(message: "No pudimos cargar el ranking.\n$_error", onRetry: _load)
                    : RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (me != null) ...[
                              _MyRankCard(me: me, total: _entries.length),
                              const SizedBox(height: 16),
                            ],
                            if (filtered.isEmpty)
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.leaderboard_rounded, color: AppColors.scorifyTextMuted, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        query.isEmpty ? "Todavía no hay puntos en este ranking. Aparecen cuando termina un campeonato puntuable; mientras, tus números están en Mi rendimiento." : "Nadie coincide con esa búsqueda.",
                                        style: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              if (podium.isNotEmpty) ...[
                                SectionCard(
                                  title: "Podio",
                                  icon: Icons.emoji_events_rounded,
                                  titleColor: const Color(0xFFE7B53C),
                                  padding: const EdgeInsets.all(10),
                                  child: _PodiumRow(top3: podium, myUserId: _myUserId, onTap: _showBreakdown),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (rest.isNotEmpty)
                                SectionCard(
                                  title: "Clasificación",
                                  icon: Icons.leaderboard_rounded,
                                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                                  child: Column(
                                    children: dividedRows([for (final p in rest) _RankRow(player: p, isMe: p.idUser == _myUserId, onTap: () => _showBreakdown(p))]),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
      ),
    );
  }
}

/// Tu lugar en el ranking, arriba de todo.
class _MyRankCard extends StatelessWidget {
  final RankingEntry me;
  final int total;
  const _MyRankCard({required this.me, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(userId: me.idUser, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu posición", style: _muted),
                const SizedBox(height: 2),
                Text(
                  "#${me.rankingPosition} de $total",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                ),
              ],
            ),
          ),
          PanelChip(label: "${me.rankingPoints} pts", color: AppColors.scorifyButterfly, fontSize: 13),
        ],
      ),
    );
  }
}

// Monedas de MyTTM (las mismas de la web): oro, plata, bronce y, del 4°
// hacia abajo, la de participación.
String _medalFor(int place) => switch (place) {
      1 => "assets/images/medal_gold.webp",
      2 => "assets/images/medal_silver.webp",
      3 => "assets/images/medal_bronze.webp",
      _ => "assets/images/medal_participation.webp",
    };

const _medalTone = {1: Color(0xFFE7B53C), 2: Color(0xFFB9C4CA), 3: Color(0xFFD8925A)};

Widget _medal(int place, double size) => Image.asset(
      _medalFor(place),
      width: size,
      height: size,
      // Decodificada al tamaño en pantalla (no el archivo completo).
      cacheWidth: (size * 3).round(),
      filterQuality: FilterQuality.medium,
    );

// Podio (estilo panel): tres tarjetas con su moneda; el 1° al centro y más
// alto. Antes eran bloques planos altos y el nombre se cortaba.
class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> top3;
  final String? myUserId;
  final ValueChanged<RankingEntry> onTap;
  const _PodiumRow({required this.top3, this.myUserId, required this.onTap});

  RankingEntry? _at(int position) => top3.where((p) => p.rankingPosition == position).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumStep(entry: _at(2), place: 2, isMe: _at(2)?.idUser == myUserId, onTap: onTap)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: _at(1), place: 1, isMe: _at(1)?.idUser == myUserId, onTap: onTap)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: _at(3), place: 3, isMe: _at(3)?.idUser == myUserId, onTap: onTap)),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final RankingEntry? entry;
  final int place;
  final bool isMe;
  final ValueChanged<RankingEntry> onTap;

  const _PodiumStep({required this.entry, required this.place, this.isMe = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.shrink();
    final first = place == 1;
    final tone = _medalTone[place]!;
    // Dentro del panel "Podio": caja oscura con filete del color de su
    // medalla (no una tarjeta dentro de otra).
    return Material(
      color: Colors.transparent,
      child: Ink(
          decoration: panelBox(color: tone),
          child: InkWell(
            onTap: () => onTap(e),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, first ? 18 : 12, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _medal(place, first ? 64 : 50),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: Text(
                      isMe ? "${e.name} (tú)" : e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PanelChip(label: "${e.rankingPoints} pts", color: tone, fontSize: 11.5),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankingEntry player;
  final bool isMe;
  final VoidCallback onTap;

  const _RankRow({required this.player, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isMe ? AppColors.scorifyMint.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(Panel.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Panel.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  "${player.rankingPosition}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.scorifyTextMuted),
                ),
              ),
              const SizedBox(width: 6),
              _medal(player.rankingPosition, 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? "${player.name} (tú)" : player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
                    ),
                    Text(player.clubName ?? "Sin club", maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PanelChip(label: "${player.rankingPoints} pts", color: AppColors.scorifyMint, fontSize: 12),
            ],
          ),
        ),
      ),
    );
  }
}
