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
    final u = (url ?? "").trim();
    return ClipOval(
      child: u.isEmpty
          ? fallback
          : Image.network(
              u,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
            ),
    );
  }
}
