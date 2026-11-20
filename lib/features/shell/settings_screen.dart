import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";

/// Una opción de Ajustes: ícono, título, detalle opcional y acción.
class SettingsOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool external;
  /// Si no es null, la fila lleva un interruptor con este valor.
  final bool? switchValue;
  const SettingsOption({
    this.switchValue,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.danger = false,
    this.external = false,
  });
}

/// Ajustes como pantalla (antes era una hoja que subía desde abajo): las
/// opciones agrupadas en tarjetas por tema, con el mismo estilo de la app.
class SettingsScreen extends StatelessWidget {
  final List<(String, List<SettingsOption>)> sections;
  final String? versionLabel;
  const SettingsScreen({super.key, required this.sections, this.versionLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const TopHeader(title: "Ajustes"),
              const SizedBox(height: 18),
              for (final (title, options) in sections) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.scorifySection,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.scorifyCardFill,
                    border: Border.all(color: AppColors.scorifyHairline),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < options.length; i++) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, indent: 56, color: AppColors.scorifySelected),
                        _OptionRow(option: options[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if ((versionLabel ?? "").isNotEmpty)
                Text(
                  "MyTTM $versionLabel",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, color: AppColors.scorifyTextFaint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final SettingsOption option;
  const _OptionRow({required this.option});

  @override
  Widget build(BuildContext context) {
    final color = option.danger ? AppColors.scorifyNegative : AppColors.scorifyInk;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                color: (option.danger ? AppColors.scorifyNegative : AppColors.scorifyMint).withValues(alpha: 0.14),
                child: Icon(option.icon, size: 18, color: option.danger ? AppColors.scorifyNegative : AppColors.scorifyMint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(option.subtitle!,
                          style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, color: AppColors.scorifyTextMuted)),
                    ],
                  ],
                ),
              ),
              if (option.switchValue != null)
                Switch(
                  value: option.switchValue!,
                  onChanged: (_) => option.onTap(),
                  activeThumbColor: AppColors.scorifyOnMint,
                  activeTrackColor: AppColors.scorifyMint,
                )
              else
                Icon(option.external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                    size: option.external ? 18 : 22, color: AppColors.scorifyTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
