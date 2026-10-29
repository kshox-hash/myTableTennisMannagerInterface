import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/features/player/models/live_summary_model.dart";

/// "En vivo" del Inicio: cómo va el campeonato que estás jugando (tu
/// categoría), para todos y no solo para ti. Una fila por ronda de la llave
/// y por grupo, la del último resultado arriba: quiénes pasan y quiénes
/// quedan fuera; en un grupo en juego, quiénes van pasando (cambia con cada
/// resultado); en una ronda en juego, quiénes faltan por jugar. Abajo de
/// cada fila, el último resultado. Se actualiza solo (ver HomeScreen). En el
/// Inicio van las últimas filas; "Ver todo" abre el resto. Si juegas varias
/// categorías, las flechas del título cambian.
class HomeLiveCard extends StatefulWidget {
  final List<LiveSummary> summaries;
  const HomeLiveCard({super.key, required this.summaries});

  @override
  State<HomeLiveCard> createState() => _HomeLiveCardState();
}

class _HomeLiveCardState extends State<HomeLiveCard> {
  int _i = 0;

  // Filas que caben en el Inicio; el resto, en "Ver todo".
  static const _maxBlocks = 3;

  @override
  Widget build(BuildContext context) {
    final all = widget.summaries;
    final s = all[_i.clamp(0, all.length - 1)];
    final shown = s.blocks.take(_maxBlocks).toList();

    return SectionCard(
      title: "En vivo · ${s.tournamentName}",
      icon: Icons.sensors_rounded,
      titleColor: AppColors.scorifyNegative,
      trailing: all.length < 2
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Arrow(icon: Icons.chevron_left_rounded, onTap: _i == 0 ? null : () => setState(() => _i--)),
                Text("${_i + 1}/${all.length}", style: AppTypography.bodyMuted.copyWith(fontSize: 11.5)),
                _Arrow(icon: Icons.chevron_right_rounded, onTap: _i == all.length - 1 ? null : () => setState(() => _i++)),
              ],
            ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              PanelChip(
                label: s.inBracket ? "Llave" : "Fase de grupos",
                color: s.inBracket ? AppColors.scorifyButterfly : AppColors.scorifyMint,
                fontSize: 11,
              ),
            ],
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text("Todavía no se juega ningún partido.", style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
            ),
          for (var k = 0; k < shown.length; k++) ...[
            if (k > 0) const Divider(height: 1, color: Panel.fieldBorder),
            _BlockRow(block: shown[k], compact: true),
          ],
          if (s.blocks.length > _maxBlocks)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showAll(context, s),
                child: const Text("Ver todo ›", style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.scorifyMint)),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAll(BuildContext context, LiveSummary s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Panel.sheetColor,
      shape: Panel.sheetShape,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelTitleBar(title: "${s.categoryLabel} · ${s.tournamentName}", icon: Icons.sensors_rounded, iconColor: AppColors.scorifyNegative),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: s.blocks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Panel.fieldBorder),
                  itemBuilder: (_, k) => _BlockRow(block: s.blocks[k], compact: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Arrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: onTap == null ? AppColors.scorifyTextFaint : AppColors.scorifyText),
        ),
      );
}

/// Una ronda o un grupo: nombre y estado arriba; abajo "Pasan", "Eliminados"
/// / "Fuera", "Van pasando" o "Juegan", y el último resultado. En [compact]
/// (Inicio) cada lista ocupa como mucho dos renglones.
class _BlockRow extends StatelessWidget {
  final LiveBlock block;
  final bool compact;
  const _BlockRow({required this.block, required this.compact});

  @override
  Widget build(BuildContext context) {
    final b = block;
    final status = b.finished
        ? "Terminado"
        : b.played == 0 && b.isRound
            ? "Por jugarse"
            : "${b.played} de ${b.total} jugados";
    final statusColor = b.finished ? AppColors.scorifyTextMuted : AppColors.scorifyMint;

    // Partidos que faltan de la ronda: "Juan P. vs Ana R.".
    final pairs = <String>[
      for (var k = 0; k + 1 < b.playing.length; k += 2) "${_nm(b.playing[k])} vs ${_nm(b.playing[k + 1])}",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(b.label, style: AppTypography.bodyText.copyWith(fontSize: 14, fontWeight: FontWeight.w700))),
              Text(status, style: TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
          if (b.passed.isNotEmpty) _Line(label: "Pasan", color: AppColors.scorifyButterfly, people: b.passed, compact: compact),
          if (b.out.isNotEmpty) _Line(label: b.isRound ? "Eliminados" : "Fuera", color: AppColors.scorifyNegative, people: b.out, compact: compact),
          if (pairs.isNotEmpty) _TextLine(label: "Juegan", color: AppColors.scorifyMint, text: pairs.join("  ·  "), compact: compact),
          if (b.passing.isNotEmpty) _Line(label: "Van pasando", color: AppColors.scorifyMint, people: b.passing, compact: compact),
          if (b.lastResult != null)
            _TextLine(
              label: "Último",
              color: AppColors.scorifyTextMuted,
              text: "${_nm(b.lastResult!.winner)} ${b.lastResult!.setsWinner}-${b.lastResult!.setsLoser} ${_nm(b.lastResult!.loser)}",
              compact: compact,
            ),
        ],
      ),
    );
  }
}

String _nm(LivePerson p) => p.isMe ? "Tú" : p.short;

/// "PASAN  Juan P. (1º) · Tú (2º)": "Tú" en menta y negrita.
class _Line extends StatelessWidget {
  final String label;
  final Color color;
  final List<LivePerson> people;
  final bool compact;
  const _Line({required this.label, required this.color, required this.people, required this.compact});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var k = 0; k < people.length; k++) {
      final p = people[k];
      if (k > 0) spans.add(const TextSpan(text: "  ·  ", style: TextStyle(color: AppColors.scorifyTextFaint)));
      spans.add(TextSpan(
        text: _nm(p) + (p.position != null ? " (${p.position}º)" : ""),
        style: p.isMe ? const TextStyle(color: AppColors.scorifyMint, fontWeight: FontWeight.w700) : null,
      ));
    }
    return _Labeled(label: label, color: color, child: Text.rich(TextSpan(children: spans), maxLines: compact ? 2 : null, overflow: compact ? TextOverflow.ellipsis : null, style: _names));
  }
}

class _TextLine extends StatelessWidget {
  final String label;
  final Color color;
  final String text;
  final bool compact;
  const _TextLine({required this.label, required this.color, required this.text, required this.compact});

  @override
  Widget build(BuildContext context) => _Labeled(
        label: label,
        color: color,
        child: Text(text, maxLines: compact ? 2 : null, overflow: compact ? TextOverflow.ellipsis : null, style: _names),
      );
}

const _names = TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.scorifyText);

/// Etiqueta de color a la izquierda (ancho fijo, así las listas quedan
/// alineadas) y el contenido al lado.
class _Labeled extends StatelessWidget {
  final String label;
  final Color color;
  final Widget child;
  const _Labeled({required this.label, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: color),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
}
