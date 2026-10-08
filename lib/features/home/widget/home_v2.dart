import "dart:async";
import "dart:math" as math;
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/core/ui/stat_gauge.dart";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/card_border.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/features/home/widget/home_layout.dart";

/// Inicio (diseño nuevo): perfil en una fila, próximo partido destacado,
/// rendimiento con anillo, racha actual y últimos resultados.

const _mint = AppColors.scorifyMint;

// Tarjetas del Inicio: color sólido oscuro al 85% (el fondo se intuye).
// El color va en los detalles; la principal lleva una línea en degradado.
const _glass = LinearGradient(colors: [Color(0xD90B1A20), Color(0xD90B1A20)]);
const _glassFeatured = LinearGradient(colors: [Color(0xE00B1A20), Color(0xE00B1A20)]);
const _lime = AppColors.scorifyButterfly;

TextStyle _t(double size, {FontWeight w = FontWeight.w400, Color c = AppColors.scorifyText, double? ls, double? h}) =>
    TextStyle(fontFamily: AppTypography.body, fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

/// Tarjeta del Inicio: fondo en degradado tenue y borde sutil.
class HomeCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  const HomeCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gradient, this.onTap});

  @override
  State<HomeCard> createState() => _HomeCardState();
}

// Vidrio liviano (sin desenfoque, que sobre un video es caro): fondo
// semitransparente, filete claro arriba y sombra suave para que flote.
class _HomeCardState extends State<HomeCard> {
  bool _down = false;

  void _press(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    const radius = 2.0; // esquinas casi rectas (estilo menú FIFA)
    final r = BorderRadius.circular(radius);
    return AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: CardBorder(
          radius: radius,
          child: ClipRRect(
            borderRadius: r,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(gradient: widget.gradient ?? _glass),
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: (_) => _press(true),
                  onTapUp: (_) => _press(false),
                  onTapCancel: () => _press(false),
                  child: Stack(
                    children: [
                      // Tarjeta principal: línea fina en degradado arriba.
                      if (widget.gradient == _glassFeatured)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 3,
                          child: DecoratedBox(decoration: BoxDecoration(gradient: appButtonGradient)),
                        ),
                      Padding(padding: widget.padding, child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección dentro de la tarjeta: ícono + texto en mayúsculas de
/// color, y una acción a la derecha ("Ver estadísticas ›").
class HomeCardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? action;
  final VoidCallback? onAction;
  const HomeCardTitle({super.key, required this.icon, required this.title, this.color = _mint, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(title.toUpperCase(), style: _t(13, w: FontWeight.w600, c: color, ls: 1.1))),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text("$action ›", style: _t(12, w: FontWeight.w500, c: _mint)),
            ),
          ),
      ],
    );
  }
}

/// Fila del perfil: foto con bandera, nombre, país · club y, a la derecha,
/// edad y género. Tocándola se abre el perfil.
class HomeProfileRow extends StatelessWidget {
  final String? userId;
  final String name;
  final String? country;
  final String? club;
  final int? age;
  final String? gender;
  final String? avatarUrl;
  final VoidCallback onTap;
  /// Saludo y frase del momento (si vienen, reemplazan nombre y datos).
  final String? greeting;
  final String? context;
  const HomeProfileRow({
    this.greeting,
    this.context,
    super.key,
    required this.userId,
    required this.name,
    this.country,
    this.club,
    this.age,
    this.gender,
    this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final genderLabel = switch (gender) { "male" => "Masculino", "female" => "Femenino", "other" => "Otro", _ => null };
    final sub = [
      if ((country ?? "").isNotEmpty) country!,
      if ((club ?? "").trim().isNotEmpty) club!.trim(),
    ].join(" · ");
    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _mint),
            const SizedBox(width: 5),
            Text(text, style: _t(12.5, c: AppColors.scorifyText)),
          ],
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: appButtonGradient),
                  child: UserAvatar(userId: userId, url: avatarUrl, size: 54),
                ),
                if ((country ?? "").isNotEmpty)
                  Positioned(right: -2, bottom: -2, child: CountryFlag(country: country!, size: 16)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(greeting ?? name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(18, w: FontWeight.w600, h: 1.2)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(this.context ?? sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, c: this.context != null ? _mint : AppColors.scorifyTextMuted)),
                      ),
                      if (this.context == null) ...[
                        if (age != null) ...[meta(Icons.person_outline_rounded, "$age años"), const SizedBox(width: 12)],
                        if (genderLabel != null) meta(gender == "female" ? Icons.female_rounded : Icons.male_rounded, genderLabel),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Próximo partido: competición, los dos jugadores, fecha · mesa · lugar y
/// el botón "Ver detalle del partido".
class HomeMatchCard extends StatelessWidget {
  final String tournamentName;
  final String? myId;
  final String? myAvatarUrl;
  final String? myClub;
  final String? opponentId;
  final String opponentName;
  final String? opponentAvatarUrl;
  final String? opponentClub;
  final String when; // "Sáb. 27 Sep\n15:30" o "Por definir"
  final String table; // "Mesa 4" / "En cola"
  final String? place;
  /// Historial entre ambos ("Se han enfrentado 3 veces · 2-1").
  final String? h2h;
  /// Para el estado en vivo: hora programada y mesa asignada.
  final DateTime? startsAt;
  final int? tableNumber;
  final VoidCallback onDetail;
  final VoidCallback? onOpponent;
  const HomeMatchCard({
    super.key,
    required this.tournamentName,
    this.myId,
    this.myAvatarUrl,
    this.myClub,
    this.opponentId,
    required this.opponentName,
    this.opponentAvatarUrl,
    this.opponentClub,
    required this.when,
    required this.table,
    this.place,
    this.h2h,
    this.startsAt,
    this.tableNumber,
    required this.onDetail,
    this.onOpponent,
  });

  @override
  Widget build(BuildContext context) {
    Widget player(String? id, String? url, String name, String? club, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _mint.withValues(alpha: 0.7), width: 1.5)),
                child: UserAvatar(userId: id, url: url, size: 40),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13.5, w: FontWeight.w600)),
                    if ((club ?? "").trim().isNotEmpty)
                      Text(club!.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, c: AppColors.scorifyTextMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
    Widget info(IconData icon, String text, {int flex = 2}) => Expanded(
          flex: flex,
          child: Row(
            children: [
              Icon(icon, size: 17, color: _mint),
              const SizedBox(width: 6),
              Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(11.5, h: 1.3))),
            ],
          ),
        );
    Widget sep() => Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.white.withValues(alpha: 0.10));

    return HomeCard(
      gradient: _glassFeatured,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Decoración a la derecha: franja diagonal y una paleta tenue.
          const Positioned.fill(child: CustomPaint(painter: _DiagonalPainter())),
          Positioned(
            right: -18,
            top: 18,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(Icons.sports_tennis_rounded, size: 110, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: HomeCardTitle(icon: Icons.calendar_month_rounded, title: "Próximo partido")),
                    _LiveStatus(startsAt: startsAt, tableNumber: tableNumber),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tournamentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, c: AppColors.scorifyText.withValues(alpha: 0.85))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: player(myId, myAvatarUrl, "Tú", myClub)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("VS", style: _t(14, w: FontWeight.w600, c: AppColors.scorifyTextMuted)),
                    ),
                    Expanded(child: player(opponentId, opponentAvatarUrl, opponentName, opponentClub, onTap: onOpponent)),
                  ],
                ),
                if (h2h != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.compare_arrows_rounded, size: 16, color: _mint),
                      const SizedBox(width: 6),
                      Expanded(child: Text(h2h!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted))),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    info(Icons.event_rounded, when),
                    sep(),
                    info(Icons.table_restaurant_rounded, table),
                    if ((place ?? "").trim().isNotEmpty) ...[sep(), info(Icons.place_rounded, place!.trim(), flex: 3)],
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: "Ver detalle del partido",
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: onDetail,
                  height: 40,
                  expand: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter();
  @override
  void paint(Canvas canvas, Size size) {
    // Franja diagonal con brillo turquesa→verde (como en el diseño).
    final p = Paint()
      ..shader = LinearGradient(
        colors: [_mint.withValues(alpha: 0.0), _lime.withValues(alpha: 0.35), _mint.withValues(alpha: 0.0)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(size.width * 0.62, 0), Offset(size.width * 0.38, size.height), p);
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [_mint.withValues(alpha: 0.10), Colors.transparent],
        stops: const [0, 0.6],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * 0.62, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.38, size.height)
      ..close();
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rendimiento: anillo de efectividad, partidos/victorias/derrotas y una
/// curva con tu diferencia de sets acumulada partido a partido (sube con
/// cada victoria —más con un 3-0—, baja con cada derrota).
class HomePerformanceCard extends StatelessWidget {
  final int played;
  final int won;
  final List<int> trend; // sets ganados − perdidos por partido, del más antiguo al más reciente
  final VoidCallback onStats;
  const HomePerformanceCard({super.key, required this.played, required this.won, required this.trend, required this.onStats});

  @override
  Widget build(BuildContext context) {
    final lost = math.max(0, played - won);
    final rate = played == 0 ? 0.0 : won / played;
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: _t(26, w: FontWeight.w600, h: 1.1)),
              const SizedBox(height: 2),
              Text(label, style: _t(12, c: AppColors.scorifyTextMuted)),
            ],
          ),
        );
    Widget sep() => Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.10));
    return HomeCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                HomeCardTitle(icon: Icons.bar_chart_rounded, title: "Rendimiento", action: "Ver estadísticas", onAction: onStats),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatGauge(
                      fraction: played == 0 ? 0 : rate,
                      value: played == 0 ? "—" : "${(rate * 100).round()}%",
                      caption: "Efectividad",
                      size: 96,
                      stroke: 6,
                      open: false,
                      valueSize: 22,
                    ),
                    const SizedBox(width: 14),
                    stat("$played", "Partidos"),
                    sep(),
                    stat("$won", "Victorias"),
                    sep(),
                    stat("$lost", "Derrotas"),
                  ],
                ),
                // Espacio para la línea de tendencia, bajo los números.
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// los últimos 5 resultados (G/P).
class HomeStreakCardV2 extends StatelessWidget {
  final List<bool> form; // últimos 5, del más antiguo al más reciente
  final int streak; // racha actual (cantidad)
  final bool winning;
  final int bestPrevious; // mejor racha de victorias anterior
  final VoidCallback? onTap;
  const HomeStreakCardV2({
    super.key,
    required this.form,
    required this.streak,
    required this.winning,
    required this.bestPrevious,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = winning ? _lime : AppColors.scorifyNegative;
    String? compare;
    if (winning && streak > 0) {
      if (streak > bestPrevious && bestPrevious > 0) {
        compare = "+${streak - bestPrevious} vs. tu mejor racha anterior";
      } else if (streak == bestPrevious && bestPrevious > 0) {
        compare = "Igualas tu mejor racha";
      } else if (bestPrevious > streak) {
        compare = "Tu mejor racha: $bestPrevious";
      }
    }
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: 70,
            bottom: -18,
            child: Icon(Icons.local_fire_department_rounded, size: 96, color: Colors.white.withValues(alpha: 0.04)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeCardTitle(icon: Icons.local_fire_department_rounded, title: "Racha actual", color: color),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (form.isEmpty)
                      Expanded(child: Text("Juega tu primer partido", style: _t(16, w: FontWeight.w600)))
                    else ...[
                      Text("$streak", style: _t(44, w: FontWeight.w700, h: 1.0)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(winning ? (streak == 1 ? "victoria" : "victorias") : (streak == 1 ? "derrota" : "derrotas"),
                                style: _t(19, w: FontWeight.w600)),
                            if (compare != null)
                              Row(
                                children: [
                                  if (compare.startsWith("+")) Icon(Icons.arrow_upward_rounded, size: 13, color: _mint),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(compare, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, c: AppColors.scorifyTextMuted)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                    for (final w in form)
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: w ? appButtonGradient : null,
                          color: w ? null : AppColors.scorifyNegative,
                        ),
                        child: Text(w ? "G" : "P", style: _t(12, w: FontWeight.w700, c: w ? AppColors.scorifyOnButterfly : Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un resultado para la tarjeta "Últimos resultados".
class HomeResult {
  final bool won;
  final String score; // "3 - 1" (tus sets primero)
  final String opponent;
  final String date; // "21 Sep"
  final VoidCallback onTap;
  HomeResult({required this.won, required this.score, required this.opponent, required this.date, required this.onTap});
}

class HomeResultsCard extends StatefulWidget {
  final List<HomeResult> results;
  final VoidCallback onAll;
  const HomeResultsCard({super.key, required this.results, required this.onAll});

  @override
  State<HomeResultsCard> createState() => _HomeResultsCardState();
}

class _HomeResultsCardState extends State<HomeResultsCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    final onAll = widget.onAll;
    final pages = ((results.length + 3) ~/ 4).clamp(1, 3);
    final page = _page.clamp(0, pages - 1);
    final shown = results.skip(page * 4).take(4).toList();
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          HomeCardTitle(icon: Icons.schedule_rounded, title: "Últimos resultados", action: "Ver todos", onAction: onAll, color: AppColors.scorifyText),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: i < shown.length ? _ResultTile(r: shown[i]) : const SizedBox.shrink()),
              ],
            ],
          ),
          if (pages > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                PagerButton(next: false, onTap: page > 0 ? () => setState(() => _page = page - 1) : null),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == page ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == page ? AppColors.scorifyMint : AppColors.scorifySurface2,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                ),
                PagerButton(next: true, onTap: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final HomeResult r;
  const _ResultTile({required this.r});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: r.onTap,
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: r.won ? appButtonGradient : null,
                      color: r.won ? null : AppColors.scorifyNegative,
                    ),
                    child: Text(r.won ? "G" : "P", style: _t(10, w: FontWeight.w700, c: r.won ? AppColors.scorifyOnButterfly : Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(r.score, style: _t(15, w: FontWeight.w600)))),
                ],
              ),
              const SizedBox(height: 6),
              Text("vs. ${r.opponent}", maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(10, c: AppColors.scorifyTextMuted)),
              const SizedBox(height: 2),
              Text(r.date, style: _t(10, c: AppColors.scorifyTextMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campeonato con la inscripción abierta (para el carrusel del Inicio).
class HomeOpenItem {
  final String name;
  final String when; // "Sáb. 12 Oct"
  final String? place;
  final VoidCallback onTap;
  HomeOpenItem({required this.name, required this.when, this.place, required this.onTap});
}

/// "Inscripciones abiertas": la invitación principal a jugar.
class HomeOpenTournamentsCard extends StatelessWidget {
  final List<HomeOpenItem> items;
  final VoidCallback onAll;
  const HomeOpenTournamentsCard({super.key, required this.items, required this.onAll});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: HomeCardTitle(icon: Icons.how_to_reg_rounded, title: "Inscripciones abiertas", action: "Ver todos", onAction: onAll),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final it = items[i];
                return SizedBox(
                  width: items.length == 1 ? MediaQuery.sizeOf(context).width - 60 : 230,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(2),
                    child: InkWell(
                      onTap: it.onTap,
                      borderRadius: BorderRadius.circular(2),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(14, w: FontWeight.w600, h: 1.2)),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.event_rounded, size: 14, color: _mint),
                                const SizedBox(width: 5),
                                Text(it.when, style: _t(12)),
                              ],
                            ),
                            if ((it.place ?? "").trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.place_rounded, size: 14, color: _mint),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(it.place!.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted))),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Un evento de "Esta semana".
class HomeWeekItem {
  final String day; // "SÁB"
  final String date; // "12"
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  HomeWeekItem({required this.day, required this.date, required this.title, required this.subtitle, required this.onTap});
}

class HomeWeekCard extends StatelessWidget {
  final List<HomeWeekItem> items;
  final VoidCallback onCalendar;
  const HomeWeekCard({super.key, required this.items, required this.onCalendar});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          HomeCardTitle(icon: Icons.date_range_rounded, title: "Próximos eventos", action: "Calendario", onAction: onCalendar),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text("No tienes eventos en los próximos 14 días.", style: _t(13, c: AppColors.scorifyTextMuted)),
            ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.circular(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(color: _mint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(2)),
                      child: Column(
                        children: [
                          Text(items[i].day, style: _t(11, w: FontWeight.w600, c: _mint, ls: 0.6)),
                          Text(items[i].date, style: _t(17, w: FontWeight.w600, h: 1.1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14, w: FontWeight.w600)),
                          Text(items[i].subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un logro positivo (solo se muestra cuando lo hay): racha o último podio.
class HomeHighlightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const HomeHighlightCard({super.key, required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(15, w: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(12.5, c: AppColors.scorifyTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un paso de la guía para nuevos.
class HomeStep {
  final String title;
  final bool done;
  final VoidCallback onTap;
  HomeStep({required this.title, required this.done, required this.onTap});
}

/// "Empieza en MyTTM": guía para quien recién llega. Desaparece cuando
/// completó todos los pasos.
class HomeOnboardingCard extends StatelessWidget {
  final List<HomeStep> steps;
  const HomeOnboardingCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final done = steps.where((s) => s.done).length;
    return HomeCard(
      gradient: _glassFeatured,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: HomeCardTitle(icon: Icons.rocket_launch_rounded, title: "Empieza en MyTTM")),
              Text("$done de ${steps.length}", style: _t(12, c: AppColors.scorifyTextMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: steps.isEmpty ? 0 : done / steps.length,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _mint,
            ),
          ),
          const SizedBox(height: 6),
          for (final s in steps)
            InkWell(
              onTap: s.done ? null : s.onTap,
              borderRadius: BorderRadius.circular(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: s.done ? appButtonGradient : null,
                        border: s.done ? null : Border.all(color: AppColors.scorifyTextMuted, width: 1.5),
                      ),
                      child: s.done ? const Icon(Icons.check_rounded, size: 16, color: AppColors.scorifyOnButterfly) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.title,
                        style: _t(14,
                            w: FontWeight.w500,
                            c: s.done ? AppColors.scorifyTextMuted : AppColors.scorifyText),
                      ),
                    ),
                    if (!s.done) const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Acceso rápido del Inicio (ícono + texto).
class HomeQuick {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  HomeQuick(this.icon, this.label, this.onTap);
}

/// Fila de accesos rápidos: siempre visible, ordena el Inicio.
class HomeQuickActions extends StatelessWidget {
  final List<HomeQuick> items;
  const HomeQuickActions({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: HomeCard(
              onTap: items[i].onTap,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(items[i].icon, color: _mint, size: 24),
                  const SizedBox(height: 6),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(items[i].label, style: _t(11.5, w: FontWeight.w500))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Tu temporada": solo números que suben (jugados, campeonatos, podios).
class HomeSeasonCard extends StatelessWidget {
  final int played;
  final int tournaments;
  final int podiums;
  const HomeSeasonCard({super.key, required this.played, required this.tournaments, required this.podiums});

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, size: 20, color: _mint),
              const SizedBox(height: 4),
              Text(value, style: _t(22, w: FontWeight.w600, h: 1.1)),
              Text(label.toUpperCase(), style: _t(11, w: FontWeight.w500, c: AppColors.scorifyTextMuted, ls: 0.8)),
            ],
          ),
        );
    Widget sep() => Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.10));
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          const HomeCardTitle(icon: Icons.auto_graph_rounded, title: "Tu temporada"),
          const SizedBox(height: 12),
          Row(
            children: [
              stat(Icons.sports_tennis_rounded, "$played", "Partidos"),
              sep(),
              stat(Icons.flag_rounded, "$tournaments", "Campeonatos"),
              sep(),
              stat(Icons.emoji_events_rounded, "$podiums", "Podios"),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner deportivo del centro del Inicio. Si existe la imagen
/// (assets/images/home_banner.jpg) va de fondo; mientras tanto, un fondo
/// provisional con degradado y una paleta tenue.
class HomeBanner extends StatelessWidget {
  final String title;
  final String button;
  final VoidCallback onTap;
  final String? imageAsset;
  const HomeBanner({super.key, required this.title, required this.button, required this.onTap, this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return CardBorder(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageAsset != null)
                Image.asset(imageAsset!, fit: BoxFit.cover, alignment: Alignment.centerRight)
              else ...[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF060E12), Color(0xFF0F4652)],
                    ),
                  ),
                ),
                const Positioned.fill(child: CustomPaint(painter: _DiagonalPainter())),
                Positioned(
                  right: -10,
                  bottom: -16,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Icon(Icons.sports_tennis_rounded, size: 150, color: _mint.withValues(alpha: 0.18)),
                  ),
                ),
              ],
              // Oscurece la izquierda para que el texto se lea sobre la foto.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xE6060E12), Color(0x00060E12)],
                    stops: [0.25, 0.75],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(title, style: _t(20, w: FontWeight.w700, h: 1.2)),
                    ),
                    const SizedBox(height: 14),
                    AppButton(label: button, trailingIcon: Icons.chevron_right_rounded, onPressed: onTap, height: 38, expand: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un campeonato en el que estás inscrito.
class HomeMyTournament {
  final String name;
  final String detail; // categoría
  final String status; // "En curso" / "Sáb. 12 Oct"
  final bool live;
  final VoidCallback onTap;
  HomeMyTournament({required this.name, required this.detail, required this.status, required this.live, required this.onTap});
}

/// "Mis campeonatos": en curso o por jugar. Vacío: invita a inscribirse.
class HomeMyTournamentsCard extends StatelessWidget {
  final List<HomeMyTournament> items;
  final VoidCallback onBrowse;
  const HomeMyTournamentsCard({super.key, required this.items, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardTitle(icon: Icons.emoji_events_rounded, title: "Mis campeonatos", action: items.isEmpty ? "Explorar" : "Ver todos", onAction: onBrowse),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aún no estás inscrito en ningún campeonato. Cuando te inscribas, aparecerán aquí.", style: _t(13, c: AppColors.scorifyTextMuted)),
                ],
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              InkWell(
                onTap: items[i].onTap,
                borderRadius: BorderRadius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14, w: FontWeight.w600)),
                            Text(items[i].detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (items[i].live ? _lime : _mint).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(items[i].status, style: _t(11.5, w: FontWeight.w600, c: items[i].live ? _lime : _mint)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                    ],
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Estado del partido: "EN MESA 3" con un punto verde que late, o
/// "Faltan 2 h 15 min" (se actualiza cada 30 s). Nada si no hay hora.
class _LiveStatus extends StatefulWidget {
  final DateTime? startsAt;
  final int? tableNumber;
  const _LiveStatus({this.startsAt, this.tableNumber});

  @override
  State<_LiveStatus> createState() => _LiveStatusState();
}

class _LiveStatusState extends State<_LiveStatus> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tableNumber != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime,
                boxShadow: [BoxShadow(color: _lime.withValues(alpha: 0.6), blurRadius: 6)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text("EN MESA ${widget.tableNumber}", style: _t(12, w: FontWeight.w700, c: _lime, ls: 0.8)),
        ],
      );
    }
    final at = widget.startsAt;
    if (at == null) return const SizedBox.shrink();
    final left = at.difference(DateTime.now());
    if (left.isNegative) return Text("Por comenzar", style: _t(12, w: FontWeight.w600, c: _mint));
    final h = left.inHours, m = left.inMinutes % 60;
    final text = left.inDays >= 1
        ? "Faltan ${left.inDays} ${left.inDays == 1 ? "día" : "días"}"
        : h > 0
            ? "Faltan $h h $m min"
            : "Faltan $m min";
    return Text(text, style: _t(12, w: FontWeight.w600, c: _mint));
  }
}

/// "Mis campeonatos" en carrusel: tarjetas con insignia de iniciales,
/// nombre, categoría y un chip "en 5 días" / "EN CURSO".
class HomeMyTournamentsCarousel extends StatelessWidget {
  final List<HomeMyTournament> items;
  final VoidCallback onBrowse;
  const HomeMyTournamentsCarousel({super.key, required this.items, required this.onBrowse});

  static String _initials(String name) {
    final words = name.split(RegExp(r"\s+")).where((w) => w.length > 2 && w[0].toUpperCase() == w[0]).toList();
    final src = words.isEmpty ? name.split(RegExp(r"\s+")) : words;
    return src.take(2).map((w) => w.isEmpty ? "" : w[0].toUpperCase()).join();
  }

  static const _badgeColors = [Color(0xFF00B3D6), Color(0xFF22E3D0), Color(0xFFA6D32D), Color(0xFFFFA62B), Color(0xFF8B7CF6)];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return HomeMyTournamentsCard(items: items, onBrowse: onBrowse);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: HomeCardTitle(icon: Icons.emoji_events_rounded, title: "Mis campeonatos", action: "Ver todos", onAction: onBrowse),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final it = items[i];
              final color = _badgeColors[it.name.hashCode.abs() % _badgeColors.length];
              return SizedBox(
                width: items.length == 1 ? MediaQuery.sizeOf(context).width - 32 : 200,
                child: HomeCard(
                  onTap: it.onTap,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.55)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: Text(_initials(it.name), style: _t(15, w: FontWeight.w700, c: AppColors.scorifyOnMint)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: (it.live ? _lime : _mint).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(it.status, style: _t(11.5, w: FontWeight.w700, c: it.live ? _lime : _mint)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w600, h: 1.2)),
                      const SizedBox(height: 2),
                      Text(it.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Portada del Inicio (a la derecha de la foto): saludo, titular con
/// "desafío" en degradado, bajada y botón.
class HomeHeroText extends StatelessWidget {
  final String greeting; // "Buenas tardes, Ignacio"
  final String? contextLine; // "Tienes un partido hoy"
  final VoidCallback onGreeting;
  const HomeHeroText({super.key, required this.greeting, this.contextLine, required this.onGreeting});

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Color(0xCC000000), blurRadius: 14)];
    final parts = greeting.replaceAll(" 👋", "").split(", ");
    return GestureDetector(
      onTap: onGreeting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts.first, style: _t(14, w: FontWeight.w500, c: AppColors.scorifyText.withValues(alpha: 0.85)).copyWith(shadows: shadow)),
          if (parts.length > 1)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(parts.sublist(1).join(", "), maxLines: 1, style: _t(26, w: FontWeight.w700, h: 1.15).copyWith(shadows: shadow)),
            ),
          const SizedBox(height: 10),
          Container(width: 32, height: 3, decoration: BoxDecoration(gradient: appButtonGradient, borderRadius: BorderRadius.circular(99))),
          if (contextLine != null) ...[
            const SizedBox(height: 10),
            Text(contextLine!, textAlign: TextAlign.left, style: _t(13, w: FontWeight.w500, c: _mint, h: 1.3).copyWith(shadows: shadow)),
          ],
        ],
      ),
    );
  }
}

/// "Próximo desafío": tu próximo campeonato o el primero con inscripción.
class HomeChallengeCard extends StatelessWidget {
  final String kicker;
  final String name;
  final String? date;
  final String? place;
  final int? players;
  final String? chip; // "En inscripción" / "Inscrito"
  /// Texto bajo el nombre (estado vacío).
  final String? subtitle;
  final String button;
  final VoidCallback onTap;
  const HomeChallengeCard({
    super.key,
    this.kicker = "PRÓXIMO DESAFÍO",
    required this.name,
    this.date,
    this.place,
    this.players,
    this.chip,
    this.subtitle,
    this.button = "Ver campeonato",
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget info(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _mint),
              const SizedBox(width: 6),
              Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5))),
            ],
          ),
        );
    return HomeCard(
      gradient: _glassFeatured,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _DiagonalPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(kicker, style: _t(12.5, w: FontWeight.w600, c: _lime, ls: 1.2))),
                    if (chip != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _lime.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(chip!, style: _t(11.5, w: FontWeight.w600, c: _lime)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(21, w: FontWeight.w700, h: 1.2)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: _t(13, c: AppColors.scorifyTextMuted, h: 1.35)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (date != null) info(Icons.calendar_month_rounded, date!),
                    if ((place ?? "").trim().isNotEmpty) info(Icons.place_rounded, place!.trim()),
                    if (players != null) info(Icons.people_outline_rounded, "$players ${players == 1 ? "jugador" : "jugadores"}"),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(label: button, trailingIcon: Icons.arrow_forward_rounded, onPressed: onTap, height: 38, expand: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta chica (mitad de ancho): ícono en círculo, un número grande
/// con su etiqueta y una sola acción.
class HomeTile extends StatelessWidget {
  final IconData icon;
  final String value; // "2"
  final String title; // "Mis campeonatos"
  final String caption; // "inscritos"
  final String action;
  final VoidCallback onTap;
  const HomeTile({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.caption,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: _t(28, w: FontWeight.w700, h: 1)),
              const SizedBox(width: 6),
              Flexible(child: Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: AppColors.scorifyTextMuted))),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, maxLines: 1, style: _t(14, w: FontWeight.w600))),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(action, style: _t(12.5, w: FontWeight.w600, c: _mint)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 15, color: _mint),
            ],
          ),
        ],
      ),
    );
  }
}
