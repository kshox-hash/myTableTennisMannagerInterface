import "package:flutter/material.dart";
import "package:share_plus/share_plus.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/confirm_dialog.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/prism_background.dart";
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

String _genderLabel(String g) => switch (g) {
      "male" => "Masculino",
      "female" => "Femenino",
      "mixed" => "Mixto",
      _ => g,
    };

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

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _refresh();
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

    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                TopHeader(
                  title: "Campeonato",
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
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _HeroCard(tournament: t, started: _started),
                        const SizedBox(height: 14),
                        if (_started) ...[
                          Row(
                            children: [
                              Expanded(child: _QuickLink(icon: Icons.sports_tennis_rounded, label: "Partidos", onTap: () => _go(AppRoutes.tournamentMatches))),
                              const SizedBox(width: 10),
                              Expanded(child: _QuickLink(icon: Icons.table_bar_rounded, label: "Mesas", onTap: () => _go(AppRoutes.tournamentTables))),
                              const SizedBox(width: 10),
                              Expanded(child: _QuickLink(icon: Icons.people_alt_rounded, label: "Jugadores", onTap: () => _go(AppRoutes.tournamentPlayers))),
                            ],
                          ),
                        ] else
                          const _NoticeBanner(
                            text: "Inscripciones abiertas. Los grupos, partidos y mesas aparecen cuando el organizador cierre las inscripciones.",
                          ),
                        const SizedBox(height: 22),
                        const _SectionLabel("Categorías"),
                        const SizedBox(height: 12),
                        if (cats.isEmpty)
                          Text("Este campeonato no tiene categorías aún.", style: AppTypography.bodyMuted)
                        else
                          for (final c in cats) ...[
                            _CategoryCard(
                              category: c,
                              participants: _participants.where((p) => p.idCategory == c.idCategory).toList(),
                              participantsLoaded: _participantsLoaded,
                              subscribing: _subscribingId == c.idCategory,
                              onSubscribe: () => _subscribe(c),
                              onUnsubscribe: () => _unsubscribe(c),
                              onOpen: () => _goMyCategory(c),
                            ),
                            const SizedBox(height: 12),
                          ],
                      ],
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

class _HeroCard extends StatelessWidget {
  final Tournament tournament;
  final bool started;
  const _HeroCard({required this.tournament, required this.started});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final when = _formatWhen(t.eventDate, t.eventTime);
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
                : ("Inscripciones abiertas", AppColors.scorifyMint, AppColors.scorifyOnMint);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(label: chipLabel, bg: chipBg, fg: chipFg),
          const SizedBox(height: 12),
          Text(
            t.tournamentName,
            style: const TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.scorifyText,
            ),
          ),
          const SizedBox(height: 14),
          if (when != null) _InfoRow(icon: Icons.calendar_today_rounded, text: when),
          if ((t.address ?? "").trim().isNotEmpty) _InfoRow(icon: Icons.place_rounded, text: t.address!),
          if ((t.region ?? "").trim().isNotEmpty) _InfoRow(icon: Icons.map_rounded, text: t.region!),
          if ((t.description ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(t.description!, style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.scorifySurface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _Kpi(value: "${t.categories.length}", label: t.categories.length == 1 ? "Categoría" : "Categorías"),
                _Kpi(value: "$enrolled", label: enrolled == 1 ? "Inscrito" : "Inscritos"),
                _Kpi(value: quota != null ? "$quota" : "∞", label: "Cupos"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final TournamentCategory category;
  final List<TournamentParticipant> participants;
  final bool participantsLoaded;
  final bool subscribing;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;
  final VoidCallback onOpen;

  const _CategoryCard({
    required this.category,
    required this.participants,
    required this.participantsLoaded,
    required this.subscribing,
    required this.onSubscribe,
    required this.onUnsubscribe,
    required this.onOpen,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final players = widget.participants;
    final enrolledCount = widget.participantsLoaded ? players.length : c.enrolledCount;
    final inEnrollment = c.phase == "enrollment";
    final full = c.quotas != null && enrolledCount >= c.quotas!;
    final (phaseLabel, phaseColor) = switch (c.phase) {
      "enrollment" => ("Inscripciones", AppColors.scorifyMint),
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
                  style: const TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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
          if (c.quotas != null && c.quotas! > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (enrolledCount / c.quotas!).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.scorifySurface2,
                color: full ? AppColors.scorifyPending : AppColors.scorifyButterfly,
              ),
            ),
          ],
          const SizedBox(height: 14),
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
          const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.scorifyTextMuted),
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
          borderRadius: BorderRadius.circular(10),
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
                      for (var i = 0; i < players.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                          decoration: BoxDecoration(
                            color: AppColors.scorifySurface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                      style: const TextStyle(
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
                                icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.scorifyMint),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.playerProfile,
                                  arguments: {"userId": players[i].idUser, "playerName": players[i].playerName},
                                ),
                              ),
                            ],
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
              const _Pill(label: "Estás inscrito ✓", bg: Color(0x33A6D32D), fg: AppColors.scorifyButterfly),
              // Pago de la inscripción (lo marca el organizador en la mesa de control).
              c.isPaid
                  ? const _Pill(label: "Inscripción pagada ✓", bg: AppColors.scorifyButterfly, fg: AppColors.scorifyOnButterfly)
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
              if (inEnrollment)
                TextButton(
                  onPressed: widget.subscribing ? null : widget.onUnsubscribe,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  child: Text("Anular inscripción", style: _meta.copyWith(color: AppColors.scorifyNegative, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              if (!inEnrollment)
                TextButton(
                  onPressed: widget.onOpen,
                  child: Text("Ver mi categoría", style: _meta.copyWith(color: AppColors.scorifyMint, fontWeight: FontWeight.w600)),
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
          SizedBox(
            height: 46,
            child: needsProfile
                ? OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                    child: const Text("Completar mi perfil"),
                  )
                : FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.scorifySurface2,
                      disabledForegroundColor: AppColors.scorifyTextMuted,
                    ),
                    child: const Text("No disponible para ti"),
                  ),
          ),
        ],
      );
    }
    if (inEnrollment) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          onPressed: full || widget.subscribing ? null : widget.onSubscribe,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.scorifySurface2,
            disabledForegroundColor: AppColors.scorifyTextMuted,
          ),
          child: widget.subscribing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.scorifyOnButterfly),
                )
              : Text(full ? "Cupos completos" : "Inscribirme"),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: widget.onOpen,
        icon: const Icon(Icons.groups_rounded, size: 18),
        label: const Text("Ver grupos y resultados"),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.scorifyText,
          side: const BorderSide(color: AppColors.scorifyTextMuted),
          shape: const StadiumBorder(),
          textStyle: AppTypography.button,
        ),
      ),
    );
  }
}

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w500,
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
              style: const TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
            style: const TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.scorifyText,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: _meta),
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
          Text(label, style: _meta.copyWith(fontSize: 11.5)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scorifyCardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.scorifyMint, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.scorifyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.scorifyMint),
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
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTypography.body,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.scorifyText,
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
    final fallback = Identicon(seed: player.idUser, size: size);
    final url = (player.avatarUrl ?? "").trim();
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: AppColors.scorifyCardFill, shape: BoxShape.circle),
      child: ClipOval(
        child: url.isEmpty
            ? fallback
            : Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }
}
