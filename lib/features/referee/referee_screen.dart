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

/// Pantalla de árbitro: se anota punto a punto (+1 por jugador). La app
/// arma cada set sola (11 puntos con 2 de diferencia) y al cerrarse un set lo
/// guarda en vivo para que jugadores y público lo sigan. Cuando alguien gana
/// el partido (mejor de 3/5/7) se confirma y se guarda como resultado final,
/// igual que si lo cargara el organizador (avanza la llave, tablas, avisos).
class RefereeScreen extends StatefulWidget {
  final String matchType;
  final String matchId;
  const RefereeScreen({super.key, required this.matchType, required this.matchId});

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _Snapshot {
  final List<(int, int)> sets;
  final int p1;
  final int p2;
  const _Snapshot(this.sets, this.p1, this.p2);
}

class _RefereeScreenState extends State<RefereeScreen> {
  final _playerApi = PlayerApi();
  final _api = RefereeApi();

  MatchDetail? _m;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _done = false;

  List<(int, int)> _sets = [];
  int _p1 = 0;
  int _p2 = 0;
  final List<_Snapshot> _undo = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await _playerApi.getMatchDetail(widget.matchType, widget.matchId);
      if (!mounted) return;
      setState(() {
        _m = m;
        // Retoma desde los sets ya guardados en vivo (si se cerró la app).
        _sets = [for (final s in m.setScores ?? const []) (s.p1, s.p2)];
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

  int get _toWin => ((_m?.bestOfSets ?? 3) / 2).ceil();
  int get _won1 => _sets.where((s) => s.$1 > s.$2).length;
  int get _won2 => _sets.where((s) => s.$2 > s.$1).length;

  static bool _setOver(int a, int b) => (a >= 11 || b >= 11) && (a - b).abs() >= 2;

  void _point(int player, int delta) {
    if (_done || _saving) return;
    final p1 = player == 1 ? _p1 + delta : _p1;
    final p2 = player == 2 ? _p2 + delta : _p2;
    if (p1 < 0 || p2 < 0) return;
    HapticFeedback.selectionClick();
    _undo.add(_Snapshot([..._sets], _p1, _p2));
    if (delta > 0 && _setOver(p1, p2)) {
      _closeSet(p1, p2);
    } else {
      setState(() {
        _p1 = p1;
        _p2 = p2;
      });
    }
  }

  void _closeSet(int a, int b) {
    final name = a > b ? _short(_m!.player1Name) : _short(_m!.player2Name);
    setState(() {
      _sets = [..._sets, (a, b)];
      _p1 = 0;
      _p2 = 0;
    });
    HapticFeedback.mediumImpact();
    showToast(context, "Set para $name ($a-$b)");
    _saveLive();
    if (_won1 >= _toWin || _won2 >= _toWin) _askFinish();
  }

  Future<void> _saveLive() async {
    try {
      await _api.saveLive(widget.matchType, widget.matchId, _sets);
    } catch (e) {
      if (mounted) showToast(context, "No se pudo guardar el set en vivo: ${e.toString().replaceFirst("Exception: ", "")}", error: true);
    }
  }

  void _undoLast() {
    if (_undo.isEmpty || _done) return;
    final s = _undo.removeLast();
    final setRemoved = s.sets.length != _sets.length;
    setState(() {
      _sets = s.sets;
      _p1 = s.p1;
      _p2 = s.p2;
    });
    if (setRemoved) _saveLive();
  }

  Future<void> _typeSet() async {
    final a = TextEditingController(), b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scorifyDeep,
        title: const Text("Escribir set", style: TextStyle(color: AppColors.scorifyText)),
        content: Row(
          children: [
            Expanded(child: _numField(a, _short(_m!.player1Name))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("-", style: TextStyle(color: AppColors.scorifyText, fontSize: 22))),
            Expanded(child: _numField(b, _short(_m!.player2Name))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Agregar set")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final x = int.tryParse(a.text) ?? -1, y = int.tryParse(b.text) ?? -1;
    if (x < 0 || y < 0 || !_setOver(x, y) || (x > 11 || y > 11) && (x - y).abs() != 2) {
      showToast(context, "Set inválido: se gana con 11 y 2 de diferencia (ej. 11-7, 12-10).", error: true);
      return;
    }
    _undo.add(_Snapshot([..._sets], _p1, _p2));
    _closeSet(x, y);
  }

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.scorifyText, fontSize: 22, fontWeight: FontWeight.w800),
        decoration: InputDecoration(labelText: label, labelStyle: AppTypography.bodyMuted),
      );

  Future<void> _askFinish() async {
    final m = _m!;
    final w1 = _won1 > _won2;
    final winner = w1 ? m.player1Name : m.player2Name;
    final ok = await confirmAction(
      context,
      title: "Terminó el partido",
      message: "Ganó $winner ${w1 ? _won1 : _won2}-${w1 ? _won2 : _won1}.\n${_sets.map((s) => "${s.$1}-${s.$2}").join("  ·  ")}\n\n¿Confirmar el resultado? Se guarda como resultado oficial.",
      confirmLabel: "Confirmar resultado",
    );
    if (!mounted) return;
    if (ok != true) return; // puede deshacer y corregir
    setState(() => _saving = true);
    try {
      await _api.submitResult(
        matchType: widget.matchType,
        matchId: widget.matchId,
        winnerId: (w1 ? m.player1Id : m.player2Id)!,
        sets: _sets,
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

  static String _short(String full) {
    final p = full.trim().split(RegExp(r"\s+"));
    return p.length <= 2 ? full : "${p[0]} ${p[1]}";
  }

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
    final mesa = m.tableNumber != null ? "Mesa ${m.tableNumber} · " : "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "$mesa${m.categoryType} · Mejor de ${m.bestOfSets}",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        // Sets cerrados
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _sets.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  "Set ${i + 1}: ${_sets[i].$1}-${_sets[i].$2}",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
                ),
              ),
            if (_sets.isEmpty)
              Text("Toca el lado del jugador que gana el punto", style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _side(1, m.player1Name, _won1, _p1)),
              const SizedBox(width: 10),
              Expanded(child: _side(2, m.player2Name, _won2, _p2)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_done)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(14)),
            child: Text(
              "Partido terminado: ${_won1 >= _won2 ? m.player1Name : m.player2Name} ganó ${_won1 >= _won2 ? _won1 : _won2}-${_won1 >= _won2 ? _won2 : _won1}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTypography.body, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _undo.isEmpty || _saving ? null : _undoLast,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text("Deshacer"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _typeSet,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text("Escribir set"),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _side(int player, String name, int setsWon, int points) {
    final color = player == 1 ? AppColors.scorifyMint : AppColors.scorifyButterfly;
    final enabled = !_done && !_saving;
    return Material(
      color: AppColors.scorifyCardFill,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => _point(player, 1) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Column(
            children: [
              Text(
                _short(name),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.scorifyText),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(
                  "Sets $setsWon",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w800, color: color),
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: Text(
                      "$points",
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 110, height: 1, fontWeight: FontWeight.w900, color: color),
                    ),
                  ),
                ),
              ),
              Text("+1  toca aquí", style: AppTypography.bodyMuted.copyWith(fontSize: 11)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: enabled && points > 0 ? () => _point(player, -1) : null,
                  child: const Text("−1"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
