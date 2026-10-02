import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Botones de la app, estilo "premium": bajos y alargados, texto en
/// mayúsculas. Planos: sin resplandor ni brillo.
///  - primary: relleno en degradado verde → celeste, para LA acción principal
///    de la pantalla (Entrar, Inscribirme, Guardar, Confirmar…).
///  - outline: borde en degradado sobre fondo oscuro, para las secundarias
///    (Cancelar, Ver torneos, Ver grupos…).
///  - danger: rojo, para confirmar algo que no se puede deshacer.
enum AppButtonVariant { primary, outline, danger }

const appButtonGradient = LinearGradient(
  colors: [AppColors.scorifyButterfly, AppColors.scorifyMint],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final bool loading;
  final double height;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.height = 44,
    this.expand = true,
  });

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.height = 44,
    this.expand = true,
  }) : variant = AppButtonVariant.outline;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool v) {
    if (_enabled && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final radius = BorderRadius.circular(widget.height / 2);
    final disabled = widget.onPressed == null;
    final small = widget.height < 40;

    final Color fg = disabled
        ? AppColors.scorifyTextMuted
        : switch (v) {
            AppButtonVariant.primary => AppColors.scorifyOnMint,
            AppButtonVariant.outline => const Color(0xFFB9C1C9), // gris claro, no blanco
            AppButtonVariant.danger => Colors.white,
          };

    final content = widget.loading
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: small ? 15 : 17, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: small ? 12 : 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: fg,
                  ),
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(widget.trailingIcon, size: small ? 16 : 18, color: fg),
              ],
            ],
          );

    final inner = Padding(
      padding: EdgeInsets.symmetric(horizontal: small ? 14 : 22),
      child: Center(widthFactor: 1, child: content),
    );

    Widget body;
    switch (v) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        body = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: disabled ? AppColors.scorifySurface2 : (v == AppButtonVariant.danger ? AppColors.scorifyNegative : null),
            gradient: !disabled && v == AppButtonVariant.primary ? appButtonGradient : null,
          ),
          // Filete fino y claro en el borde (sin resplandor ni brillo).
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: disabled ? null : Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
            child: inner,
          ),
        );
      case AppButtonVariant.outline:
        // Borde en degradado: el degradado de fondo asoma 1.3 px alrededor
        // del relleno oscuro.
        body = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: disabled
                ? null
                : LinearGradient(
                    // Celeste arriba → verde abajo, apagado.
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scorifyMint.withValues(alpha: 0.9),
                      AppColors.scorifyButterfly.withValues(alpha: 0.9),
                    ],
                  ),
            color: disabled ? AppColors.scorifySurface2 : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2 - 1.5),
                // Más claro que las tarjetas: se lee como botón encima de ellas.
                color: const Color(0xFF1A313C),
              ),
              child: inner,
            ),
          ),
        );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1,
            duration: const Duration(milliseconds: 110),
            child: SizedBox(
              height: widget.height,
              width: widget.expand ? double.infinity : null,
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fondo de la opción elegida en los selectores tipo píldora (pestañas,
/// filtros): el mismo degradado y filete claro del botón principal.
BoxDecoration selectedPillDecoration(bool selected) => BoxDecoration(
      gradient: selected ? appButtonGradient : null,
      borderRadius: BorderRadius.circular(999),
      border: selected ? Border.all(color: Colors.white.withValues(alpha: 0.35)) : null,
    );
