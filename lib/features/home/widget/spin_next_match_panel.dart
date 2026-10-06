import 'package:myttmi/core/ui/section_card.dart';
import 'package:myttmi/core/ui/app_button.dart';
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/user_avatar.dart';

/// Tarjeta "Próximo partido" estilo marcador de fútbol (competición arriba,
/// un jugador a cada lado y el dato clave grande al centro).
///
/// Al centro va lo más útil según el estado real del partido — no hay hora
/// programada en el modelo, así que no se inventa una:
///  - con mesa asignada: "MESA n" grande + "Listo para jugar";
///  - sin mesa: "VS" grande + el estado de la cola (queueLabel).
/// Toda la tarjeta lleva al perfil del rival.
class SpinNextMatchPanel extends StatelessWidget {
  // Sin partido: se muestra el estado vacío.
  final bool hasMatch;
  final String tournamentName;
  final String stageLabel; // "Todo Competidor · Grupo GR-2"
  final String? myId;
  final String myName;
  final String? myAvatarUrl;
  final String? opponentId;
  final String opponentName;
  final String? opponentAvatarUrl;
  final int? tableNumber;
  final String statusLabel; // cola / estado cuando no hay mesa
  /// Hora planificada ("Hoy 18:30"); se muestra si todavía no hay mesa.
  final DateTime? scheduledAt;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onTap;
  /// Abre el perfil del rival (con su historial). Null si aún no hay rival.
  final VoidCallback? onOpponentProfile;

  const SpinNextMatchPanel({
    super.key,
    required this.hasMatch,
    this.tournamentName = "",
    this.stageLabel = "",
    this.myId,
    this.myName = "Tú",
    this.myAvatarUrl,
    this.opponentId,
    this.opponentName = "Rival por definir",
    this.opponentAvatarUrl,
    this.tableNumber,
    this.statusLabel = "",
    this.scheduledAt,
    this.emptyTitle = "Sin partidos programados",
    this.emptySubtitle = "",
    required this.onTap,
    this.onOpponentProfile,
  });

  static String _hhmm(DateTime d) => "${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}";

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return "HOY";
    if (diff == 1) return "MAÑANA";
    return "${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}";
  }

  // "Cristóbal Gutiérrez Silva" -> "Cristóbal Gutiérrez" (nombre + primer apellido).
  static String _short(String full) {
    final parts = full.trim().split(RegExp(r"\s+"));
    return parts.length <= 2 ? full.trim() : "${parts[0]} ${parts[1]}";
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "Próximo partido",
      icon: Icons.sports_tennis_rounded,
      titleColor: AppColors.scorifyMint,
      gradient: AppColors.featuredGradient,
      fill: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: hasMatch ? _match() : _empty(),
    );
  }

  Widget _empty() {
    return Column(
      children: [
        const Icon(Icons.sports_tennis_rounded, color: AppColors.scorifyMint, size: 30),
        const SizedBox(height: 10),
        Text(
          emptyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.scorifyText, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (emptySubtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _match() {
    final ready = tableNumber != null;
    // Centrado en el alto que le dé el Inicio (la tarjeta llega hasta abajo).
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Competición (como "Premier League / Week 10").
        Text(
          tournamentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.scorifyText, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (stageLabel.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            stageLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Side(id: myId, url: myAvatarUrl, name: _short(myName), caption: "Tú")),
            SizedBox(
              width: 122,
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  if (ready) ...[
                    const Text(
                      "MESA",
                      style: TextStyle(color: AppColors.scorifyTextMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    ),
                    Text(
                      "$tableNumber",
                      style: const TextStyle(color: AppColors.scorifyText, fontSize: 38, height: 1.05, fontWeight: FontWeight.w700),
                    ),
                  ] else if (scheduledAt != null) ...[
                    Text(
                      _dayLabel(scheduledAt!),
                      style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                    Text(
                      _hhmm(scheduledAt!),
                      style: const TextStyle(color: AppColors.scorifyText, fontSize: 32, height: 1.1, fontWeight: FontWeight.w700),
                    ),
                  ] else
                    const Text(
                      "VS",
                      style: TextStyle(color: AppColors.scorifyText, fontSize: 34, height: 1.2, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  _Chip(
                    text: ready ? "Listo para jugar" : (statusLabel.isEmpty ? "Por jugar" : "En espera"),
                    color: ready ? AppColors.scorifyButterfly : AppColors.scorifyPending,
                  ),
                ],
              ),
            ),
            Expanded(child: _Side(id: opponentId, url: opponentAvatarUrl, name: _short(opponentName), caption: "Rival")),
          ],
        ),
        // Sin mesa: el detalle de la cola, completo (cabe en dos líneas).
        if (!ready && statusLabel.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            statusLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
        if (onOpponentProfile != null) ...[
          const SizedBox(height: 12),
          AppButton.outline(
            label: "Ver perfil del rival",
            icon: Icons.person_search_rounded,
            onPressed: onOpponentProfile,
            height: 36,
            expand: false,
          ),
        ],
      ],
    );
  }
}

class _Side extends StatelessWidget {
  final String? id;
  final String? url;
  final String name;
  final String caption;
  const _Side({required this.id, this.url, required this.name, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        id != null && id!.isNotEmpty
            // Foto real si la tiene; si no, su identicon.
            ? UserAvatar(userId: id, url: url, size: 52)
            : Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(2)),
                child: const Icon(Icons.person_rounded, color: AppColors.scorifyTextMuted),
              ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.scorifyText, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
        ),
        const SizedBox(height: 2),
        Text(caption, style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, maxLines: 1, softWrap: false, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
