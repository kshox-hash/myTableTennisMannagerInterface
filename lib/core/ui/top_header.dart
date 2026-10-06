import 'package:flutter/material.dart';
import 'package:myttmi/features/notifications/presentation/notifications_screen.dart';
import 'package:myttmi/core/ui/side_panel_route.dart';
import 'package:myttmi/features/notifications/notification_popups.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/constants/app_typography.dart';

/// Encabezado estándar para pantallas empujadas (detalle de torneo, partidos,
/// inscritos, perfil, etc.) — reemplaza el <code>AppBar</code> Material por
/// defecto que usan hoy 11 de las 16 pantallas de la app.
class TopHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  /// Volver propio (p. ej. a la pestaña de la que vino); se muestra siempre.
  final VoidCallback? onBack;

  const TopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack == null && !showBack && AppShellScope.of(context)?.openMenu != null) ...[
          HeaderIconButton(icon: Icons.menu_rounded, onTap: AppShellScope.of(context)!.openMenu!),
          const SizedBox(width: 12),
        ],
        if (onBack != null || (showBack && Navigator.canPop(context))) ...[
          BackCircleButton(onTap: onBack ?? () => Navigator.pop(context)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.h1),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMuted.copyWith(fontSize: 11.5),
                ),
              ],
            ],
          ),
        ),
        if (actions != null) ...[
          const SizedBox(width: 10),
          ...actions!,
        ],
        // Secciones principales: la campana, igual que en el Inicio.
        if (onBack == null && !showBack && AppShellScope.of(context)?.openMenu != null) ...[
          const SizedBox(width: 10),
          ValueListenableBuilder<int>(
            valueListenable: NotificationPopups.unread,
            builder: (context, unread, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Navigator.push(context, SidePanelRoute(child: const NotificationsScreen())),
                ),
                if (unread > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.scorifyBadge, borderRadius: BorderRadius.circular(99)),
                      child: Text(unread > 9 ? "9+" : "$unread",
                          style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HeaderIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scorifyInput,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColors.scorifyText, size: 21)),
      ),
    );
  }
}

/// Botón de volver: círculo con borde fino y flecha ‹, sin relleno.
class BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const BackCircleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.scorifyText.withValues(alpha: 0.75), width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.chevron_left_rounded, color: AppColors.scorifyText, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Botón para pasar de página dentro de una tarjeta (‹ ›): cuadradito
/// oscuro con borde; distinto al de volver.
class PagerButton extends StatelessWidget {
  final bool next;
  final VoidCallback? onTap;
  const PagerButton({super.key, required this.next, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 20, color: AppColors.scorifyText.withValues(alpha: enabled ? 0.9 : 0.25)),
        ),
      ),
    );
  }
}
