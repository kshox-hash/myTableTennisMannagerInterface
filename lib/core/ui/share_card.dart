import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:share_plus/share_plus.dart";

/// Imagen para compartir un podio o una victoria (historias de Instagram,
/// WhatsApp): se dibuja fuera de la pantalla, se convierte a PNG y se abre
/// el menú de compartir del teléfono. Lleva el logo de MyTTM.
class ShareImage {
  ShareImage._();

  static Future<void> share(BuildContext context, Widget card, {String text = ""}) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: 0,
        child: RepaintBoundary(key: key, child: Material(color: Colors.transparent, child: card)),
      ),
    );
    overlay.insert(entry);
    try {
      // Que alcance a dibujarse (y a cargar el logo).
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 250));
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      entry.remove();
      if (data == null) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(data.buffer.asUint8List(), mimeType: "image/png", name: "myttm.png")],
        text: text,
      ));
    } catch (_) {
      if (entry.mounted) entry.remove();
    }
  }
}

/// Tarjeta vertical (formato historia) con el logro.
class ShareCard extends StatelessWidget {
  final String kicker; // "¡CAMPEÓN!" / "¡VICTORIA!"
  final Color accent;
  final IconData icon;
  final String headline; // "Todo Competidor" / "3 - 1"
  final String? subline; // "vs. Pedro González"
  final String tournament;
  final String? date;
  final String playerName;

  const ShareCard({
    super.key,
    required this.kicker,
    required this.accent,
    required this.icon,
    required this.headline,
    this.subline,
    required this.tournament,
    this.date,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle t(double s, {FontWeight w = FontWeight.w600, Color c = AppColors.scorifyText, double? ls}) =>
        TextStyle(fontFamily: AppTypography.body, fontSize: s, fontWeight: w, color: c, letterSpacing: ls, decoration: TextDecoration.none);
    return Container(
      width: 360,
      height: 640,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4652), Color(0xFF060E12), Color(0xFF060E12)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(markSize: 34, wordmarkSize: 22),
          const Spacer(),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.15)),
            child: Icon(icon, size: 48, color: accent),
          ),
          const SizedBox(height: 22),
          Text(kicker, style: t(34, w: FontWeight.w700, c: accent)),
          const SizedBox(height: 6),
          Text(headline, style: t(26)),
          if (subline != null) ...[
            const SizedBox(height: 4),
            Text(subline!, style: t(16, w: FontWeight.w400, c: AppColors.scorifyTextMuted)),
          ],
          const SizedBox(height: 22),
          Container(height: 3, width: 64, decoration: const BoxDecoration(gradient: appButtonGradient)),
          const SizedBox(height: 18),
          Text(tournament, style: t(16)),
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(date!, style: t(14, w: FontWeight.w400, c: AppColors.scorifyTextMuted)),
          ],
          const Spacer(),
          Text(playerName, style: t(15)),
          const SizedBox(height: 2),
          Text("Torneos de tenis de mesa · myttm.cl", style: t(12, w: FontWeight.w400, c: AppColors.scorifyTextMuted, ls: 0.3)),
        ],
      ),
    );
  }
}
