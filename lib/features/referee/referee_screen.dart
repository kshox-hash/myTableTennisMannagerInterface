import "package:myttmi/core/ui/card_border.dart";
import "package:myttmi/core/ui/app_button.dart";
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
      setState(() => _done = true);
      showToast(context, "Resultado guardado. ¡Gracias por arbitrar!");
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
    final mesa = m.tableNumber != null ? "Mesa ${m.tableNumber} · " : "";

    return ListView(
      children: [
        Text(
          "$mesa${m.categoryType} · Mejor de ${m.bestOfSets}",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 14),
        // Marcador de sets
        Row(
          children: [
            Expanded(child: _nameBig(m.player1Name, s1 > s2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: decided ? AppColors.scorifyButterfly : AppColors.scorifySurface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$s1 - $s2",
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: decided ? AppColors.scorifyOnButterfly : AppColors.scorifyText,
                ),
              ),
            ),
            Expanded(child: _nameBig(m.player2Name, s2 > s1, right: true)),
          ],
        ),
        const SizedBox(height: 16),
        // Grilla: una fila por jugador, una columna por set (igual al panel).
        CardBorder(child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 104),
                    for (var i = 0; i < _a.length; i++)
                      SizedBox(
                        width: 56,
                        child: Text("Set ${i + 1}",
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMuted.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _row(1, m.player1Name),
                const SizedBox(height: 8),
                _row(2, m.player2Name),
              ],
            ),
          ),
        )),
        const SizedBox(height: 10),
        if (problem != null)
          Text(problem, style: const TextStyle(color: AppColors.scorifyNegative, fontSize: 13, fontWeight: FontWeight.w600))
        else if (!_done)
          Text(
            valid.isEmpty
                ? "Al terminar cada set, escribe su marcador. Se guarda solo y los jugadores lo ven en vivo."
                : decided
                    ? "Partido decidido. Revisa los sets y confirma el resultado."
                    : "${valid.length} ${valid.length == 1 ? "set guardado" : "sets guardados"} en vivo ✓",
            style: AppTypography.bodyMuted.copyWith(fontSize: 12.5),
          ),
        const SizedBox(height: 18),
        if (_done)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(14)),
            child: Text(
              "Partido terminado: ${s1 >= s2 ? m.player1Name : m.player2Name} ganó ${s1 >= s2 ? s1 : s2}-${s1 >= s2 ? s2 : s1}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTypography.body, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
            ),
          )
        else
          AppButton(
            label: "Confirmar resultado",
            onPressed: decided && problem == null ? _confirm : null,
            loading: _saving,
            height: 48,
          ),
      ],
    );
  }

  Widget _nameBig(String name, bool winning, {bool right = false}) => Text(
        name,
        maxLines: 2,
        textAlign: right ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: winning ? AppColors.scorifyButterfly : AppColors.scorifyText,
        ),
      );

  Widget _row(int player, String name) {
    final ctrls = player == 1 ? _a : _b;
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.scorifyText)),
        ),
        for (var i = 0; i < ctrls.length; i++) SizedBox(width: 56, child: Center(child: _cell(i, player, ctrls[i]))),
      ],
    );
  }

  Widget _cell(int i, int player, TextEditingController c) {
    final s = _set(i);
    final won = s != null && _legal(s.$1, s.$2) && (player == 1 ? s.$1 > s.$2 : s.$2 > s.$1);
    return SizedBox(
      width: 48,
      height: 46,
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
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: won ? AppColors.scorifyButterfly : AppColors.scorifyText,
        ),
        decoration: InputDecoration(
          counterText: "",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: AppColors.scorifyInput,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.5),
          ),
        ),
      ),
    );
  }
}
