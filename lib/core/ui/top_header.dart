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
    final shell = AppShellScope.of(context);
    // Pestaña principal a la que se llegó con un enlace (p. ej. "Ver todos"
    // en el Inicio): flecha ← que vuelve a la pestaña de origen, en vez del
    // menú — igual que una pantalla empujada. Desde el menú no hay flecha.
    final returnTab = onBack == null && !showBack ? shell?.returnTab : null;
    final back = onBack ?? (returnTab != null ? () => shell!.switchTab(returnTab) : null);
    return Row(
      children: [
        if (back == null && !showBack && shell?.openMenu != null) ...[
          HeaderIconButton(icon: Icons.menu_rounded, onTap: shell!.openMenu!),
          const SizedBox(width: 12),
        ],
        if (back != null || (showBack && Navigator.canPop(context))) ...[
          BackCircleButton(onTap: back ?? () => Navigator.pop(context)),
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
        if (onBack == null && !showBack && shell?.openMenu != null) ...[
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

/// Página cuyo encabezado (título, pestañas, filtros) sube junto con el
/// contenido al hacer scroll, en vez de quedarse fijo y que la lista pase
/// por debajo con un corte en el aire. `body` es la lista de la página: debe
/// ser un scroll vertical SIN controlador propio (usa el del NestedScrollView);
/// para "cargar más al final" escuchar ScrollNotification, no un controller.
class ScrollingHeaderPage extends StatelessWidget {
  final List<Widget> header;
  final Widget body;
  final CrossAxisAlignment crossAxisAlignment;
  const ScrollingHeaderPage({
    super.key,
    required this.header,
    required this.body,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: crossAxisAlignment, children: header),
        ),
      ],
      // Las listas de adentro solo heredan el scroll del NestedScrollView en
      // Android/iOS por defecto; así también en web/escritorio (Chrome).
      body: Builder(
        builder: (context) => PrimaryScrollController(
          controller: PrimaryScrollController.of(context),
          automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
          child: body,
        ),
      ),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 20, color: AppColors.scorifyText.withValues(alpha: enabled ? 0.9 : 0.25)),
        ),
      ),
    );
  }
}
