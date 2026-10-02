import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Confirmación antes de una acción importante (inscribirse, pedir unirse a
/// un club...) — igual que el confirmDialog de la web. Devuelve true solo si
/// el usuario tocó el botón de confirmar.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Confirmar",
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.scorifyDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.scorifyText,
        ),
      ),
      content: Text(message, style: AppTypography.bodyMuted.copyWith(height: 1.45)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            "Cancelar",
            style: TextStyle(fontFamily: AppTypography.body, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted),
          ),
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.pop(ctx, true),
          variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
          height: 40,
          expand: false,
        ),
      ],
    ),
  );
  return ok == true;
}
