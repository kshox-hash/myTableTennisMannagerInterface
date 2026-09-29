import "package:flutter/material.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/calendar/api/calendar_api.dart";
import "package:myttmi/features/calendar/models/calendar_event.dart";
import "package:myttmi/features/shell/tab_auto_refresh.dart";
import "package:myttmi/features/tournament/api/tournament_api.dart";
import "package:myttmi/features/tournament/presentation/tournament_detail_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

const _months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
const _monthsShort = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];
const _weekdays = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"];

const TextStyle _muted = TextStyle(
  fontFamily: AppTypography.body,
  fontSize: 12.5,
  fontWeight: FontWeight.w500,
  color: AppColors.scorifyTextMuted,
);

String _genderLabel(String g) => switch (g) {
      "male" => "Masculino",
      "female" => "Femenino",
      "mixed" => "Mixto",
      _ => g,
    };

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TabAutoRefreshMixin<CalendarScreen> {
  @override
  int get tabIndex => 1;

  @override
  void onTabActivated() => _reloadAll();

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime.now();

  final CalendarApi _api = CalendarApi();
  final _tournamentApi = TournamentApi();

  bool _loading = false;
  String? _error;
  final Map<DateTime, List<CalendarEvent>> _itemsByDay = {};

  // "Tus próximos campeonatos": desde hoy hasta 6 meses — siempre visible,
  // aunque el campeonato no caiga en el mes que se está mirando.
  List<CalendarEvent> _upcoming = [];

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _loadMonth(_focusedMonth);
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      // Desde 30 días atrás: un campeonato que se sigue jugando después de su
      // fecha (se alargó o dura más de un día) no debe desaparecer de acá.
      final events = (await _api.myEvents(from: today.subtract(const Duration(days: 30)), to: today.add(const Duration(days: 180))))
          .where((e) => !e.finished && (!e.date.isBefore(today) || e.inProgress))
          .toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      if (mounted) setState(() => _upcoming = events);
    } catch (_) {
      // El error se muestra en la sección del mes; esta lista es un extra.
    }
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    try {
      final events = await _api.myEvents(from: first, to: last);
      final map = <DateTime, List<CalendarEvent>>{};
      for (final e in events) {
        map.putIfAbsent(_dayKey(e.date), () => []).add(e);
      }
      if (!mounted) return;
      setState(() {
        _itemsByDay
          ..clear()
          ..addAll(map);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
      _selectedDay = _clampSelectedToMonth(_selectedDay, _focusedMonth);
    });
    _loadMonth(_focusedMonth);
  }

  // Tocar un próximo campeonato lleva el calendario a ese día.
  void _jumpTo(DateTime day) {
    final month = DateTime(day.year, day.month, 1);
    final changed = month != _focusedMonth;
    setState(() {
      _focusedMonth = month;
      _selectedDay = day;
    });
    if (changed) _loadMonth(month);
  }

  @override
  Widget build(BuildContext context) {
    final dayItems = _itemsByDay[_dayKey(_selectedDay)] ?? const <CalendarEvent>[];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const TopHeader(title: "Calendario", showBack: false),
        const SizedBox(height: 6),
        const Text("Tus campeonatos inscritos, día a día.", style: _muted),

        if (_upcoming.isNotEmpty) ...[
          _Section(_upcoming.any((e) => e.inProgress) ? "Tus campeonatos" : "Tus próximos campeonatos"),
          for (final e in _upcoming.take(3)) ...[
            _EventCard(
              event: e,
              onTap: () => _openTournament(e.tournamentId),
              onDateTap: () => _jumpTo(e.date),
            ),
            const SizedBox(height: 10),
          ],
        ],

        const _Section("Calendario"),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.scorifyText),
                    ),
                  ),
                  _RoundIcon(icon: Icons.chevron_left_rounded, onTap: () => _goMonth(-1)),
                  const SizedBox(width: 6),
                  _RoundIcon(
                    icon: Icons.today_rounded,
                    onTap: () {
                      final now = DateTime.now();
                      _jumpTo(DateTime(now.year, now.month, now.day));
                    },
                  ),
                  const SizedBox(width: 6),
                  _RoundIcon(icon: Icons.chevron_right_rounded, onTap: () => _goMonth(1)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final w in const ["L", "M", "M", "J", "V", "S", "D"])
                    Expanded(child: Center(child: Text(w, style: _muted.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)))),
                ],
              ),
              const SizedBox(height: 6),
              _CalendarMonthGrid(
                month: _focusedMonth,
                selectedDay: _selectedDay,
                hasItems: (d) => (_itemsByDay[_dayKey(d)]?.isNotEmpty ?? false),
                onSelectDay: (d) => setState(() => _selectedDay = d),
              ),
            ],
          ),
        ),

        _Section(_dayTitle(_selectedDay)),
        if (_error != null)
          ErrorStateView(message: "No pudimos cargar tu calendario.\n$_error", onRetry: () => _loadMonth(_focusedMonth))
        else if (_loading)
          const Padding(padding: EdgeInsets.only(top: 12), child: LoadingState())
        else if (dayItems.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: AppColors.scorifyTextMuted, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text("No tienes campeonatos este día.", style: _muted)),
              ],
            ),
          )
        else
          for (final e in dayItems) ...[
            _EventCard(event: e, onTap: () => _openTournament(e.tournamentId)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dayTitle(DateTime d) {
    final w = _weekdays[(d.weekday - 1).clamp(0, 6)];
    return "${w[0].toUpperCase()}${w.substring(1)} ${d.day} de ${_months[d.month - 1].toLowerCase()}";
  }

  Future<void> _openTournament(String tournamentId) async {
    try {
      final tournament = await _tournamentApi.getTournamentById(tournamentId);
      if (!mounted) return;
      Navigator.push(context, CyberPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)));
    } catch (e) {
      if (!mounted) return;
      showToast(context, "No pudimos abrir el campeonato.", error: true);
    }
  }

  DateTime _clampSelectedToMonth(DateTime selected, DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    if (selected.isBefore(first)) return first;
    if (selected.isAfter(last)) return last;
    return selected;
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(title,
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
      );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.scorifyInput,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 36, height: 36, child: Icon(icon, color: AppColors.scorifyText, size: 20)),
        ),
      );
}

/// Campeonato inscrito: bloque de fecha a la izquierda (como un calendario
/// de pared) y datos a la derecha.
class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback? onDateTap;
  const _EventCard({required this.event, required this.onTap, this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final e = event;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(e.date.year, e.date.month, e.date.day).difference(today).inDays;
    final when = e.finished
        ? "Finalizado"
        : e.inProgress
        ? "En curso"
        : days == 0
        ? "Hoy"
        : days == 1
            ? "Mañana"
            : days > 1
                ? "En $days días"
                : null;
    final loc = (e.location ?? "").trim();

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Text(_monthsShort[e.date.month - 1],
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.scorifyMint, letterSpacing: 1)),
                  Text("${e.date.day}",
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.scorifyText, height: 1.15)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.tournamentName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.scorifyText, height: 1.25)),
                const SizedBox(height: 4),
                Text("${e.categoryName} · ${_genderLabel(e.gender)}", maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted),
                if (loc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: AppColors.scorifyMint),
                      const SizedBox(width: 4),
                      Expanded(child: Text(loc, maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (when != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !e.finished && (e.inProgress || days <= 1) ? AppColors.scorifyButterfly : AppColors.scorifySurface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                when,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !e.finished && (e.inProgress || days <= 1) ? AppColors.scorifyOnButterfly : AppColors.scorifyTextMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ------------------------------ GRID MES ------------------------------ */

class _CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final bool Function(DateTime day) hasItems;
  final ValueChanged<DateTime> onSelectDay;

  const _CalendarMonthGrid({required this.month, required this.selectedDay, required this.hasItems, required this.onSelectDay});

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = (firstOfMonth.weekday - 1) % 7;
    final rows = ((leadingEmpty + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final dayNum = r * 7 + c - leadingEmpty + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 46));
            }
            final date = DateTime(month.year, month.month, dayNum);
            return Expanded(
              child: _DayCell(
                day: dayNum,
                isSelected: _sameDay(date, selectedDay),
                isToday: _sameDay(date, DateTime.now()),
                hasItems: hasItems(date),
                onTap: () => onSelectDay(date),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Día del mes: seleccionado = círculo celeste, hoy = anillo, con
/// campeonato = punto verde debajo del número.
class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasItems;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.isSelected, required this.isToday, required this.hasItems, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.scorifyMint : Colors.transparent,
                border: !isSelected && isToday ? Border.all(color: AppColors.scorifyMint, width: 1.5) : null,
              ),
              child: Text(
                "$day",
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 14,
                  fontWeight: isSelected || isToday || hasItems ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.scorifyOnMint : AppColors.scorifyText,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: hasItems ? AppColors.scorifyButterfly : Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
