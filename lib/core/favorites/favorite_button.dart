import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/favorites/favorite_matches.dart";
import "package:myttmi/core/ui/app_toast.dart";

/// Corazón para guardar un partido y seguirlo en vivo desde el Inicio.
class FavoriteButton extends StatelessWidget {
  final String matchType;
  final String matchId;
  final double size;
  /// Con fondo circular (en la barra de un detalle) o solo el ícono (en tarjetas).
  final bool filledBackground;

  const FavoriteButton({
    super.key,
    required this.matchType,
    required this.matchId,
    this.size = 22,
    this.filledBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<FavoriteMatch>>(
      valueListenable: FavoriteMatches.items,
      builder: (context, list, _) {
        final on = list.contains(FavoriteMatch(matchType, matchId));
        final icon = Icon(
          on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: on ? AppColors.scorifyNegative : AppColors.scorifyTextMuted,
          size: size,
        );
        Future<void> tap() async {
          final ok = await FavoriteMatches.toggle(matchType, matchId);
          if (!context.mounted) return;
          if (!ok) {
            showToast(context, "Puedes guardar hasta ${FavoriteMatches.max} partidos.", error: true);
          } else if (!on) {
            showToast(context, "Partido guardado. Síguelo en vivo desde el ♥ del Inicio.");
          }
        }

        if (filledBackground) {
          return Material(
            color: AppColors.scorifyInput,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: tap,
              customBorder: const CircleBorder(),
              child: SizedBox(width: 42, height: 42, child: Center(child: icon)),
            ),
          );
        }
        return InkResponse(
          onTap: tap,
          radius: size,
          child: Padding(padding: const EdgeInsets.all(4), child: icon),
        );
      },
    );
  }
}
