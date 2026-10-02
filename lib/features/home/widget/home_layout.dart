import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/identicon.dart";

// Piezas del Inicio: cabecera con avatar, barra de datos, racha, botones,
// KPIs, próximo partido vacío y accesos. Estilo sólido del resto de la app
// (sin bordes, degradados ni brillos) — lo que cambió es la distribución.

// Nombre del país → código ISO (los que usa la app al registrarse).
const _isoByCountry = {
  "chile": "CL", "argentina": "AR", "perú": "PE", "peru": "PE", "bolivia": "BO", "uruguay": "UY",
  "paraguay": "PY", "brasil": "BR", "colombia": "CO", "ecuador": "EC", "venezuela": "VE",
  "méxico": "MX", "mexico": "MX", "españa": "ES", "estados unidos": "US", "cuba": "CU",
  "costa rica": "CR", "panamá": "PA", "panama": "PA", "china": "CN", "japón": "JP", "japon": "JP",
  "corea del sur": "KR", "alemania": "DE", "francia": "FR", "italia": "IT", "portugal": "PT",
};

/// Bandera como emoji a partir del nombre del país (liviano, sin imágenes).
class CountryFlag extends StatelessWidget {
  final String country;
  final double size;
  const CountryFlag({super.key, required this.country, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final iso = _isoByCountry[country.trim().toLowerCase()];
    if (iso == null) return Icon(Icons.public_rounded, size: size, color: AppColors.scorifyMint);
    final emoji = String.fromCharCodes(iso.codeUnits.map((c) => 0x1F1E6 + c - 65));
    return Text(emoji, style: TextStyle(fontSize: size * 0.9, height: 1));
  }
}

TextStyle _label([Color c = AppColors.scorifyTextMuted]) =>
    TextStyle(fontFamily: AppTypography.body, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: c);

/// Tarjeta sólida, la base de todo el Inicio.
class HomePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const HomePanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scorifyCardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Cabecera: avatar con la bandera, nombre, país y datos del jugador (club,
/// edad, género, desde cuándo está en MyTTM). Tocándola se abre el perfil.
class HomeHero extends StatelessWidget {
  final String? userId;
  final String name;
  final String? country;
  final String? club;
  final int? age;
  final String? gender;
  final DateTime? memberSince;
  final String? avatarUrl;
  final VoidCallback? onTap;
  const HomeHero({
    super.key,
    required this.userId,
    required this.name,
    this.country,
    this.club,
    this.age,
    this.gender,
    this.memberSince,
    this.avatarUrl,
    this.onTap,
  });

  static const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

  @override
  Widget build(BuildContext context) {
    final hasCountry = (country ?? "").isNotEmpty;
    final genderLabel = switch (gender) { "male" => "Masculino", "female" => "Femenino", "other" => "Otro", _ => null };
    final since = memberSince?.toLocal();
    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.scorifyMint),
              const SizedBox(width: 5),
              Text(text, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
            ],
          ),
        );
    return HomePanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.scorifySurface2),
                    child: UserAvatar(userId: userId, url: avatarUrl, size: 72),
                  ),
                  if (hasCountry)
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.scorifyCardFill, shape: BoxShape.circle),
                        child: CountryFlag(country: country!, size: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 21, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.scorifyText),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (hasCountry) country!,
                        if (since != null) "En MyTTM desde ${_months[since.month - 1]} ${since.year}",
                      ].join(" · "),
                      maxLines: 2,
                      style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip(Icons.shield_outlined, (club ?? "").trim().isEmpty ? "Sin club" : club!),
              if (age != null) chip(Icons.cake_outlined, "$age años"),
              if (genderLabel != null) chip(Icons.person_outline_rounded, genderLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra de 3 datos: Partidos · Inscripciones · Ranking.
/// Una sola fila con lo esencial: partidos, victorias y efectividad (antes
/// además había dos tarjetas grandes de Victorias/Efectividad que repetían
/// lo mismo, y un "Ranking –" vacío). El detalle vive en Mi rendimiento.
class HomeStatsBar extends StatelessWidget {
  final int played;
  final int won;
  final String winRate; // "83%" o "—"
  const HomeStatsBar({super.key, required this.played, required this.won, required this.winRate});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color color, String label, String value) => Expanded(
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label.toUpperCase(), style: _label().copyWith(letterSpacing: 0.6)),
                    ),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                  ],
                ),
              ),
            ],
          ),
        );
    Widget divider() => Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.scorifySurface2);
    return HomePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          item(Icons.sports_tennis_rounded, AppColors.scorifyMint, "Partidos", "$played"),
          divider(),
          item(Icons.emoji_events_rounded, AppColors.scorifyButterfly, "Victorias", "$won"),
          divider(),
          item(Icons.insights_rounded, AppColors.scorifyMint, "Efectividad", winRate),
        ],
      ),
    );
  }
}

/// Racha: "5 victorias seguidas" + los últimos 5 resultados.
class HomeStreakCard extends StatelessWidget {
  /// Últimos resultados, del más antiguo al más reciente (true = ganado).
  final List<bool> form;
  final VoidCallback onTap;
  const HomeStreakCard({super.key, required this.form, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String text;
    var winning = true;
    if (form.isEmpty) {
      text = "Juega tu primer partido";
    } else {
      winning = form.last;
      var n = 0;
      for (final r in form.reversed) {
        if (r != winning) break;
        n++;
      }
      text = winning
          ? (n == 1 ? "Ganaste el último" : "$n victorias seguidas")
          : (n == 1 ? "Perdiste el último" : "$n derrotas seguidas");
    }
    final accent = winning ? AppColors.scorifyButterfly : AppColors.scorifyNegative;
    return HomePanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          Icon(winning ? Icons.local_fire_department_rounded : Icons.trending_down_rounded, color: accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RACHA", style: _label(accent)),
                const SizedBox(height: 3),
                Text(text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
              ],
            ),
          ),
          for (final won in form)
            Container(
              width: 21,
              height: 21,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: won ? AppColors.scorifyButterfly : AppColors.scorifyNegative,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(won ? Icons.check_rounded : Icons.close_rounded, color: won ? AppColors.scorifyOnButterfly : Colors.white, size: 14),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
        ],
      ),
    );
  }
}

/// Botones "Mi perfil" (degradado) e "Historial" (borde en degradado).
class HomeActionButtons extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onHistory;
  const HomeActionButtons({super.key, required this.onProfile, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AppButton(label: "Mi perfil", icon: Icons.person_rounded, onPressed: onProfile)),
        const SizedBox(width: 12),
        Expanded(child: AppButton.outline(label: "Historial", icon: Icons.receipt_long_rounded, onPressed: onHistory)),
      ],
    );
  }
}

/// KPI grande (Victorias / Efectividad) con su ícono de color.
class HomeKpiCard extends StatelessWidget {
  final IconData icon;
  final IconData decoration; // se mantiene por compatibilidad, ya no se dibuja
  final Color accent;
  final String label;
  final String value;
  final String sub;
  const HomeKpiCard({super.key, required this.icon, required this.decoration, required this.accent, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: _label()),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 28, height: 1, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                const SizedBox(height: 6),
                Text(sub, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Próximo partido" cuando no hay ninguno: invita a buscar campeonatos.
class HomeNoMatchCard extends StatelessWidget {
  final VoidCallback onBrowse;
  final bool loading;
  const HomeNoMatchCard({super.key, required this.onBrowse, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      // Centrado (ícono arriba, textos y botón al medio), igual que la
      // tarjeta del partido, que ya es simétrica.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      // Si el Inicio le da más alto (es la última tarjeta), el contenido
      // queda centrado en ese espacio.
      child: SizedBox(
        width: double.infinity,
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.scorifyMint, size: 15),
                    const SizedBox(width: 6),
                    Text("PRÓXIMO PARTIDO", style: _label(AppColors.scorifyMint)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(loading ? "Cargando…" : "Sin partidos programados",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                const SizedBox(height: 2),
                const Text("Inscríbete a un campeonato para entrar al fixture",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted)),
                const SizedBox(height: 12),
                AppButton.outline(
                  label: "Ver torneos",
                  onPressed: onBrowse,
                  trailingIcon: Icons.chevron_right_rounded,
                  height: 36,
                  expand: false,
                ),
              ],
        ),
      ),
    );
  }
}

/// Modo día de torneo: tu posición en tu grupo, justo bajo el próximo
/// partido. Toca para ver la tabla completa y tus partidos.
class HomeGroupCard extends StatelessWidget {
  final String groupName;
  final int? position;
  final int total;
  final int won;
  final int lost;
  final int setsFor;
  final int setsAgainst;
  final VoidCallback onTap;
  const HomeGroupCard({
    super.key,
    required this.groupName,
    required this.position,
    required this.total,
    required this.won,
    required this.lost,
    required this.setsFor,
    required this.setsAgainst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leading = position == 1;
    return HomePanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: leading ? AppColors.scorifyButterfly : AppColors.scorifySurface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              position == null ? "–" : "${position}°",
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: leading ? AppColors.scorifyOnButterfly : AppColors.scorifyText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TU GRUPO · ${groupName.toUpperCase()}", style: _label(AppColors.scorifyMint)),
                const SizedBox(height: 3),
                Text(
                  position == null ? "Aún sin partidos jugados" : "${position}° de $total",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scorifyText),
                ),
                const SizedBox(height: 2),
                Text(
                  "${won}G · ${lost}P · Sets $setsFor-$setsAgainst",
                  style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.scorifyTextMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
        ],
      ),
    );
  }
}

/// "Te toca arbitrar": el organizador te asignó como árbitro (o escaneaste
/// su QR). Abre la pantalla para anotar el marcador.
class HomeRefereeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const HomeRefereeCard({super.key, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.scorifyButterfly, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sports_rounded, color: AppColors.scorifyOnButterfly),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TE TOCA ARBITRAR", style: _label(AppColors.scorifyButterfly)),
                const SizedBox(height: 3),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.scorifyText)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, color: AppColors.scorifyTextMuted)),
              ],
            ),
          ),
          AppButton(label: "Arbitrar", onPressed: onTap, height: 36, expand: false),
        ],
      ),
    );
  }
}
