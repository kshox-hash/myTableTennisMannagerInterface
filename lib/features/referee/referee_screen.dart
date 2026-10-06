import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/ui/confirm_dialog.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";
import "package:myttmi/features/referee/referee_api.dart";

/// Pantalla de árbitro: al terminar cada set se escribe su marcador en una
/// grilla igual a la del panel del organizador (una fila por jugador, una
/// columna por set). Cada set completo y válido (11 con 2 de diferencia) se
/// guarda solo "en vivo" para que jugadores y público lo vean; cuando alguien
/// gana el partido se confirma y queda como resultado oficial (avanza la
/// llave, tablas, avisos), igual que si lo cargara el organizador.
class RefereeScreen extends StatefulWidget {
  final String matchType;
  final String matchId;
  const RefereeScreen({super.key, required this.matchType, required this.matchId});

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _RefereeScreenState extends State<RefereeScreen> {
  final _playerApi = PlayerApi();
  final _api = RefereeApi();

  MatchDetail? _m;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _done = false;
  // Lo cerró este árbitro recién: se le agradece en pantalla.
  bool _thanked = false;
  String _savedLive = ""; // sets ya guardados en vivo (para no repetir el envío)

  List<TextEditingController> _a = [];
  List<TextEditingController> _b = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._a, ..._b]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final m = await _playerApi.getMatchDetail(widget.matchType, widget.matchId);
      if (!mounted) return;
      final n = m.bestOfSets;
      final prev = m.setScores ?? const [];
      setState(() {
        _m = m;
        _a = List.generate(n, (i) => TextEditingController(text: i < prev.length ? "${prev[i].p1}" : ""));
        _b = List.generate(n, (i) => TextEditingController(text: i < prev.length ? "${prev[i].p2}" : ""));
        _savedLive = prev.map((x) => "${x.p1}-${x.p2}").join(",");
        _done = m.status == "played" || m.status == "walkover";
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Cálculo a partir de la grilla ────────────────────────────────────

  int get _toWin => ((_m?.bestOfSets ?? 3) / 2).ceil();

  /// Set legal: se gana con 11; desde 10-10 hay que ganar por 2 (12-10, 13-11…).
  static bool _legal(int a, int b) {
    if (a == b) return false;
    final w = a > b ? a : b, l = a > b ? b : a;
    if (w < 11) return false;
    if (w == 11) return l <= 9;
    return l == w - 2;
  }

  (int, int)? _set(int i) {
    final x = int.tryParse(_a[i].text.trim()), y = int.tryParse(_b[i].text.trim());
    if (x == null || y == null) return null;
    return (x, y);
  }

  bool _filled(int i) => _a[i].text.trim().isNotEmpty || _b[i].text.trim().isNotEmpty;

  /// Sets válidos y seguidos desde el primero (lo que se puede guardar).
  List<(int, int)> get _validPrefix {
    final out = <(int, int)>[];
    var w1 = 0, w2 = 0;
    for (var i = 0; i < _a.length; i++) {
      final s = _set(i);
      if (s == null || !_legal(s.$1, s.$2)) break;
      out.add(s);
      s.$1 > s.$2 ? w1++ : w2++;
      if (w1 >= _toWin || w2 >= _toWin) break; // partido decidido
    }
    return out;
  }

  int _wins(List<(int, int)> sets, int player) =>
      sets.where((s) => player == 1 ? s.$1 > s.$2 : s.$2 > s.$1).length;

  /// Mensaje de error de la grilla, o null si está bien.
  String? get _problem {
    final valid = _validPrefix;
    for (var i = 0; i < _a.length; i++) {
      if (!_filled(i)) continue;
      final s = _set(i);
      if (i > valid.length) return "Set ${i + 1}: completa antes los sets anteriores.";
      if (i == valid.length) {
        if (s == null) return null; // a medio escribir
        if (!_legal(s.$1, s.$2)) return "Set ${i + 1}: ${s.$1}-${s.$2} no es válido (se gana con 11 y 2 de diferencia).";
      }
      if (i >= valid.length && _decided(valid)) return "El partido ya está decidido: borra el set ${i + 1}.";
    }
    return null;
  }

  bool _decided(List<(int, int)> s) => _wins(s, 1) >= _toWin || _wins(s, 2) >= _toWin;

  void _onChanged() {
    setState(() {});
    final valid = _validPrefix;
    // Set terminado nuevo o corregido → se guarda en vivo.
    final key = valid.map((x) => "${x.$1}-${x.$2}").join(",");
    if (!_done && valid.isNotEmpty && key != _savedLive && _problem == null) {
      _savedLive = key;
      HapticFeedback.mediumImpact();
      _api.saveLive(widget.matchType, widget.matchId, valid).catchError((e) {
        if (mounted) showToast(context, "No se pudo guardar el set en vivo: ${e.toString().replaceFirst("Exception: ", "")}", error: true);
      });
    }
  }

  Future<void> _confirm() async {
    final m = _m!;
    final sets = _validPrefix;
    final w1 = _wins(sets, 1) > _wins(sets, 2);
    final ok = await confirmAction(
      context,
      title: "Confirmar resultado",
      message:
          "Ganó ${w1 ? m.player1Name : m.player2Name} ${_wins(sets, w1 ? 1 : 2)}-${_wins(sets, w1 ? 2 : 1)}.\n${sets.map((s) => "${s.$1}-${s.$2}").join("  ·  ")}\n\nSe guarda como resultado oficial.",
      confirmLabel: "Confirmar",
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _api.submitResult(
        matchType: widget.matchType,
        matchId: widget.matchId,
        winnerId: (w1 ? m.player1Id : m.player2Id)!,
        sets: sets,
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _thanked = true;
      });
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TopHeader(title: "Arbitrar"),
                const SizedBox(height: 12),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState();
    if (_error != null || _m == null) {
      return ErrorStateView(message: "No se pudo abrir el partido.\n${_error ?? ""}", onRetry: _load);
    }
    final m = _m!;
    final valid = _validPrefix;
    final s1 = _wins(valid, 1), s2 = _wins(valid, 2);
    final decided = _decided(valid);
    final problem = _problem;
    final current = decided ? -1 : valid.length; // set que se está jugando

    // Mensaje de ayuda con ícono (guía / error / guardado).
    final (IconData hintIcon, Color hintColor, String hintText) = problem != null
        ? (Icons.warning_amber_rounded, AppColors.scorifyNegative, problem)
        : valid.isEmpty
            ? (Icons.info_rounded, AppColors.scorifyMint, "Al terminar cada set, escribe su marcador. Se guarda solo y los jugadores lo ven en vivo.")
            : decided
                ? (Icons.check_circle_rounded, AppColors.scorifyButterfly, "Partido decidido. Revisa los sets y confirma el resultado.")
                : (Icons.check_circle_rounded, AppColors.scorifyButterfly,
                    "${valid.length} ${valid.length == 1 ? "set guardado" : "sets guardados"} en vivo");

    return ListView(
      children: [
        // ── Marcador ──
        SectionCard(
          title: "Marcador",
          icon: Icons.scoreboard_rounded,
          gradient: AppColors.featuredGradient,
          trailing: Padding(padding: const EdgeInsets.only(right: 10), child: _LiveBadge(decided: decided, started: valid.isNotEmpty)),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (m.tableNumber != null) _chip("MESA ${m.tableNumber}", AppColors.scorifyMint),
                  _chip(m.categoryType, AppColors.scorifyTextMuted),
                  _chip("Mejor de ${m.bestOfSets}", AppColors.scorifyTextMuted),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _player(m.player1Id, m.player1Name, s1 > s2)),
                  Column(
                    children: [
                      Text("$s1 – $s2",
                          style: TextStyle(
                            fontFamily: AppTypography.body,
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: decided ? AppColors.scorifyButterfly : AppColors.scorifyText,
                          )),
                      const Text("SETS",
                          style: TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: AppColors.scorifyTextMuted)),
                    ],
                  ),
                  Expanded(child: _player(m.player2Id, m.player2Name, s2 > s1)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Marcador por set ──
        SectionCard(
          title: "Marcador por set",
          icon: Icons.grid_view_rounded,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 92),
                    for (var i = 0; i < _a.length; i++)
                      SizedBox(
                        width: 58,
                        child: Text("S${i + 1}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.body,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: i == current ? AppColors.scorifyMint : AppColors.scorifyTextMuted,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _row(1, m.player1Name, current),
                const SizedBox(height: 8),
                _row(2, m.player2Name, current),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: hintColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(hintIcon, size: 18, color: hintColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(hintText,
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, height: 1.35, color: problem != null ? hintColor : AppColors.scorifyText)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        if (_done)
          SectionCard(
            title: _thanked ? "¡Gracias por arbitrar!" : "Partido terminado",
            icon: _thanked ? Icons.favorite_rounded : Icons.check_circle_rounded,
            titleColor: AppColors.scorifyButterfly,
            gradient: _thanked ? AppColors.featuredGradient : AppColors.cardGradient,
            child: Text(
              _thanked
                  ? "Ganó ${s1 >= s2 ? m.player1Name : m.player2Name} ${s1 >= s2 ? s1 : s2}-${s1 >= s2 ? s2 : s1}. El resultado quedó guardado como oficial. Tu ayuda hace que el campeonato avance a tiempo."
                  : "Ganó ${s1 >= s2 ? m.player1Name : m.player2Name} ${s1 >= s2 ? s1 : s2}-${s1 >= s2 ? s2 : s1}. El resultado ya está cargado.",
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, height: 1.4, color: AppColors.scorifyText),
            ),
          )
        else
          AppButton(
            label: "Confirmar resultado",
            icon: Icons.check_rounded,
            onPressed: decided && problem == null ? _confirm : null,
            loading: _saving,
            height: 48,
          ),
      ],
    );
  }

  Widget _chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c)),
      );

  /// Jugador en el marcador: foto y nombre; el que va ganando en verde.
  Widget _player(String? id, String name, bool leading) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: leading ? appButtonGradient : null,
              color: leading ? null : AppColors.scorifySurface2,
            ),
            child: UserAvatar(userId: id, size: 52),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: leading ? AppColors.scorifyButterfly : AppColors.scorifyText,
            ),
          ),
        ],
      );

  Widget _row(int player, String name, int current) {
    final ctrls = player == 1 ? _a : _b;
    final short = name.trim().split(RegExp(r"\s+")).take(2).join(" ");
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(short,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
        ),
        for (var i = 0; i < ctrls.length; i++) SizedBox(width: 58, child: Center(child: _cell(i, player, ctrls[i], i == current))),
      ],
    );
  }

  Widget _cell(int i, int player, TextEditingController c, bool current) {
    final s = _set(i);
    final won = s != null && _legal(s.$1, s.$2) && (player == 1 ? s.$1 > s.$2 : s.$2 > s.$1);
    return SizedBox(
      width: 52,
      height: 52,
      child: TextField(
        controller: c,
        enabled: !_done && !_saving,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => _onChanged(),
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: won ? AppColors.scorifyButterfly : AppColors.scorifyText,
        ),
        decoration: InputDecoration(
          counterText: "",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          // Set ganado: fondo verde suave; el que se juega: borde turquesa.
          fillColor: won ? AppColors.scorifyButterfly.withValues(alpha: 0.12) : AppColors.scorifyInput,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: current ? BorderSide(color: AppColors.scorifyMint.withValues(alpha: 0.6), width: 1.2) : BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.8),
          ),
        ),
      ),
    );
  }
}

/// "EN VIVO" con punto que late mientras se juega; "DECIDIDO" al final.
class _LiveBadge extends StatefulWidget {
  final bool decided;
  final bool started;
  const _LiveBadge({required this.decided, required this.started});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.decided) {
      return const Text("DECIDIDO",
          style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.scorifyButterfly));
    }
    if (!widget.started) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_p),
          child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.scorifyNegative)),
        ),
        const SizedBox(width: 6),
        const Text("EN VIVO",
            style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.scorifyNegative)),
      ],
    );
  }
}
