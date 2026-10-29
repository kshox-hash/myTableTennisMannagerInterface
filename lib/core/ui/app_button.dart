import "package:myttmi/core/ui/ui_sound.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Botones de la app, estilo "premium": bajos y alargados, texto en
/// mayúsculas. Planos: sin resplandor ni brillo.
///  - primary: relleno en degradado azul → cyan, para LA acción principal
///    de la pantalla (Entrar, Inscribirme, Guardar, Confirmar…).
///  - outline: borde en degradado sobre fondo oscuro, para las secundarias
///    (Cancelar, Ver torneos, Ver grupos…).
///  - danger: rojo, para confirmar algo que no se puede deshacer.
enum AppButtonVariant { primary, outline, danger }

// Sobrio: azul de marca → azul profundo (antes terminaba en cyan
// brillante y se veía chillón). Vertical, como un botón con algo de volumen.
// Por ahora color liso (prioridad a la fluidez; el diseño se retoma después).
const appButtonGradient = LinearGradient(colors: [AppColors.scorifyMint, AppColors.scorifyMint]);

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
    this.height = 40,
    this.expand = true,
  });

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.height = 40,
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
    final radius = BorderRadius.circular(Panel.buttonRadius); // esquinas casi rectas (estilo panel)
    final disabled = widget.onPressed == null;
    final small = widget.height < 40;

    // Texto claro en todos: el fondo es un degradado oscuro (estilo panel).
    final Color fg = disabled ? AppColors.scorifyTextFaint : AppColors.scorifyText;

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
                    fontSize: small ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
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

    // Estilo panel: degradado vertical de casi negro arriba a un color
    // abajo (verde azulado en el secundario, celeste de marca en el
    // principal, rojo en el de peligro) con filete fino del mismo tono.
    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: disabled ? Panel.field : null,
        gradient: disabled
            ? null
            : switch (v) {
                AppButtonVariant.primary => Panel.primaryButtonGradient,
                AppButtonVariant.outline => Panel.buttonGradient,
                AppButtonVariant.danger => Panel.dangerButtonGradient,
              },
        border: Border.all(
          color: disabled
              ? Panel.fieldBorder
              : switch (v) {
                  AppButtonVariant.primary => Panel.primaryButtonBorder,
                  AppButtonVariant.outline => Panel.buttonBorder,
                  AppButtonVariant.danger => Panel.dangerButtonBorder,
                },
        ),
      ),
      child: inner,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled
            ? () {
                UiSound.tap();
                widget.onPressed!();
              }
            : null,
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
/// filtros): el mismo degradado y filete del botón principal.
BoxDecoration selectedPillDecoration(bool selected) => BoxDecoration(
      gradient: selected ? Panel.primaryButtonGradient : null,
      borderRadius: BorderRadius.circular(Panel.buttonRadius),
      border: selected ? Border.all(color: Panel.primaryButtonBorder) : null,
    );
