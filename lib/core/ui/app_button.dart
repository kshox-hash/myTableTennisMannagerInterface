import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Botones de la app, estilo "premium": bajos y alargados, texto en
/// mayúsculas con letras espaciadas.
///  - primary: relleno en degradado verde → celeste, para LA acción principal
///    de la pantalla (Entrar, Inscribirme, Guardar, Confirmar…).
///  - outline: borde en degradado sobre fondo oscuro, para las secundarias
///    (Cancelar, Ver torneos, Ver grupos…).
///  - danger: rojo, para confirmar algo que no se puede deshacer.
enum AppButtonVariant { primary, outline, danger }

const appButtonGradient = LinearGradient(
  colors: [AppColors.scorifyButterfly, AppColors.scorifyMint],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
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
            AppButtonVariant.outline => AppColors.scorifyText,
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
                    fontSize: small ? 11.5 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: small ? 0.8 : 1.1,
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
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: (v == AppButtonVariant.danger ? AppColors.scorifyNegative : AppColors.scorifyMint).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          // Brillo suave arriba: da el volumen "de cristal" del botón.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: disabled
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.0)],
                      stops: const [0, 0.55],
                    ),
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
                    colors: [
                      AppColors.scorifyButterfly.withValues(alpha: 0.85),
                      AppColors.scorifyMint.withValues(alpha: 0.85),
                    ],
                  ),
            color: disabled ? AppColors.scorifySurface2 : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2 - 1.3),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF14262E), AppColors.scorifyBg.withValues(alpha: 0.96)],
                ),
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
