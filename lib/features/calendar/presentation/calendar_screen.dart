import "package:flutter/material.dart";
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

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TabAutoRefreshMixin<CalendarScreen> {
  @override
  int get tabIndex => 1;

  @override
  void onTabActivated() => _loadMonth(_focusedMonth);

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDay = DateTime.now();

  final CalendarApi _api = CalendarApi();

  bool _loading = false;
  String? _error;

  final Map<DateTime, List<_CalendarItem>> _itemsByDay = {};
  final _tournamentApi = TournamentApi();

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedMonth);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() {
      _loading = true;
      _error = null;
      _itemsByDay.clear();
    });

    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    try {
      final events = await _api.myEvents(from: first, to: last);

      for (final e in events) {
        final key = _dayKey(e.date);
        _itemsByDay.putIfAbsent(key, () => []);
        _itemsByDay[key]!.add(_CalendarItem.fromEvent(e));
      }

      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _monthLabel(_focusedMonth);
    final dayItems = _itemsByDay[_dayKey(_selectedDay)] ?? const [];

    return ListView(
      // Toda la pantalla es una sola lista scrolleable — si la grilla del mes
      // tiene 6 filas, la agenda de abajo sigue siendo alcanzable.
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const TopHeader(title: "Calendario", showBack: false),

        const SizedBox(height: 14),

        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(monthLabel, style: AppTypography.h2)),
                  HeaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                          1,
                        );
                        _selectedDay = _clampSelectedToMonth(
                          _selectedDay,
                          _focusedMonth,
                        );
                      });
                      _loadMonth(_focusedMonth);
                    },
                  ),
                  const SizedBox(width: 8),
                  HeaderIconButton(
                    icon: Icons.today_rounded,
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
                        _focusedMonth = DateTime(now.year, now.month, 1);
                        _selectedDay = now;
                      });
                      _loadMonth(_focusedMonth);
                    },
                  ),
                  const SizedBox(width: 8),
                  HeaderIconButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                          1,
                        );
                        _selectedDay = _clampSelectedToMonth(
                          _selectedDay,
                          _focusedMonth,
                        );
                      });
                      _loadMonth(_focusedMonth);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: const [
                  _WeekLabel("L"),
                  _WeekLabel("M"),
                  _WeekLabel("M"),
                  _WeekLabel("J"),
                  _WeekLabel("V"),
                  _WeekLabel("S"),
                  _WeekLabel("D"),
                ],
              ),
              const SizedBox(height: 8),

              _CalendarMonthGrid(
                month: _focusedMonth,
                selectedDay: _selectedDay,
                hasItems: (d) => (_itemsByDay[_dayKey(d)]?.isNotEmpty ?? false),
                onSelectDay: (d) => setState(() => _selectedDay = d),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Text(
                "Agenda · ${_dayTitle(_selectedDay)}",
                style: AppTypography.h2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                _loading ? "…" : "${dayItems.length} item(s)",
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_error != null)
          ErrorStateView(
            message: "No pudimos cargar tu calendario.\n$_error",
            onRetry: () => _loadMonth(_focusedMonth),
          )
        else if (_loading)
          const LoadingState()
        else if (dayItems.isEmpty)
          const EmptyState(
            icon: Icons.event_available_rounded,
            message: "No tenés campeonatos este día.",
          )
        else
          ...dayItems.map(
            (e) => _AgendaCard(
              item: e,
              onTap: () => _openTournament(e.tournamentId),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  String _monthLabel(DateTime d) {
    const months = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return "${months[d.month - 1]} ${d.year}";
  }

  String _dayTitle(DateTime d) {
    const wd = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    final w = wd[(d.weekday - 1).clamp(0, 6)];
    return "$w ${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}";
  }

  Future<void> _openTournament(String tournamentId) async {
    try {
      final tournament = await _tournamentApi.getTournamentById(tournamentId);
      if (!mounted) return;
      Navigator.push(
        context,
        CyberPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: tournament),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No pudimos abrir el campeonato.\n$e")),
      );
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

/* ------------------------------ MODELO UI ------------------------------ */

enum _CalendarItemType { tournament }

class _CalendarItem {
  final _CalendarItemType type;
  final String tournamentId;
  final String title;
  final String subtitle;
  final String meta;

  const _CalendarItem({
    required this.type,
    required this.tournamentId,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  factory _CalendarItem.fromEvent(CalendarEvent e) {
    String genderLabel(String g) {
      switch (g) {
        case "male":
          return "Masculino";
        case "female":
          return "Femenino";
        case "mixed":
          return "Mixto";
        default:
          return g;
      }
    }

    final loc = (e.location ?? "").trim();
    return _CalendarItem(
      type: _CalendarItemType.tournament,
      tournamentId: e.tournamentId,
      title: e.tournamentName,
      subtitle: "Categoría: ${e.categoryName} · ${genderLabel(e.gender)}",
      meta: loc.isEmpty ? "Inscrito" : loc,
    );
  }
}

/* ------------------------------ GRID MES ------------------------------ */

class _CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final bool Function(DateTime day) hasItems;
  final ValueChanged<DateTime> onSelectDay;

  const _CalendarMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.hasItems,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingEmpty = (firstOfMonth.weekday - 1) % 7;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final index = r * 7 + c;
            final dayNum = index - leadingEmpty + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(month.year, month.month, dayNum);
            final isSelected = _sameDay(date, selectedDay);
            final isToday = _sameDay(date, DateTime.now());
            final dot = hasItems(date);

            return Expanded(
              child: _DayCell(
                day: dayNum,
                isSelected: isSelected,
                isToday: isToday,
                hasItems: dot,
                onTap: () => onSelectDay(date),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasItems;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? AppColors.scorifyMint.withOpacity(0.16)
        : Colors.white.withOpacity(0.04);
    final border = isSelected
        ? AppColors.scorifyMint.withOpacity(0.45)
        : Colors.white.withOpacity(0.08);
    final textColor = isSelected
        ? AppColors.scorifyText
        : AppColors.scorifyText.withOpacity(0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  "$day",
                  style: AppTypography.mono14.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isToday)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.scorifyMint,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                if (hasItems)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.scorifyMint,
                        borderRadius: BorderRadius.circular(99),
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

class _WeekLabel extends StatelessWidget {
  final String t;
  const _WeekLabel(this.t);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(child: Text(t, style: AppTypography.caption)),
    );
  }
}

/* ------------------------------ UI ------------------------------ */

class _AgendaCard extends StatelessWidget {
  final _CalendarItem item;
  final VoidCallback onTap;
  const _AgendaCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.scorifyMint.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.scorifyCardBorder),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.scorifyMint,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.scorifyTextFaint,
            ),
          ],
        ),
      ),
    );
  }
}
