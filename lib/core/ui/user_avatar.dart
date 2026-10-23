import "package:myttmi/core/ui/avatar_cache.dart";
import "package:myttmi/core/helpers/image_url.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/ui/identicon.dart";

/// Avatar del jugador: su foto (subida en la web o la app) si tiene, y si no
/// —o si la foto no carga— el avatar generado a partir de su id.
class UserAvatar extends StatelessWidget {
  final String? userId;
  final String? url;
  final double size;
  const UserAvatar({super.key, required this.userId, this.url, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final fallback = userId == null || userId!.isEmpty
        ? Container(width: size, height: size, color: AppColors.scorifySurface2)
        : Identicon(seed: userId!, size: size);
    // Si esta pantalla no trae la foto, se usa la que ya se vio en otra
    // (AvatarCache); si la trae, queda anotada para las demás.
    AvatarCache.remember(userId, url);
    final u = safeImageUrl((url ?? "").trim().isNotEmpty ? url : AvatarCache.urlFor(userId));
    // Decodificada chica (no la foto completa: en listas largas era lo que
    // trababa el scroll) y en dos tamaños fijos, para que la misma foto se
    // decodifique UNA vez y la reutilicen todos los avatares de la app
    // (el caché de imágenes de Flutter la guarda por dirección + tamaño).
    final px = size * MediaQuery.devicePixelRatioOf(context) <= 128 ? 128 : 256;
    return ClipOval(
      child: u == null
          ? fallback
          : Image.network(
              u,
              width: size,
              height: size,
              cacheWidth: px,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
            ),
    );
  }
}
