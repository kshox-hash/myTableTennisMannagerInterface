import "package:myttmi/core/ui/card_border.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/player/models/achievement_model.dart";

// Colores de medalla (oro / plata / bronce).
const _gold = [Color(0xFFFFE08A), Color(0xFFE0A526)];
const _silver = [Color(0xFFF1F4F6), Color(0xFFA9B4BC)];
const _bronze = [Color(0xFFF2B98A), Color(0xFFB8733F)];

List<Color> _medalColors(int position) => switch (position) {
      1 => _gold,
      2 => _silver,
      _ => _bronze,
    };

String _placeLabel(int position) => switch (position) {
      1 => "Campeón",
      2 => "Subcampeón",
      _ => "3er lugar",
    };

const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

String? _shortDate(String? iso) {
  final d = DateTime.tryParse(iso ?? "");
  if (d == null) return null;
  return "${d.day} ${_months[d.month - 1]} ${d.year}";
}

/// Medalla dibujada (disco con degradado y el puesto), sin emoji.
class Medal extends StatelessWidget {
  final int position;
  final double size;
  const Medal({super.key, required this.position, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = _medalColors(position);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: c.last.withValues(alpha: 0.35), blurRadius: 10)],
      ),
      child: Text(
        "$position°",
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2A1E05),
        ),
      ),
    );
  }
}

/// Fila de un podio: medalla + "Campeón · categoría" + torneo y fecha.
class AchievementRow extends StatelessWidget {
  final PlayerAchievement achievement;
  const AchievementRow({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final date = _shortDate(a.eventDate);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Medal(position: a.position),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_placeLabel(a.position)} · ${a.categoryLabel}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.scorifyText),
                ),
                const SizedBox(height: 2),
                Text(
                  [a.tournamentName, if (date != null) date].join(" · "),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Palmarés": medallero del jugador (cuántos oros, platas y bronces) y la
/// lista de sus podios en categorías finalizadas. En el perfil propio se
/// muestra aunque esté vacío (showEmpty); en el de otro jugador se oculta.
class AchievementsCard extends StatefulWidget {
  final List<PlayerAchievement> achievements;
  final bool showEmpty;
  const AchievementsCard({super.key, required this.achievements, this.showEmpty = false});

  @override
  State<AchievementsCard> createState() => _AchievementsCardState();
}

class _AchievementsCardState extends State<AchievementsCard> {
  static const _preview = 5;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.achievements.toList()
      ..sort((a, b) => (b.eventDate ?? "").compareTo(a.eventDate ?? ""));
    if (list.isEmpty && !widget.showEmpty) return const SizedBox.shrink();

    final golds = list.where((a) => a.position == 1).length;
    final silvers = list.where((a) => a.position == 2).length;
    final bronzes = list.where((a) => a.position >= 3).length;
    final shown = _all ? list : list.take(_preview).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBorder(radius: 20, child: Container(
        decoration: BoxDecoration(color: AppColors.scorifyCardFill, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFE0A526), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Palmarés",
                      style: TextStyle(fontFamily: AppTypography.body, fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                ),
                if (list.isNotEmpty)
                  Text("${list.length} ${list.length == 1 ? "podio" : "podios"}",
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
              ],
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "Todavía no tienes podios. Cuando quedes entre los 3 primeros de una categoría, tu medalla aparece aquí.",
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted),
                ),
              )
            else ...[
              // Medallero: cuántos títulos de cada tipo.
              Row(
                children: [
                  Expanded(child: _Count(position: 1, count: golds, label: "Campeón")),
                  const SizedBox(width: 8),
                  Expanded(child: _Count(position: 2, count: silvers, label: "Subcampeón")),
                  const SizedBox(width: 8),
                  Expanded(child: _Count(position: 3, count: bronzes, label: "3er lugar")),
                ],
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFF1A2F39)),
                AchievementRow(achievement: shown[i]),
              ],
              if (list.length > _preview)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _all = !_all),
                    child: Text(_all ? "Ver menos" : "Ver todos (${list.length})",
                        style: const TextStyle(fontFamily: AppTypography.body, fontWeight: FontWeight.w600, color: AppColors.scorifyMint)),
                  ),
                ),
            ],
          ],
        ),
      )),
    );
  }
}

class _Count extends StatelessWidget {
  final int position;
  final int count;
  final String label;
  const _Count({required this.position, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Opacity(opacity: count == 0 ? 0.35 : 1, child: Medal(position: position, size: 34)),
          const SizedBox(height: 6),
          Text("$count",
              style: const TextStyle(fontFamily: AppTypography.body, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
          Text(label, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
        ],
      ),
    );
  }
}
