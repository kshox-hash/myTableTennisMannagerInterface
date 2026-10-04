import "dart:math" as math;

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
const _lime = AppColors.scorifyButterfly;

TextStyle _t(double size, {FontWeight w = FontWeight.w400, Color c = AppColors.scorifyText, double? ls, double? h}) =>
    TextStyle(fontFamily: AppTypography.body, fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

/// Tarjeta del Inicio: fondo en degradado tenue y borde sutil.
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  const HomeCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gradient, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return CardBorder(
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient ?? AppColors.cardGradient),
            child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
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
            borderRadius: BorderRadius.circular(8),
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
  const HomeProfileRow({
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
      borderRadius: BorderRadius.circular(16),
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
                        child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(17, w: FontWeight.w600, h: 1.2)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, c: AppColors.scorifyTextMuted)),
                      ),
                      if (age != null) ...[meta(Icons.person_outline_rounded, "$age años"), const SizedBox(width: 12)],
                      if (genderLabel != null) meta(gender == "female" ? Icons.female_rounded : Icons.male_rounded, genderLabel),
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
    required this.onDetail,
    this.onOpponent,
  });

  @override
  Widget build(BuildContext context) {
    Widget player(String? id, String? url, String name, String? club, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
      gradient: AppColors.featuredGradient,
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
                const HomeCardTitle(icon: Icons.calendar_month_rounded, title: "Próximo partido"),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    info(Icons.event_rounded, when),
                    sep(),
                    info(Icons.table_restaurant_rounded, table),
                    if ((place ?? "").trim().isNotEmpty) ...[sep(), info(Icons.place_outlined, place!.trim(), flex: 3)],
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
/// línea con la evolución de tu efectividad en los últimos partidos.
class HomePerformanceCard extends StatelessWidget {
  final int played;
  final int won;
  final List<bool> trend; // resultados del más antiguo al más reciente
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
          if (trend.length >= 2)
            Positioned(
              right: 0,
              bottom: 0,
              width: 200,
              height: 34,
              child: CustomPaint(painter: _TrendPainter(trend)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                HomeCardTitle(icon: Icons.bar_chart_rounded, title: "Rendimiento", action: "Ver estadísticas", onAction: onStats),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Ring(rate: rate, empty: played == 0),
                    const SizedBox(width: 14),
                    stat("$played", "Partidos"),
                    sep(),
                    stat("$won", "Victorias"),
                    sep(),
                    stat("$lost", "Derrotas"),
                  ],
                ),
                // Espacio para la línea de tendencia, bajo los números.
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double rate;
  final bool empty;
  const _Ring({required this.rate, required this.empty});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _RingPainter(empty ? 0 : rate),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(empty ? "—" : "${(rate * 100).round()}%", style: _t(22, w: FontWeight.w700, h: 1.1)),
              Text("Efectividad", style: _t(10.5, c: AppColors.scorifyTextMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.white.withValues(alpha: 0.08));
    if (value <= 0) return;
    final sweep = math.pi * 2 * value.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: math.pi * 1.5,
            colors: [_lime, _mint, _lime],
            transform: GradientRotation(-math.pi / 2),
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// Línea de la efectividad acumulada partido a partido (decorativa, tenue).
class _TrendPainter extends CustomPainter {
  final List<bool> results;
  _TrendPainter(this.results);
  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    var w = 0;
    for (var i = 0; i < results.length; i++) {
      if (results[i]) w++;
      final rate = w / (i + 1);
      final x = size.width * i / (results.length - 1);
      final y = size.height - 6 - (size.height - 12) * rate;
      pts.add(Offset(x, y));
    }
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lime.withValues(alpha: 0.16), Colors.transparent],
          ).createShader(rect));
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = LinearGradient(colors: [_lime.withValues(alpha: 0.15), _lime.withValues(alpha: 0.75)]).createShader(rect));
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.results != results;
}

/// Racha actual: número grande, comparación con tu mejor racha anterior y
/// los últimos 5 resultados (G/P).
class HomeStreakCardV2 extends StatelessWidget {
  final List<bool> form; // últimos 5, del más antiguo al más reciente
  final int streak; // racha actual (cantidad)
  final bool winning;
  final int bestPrevious; // mejor racha de victorias anterior
  final VoidCallback onTap;
  const HomeStreakCardV2({
    super.key,
    required this.form,
    required this.streak,
    required this.winning,
    required this.bestPrevious,
    required this.onTap,
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
                    const Icon(Icons.chevron_right_rounded, color: AppColors.scorifyTextMuted),
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

class HomeResultsCard extends StatelessWidget {
  final List<HomeResult> results;
  final VoidCallback onAll;
  const HomeResultsCard({super.key, required this.results, required this.onAll});

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: i < results.length ? _ResultTile(r: results[i]) : const SizedBox.shrink()),
              ],
            ],
          ),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: r.onTap,
        borderRadius: BorderRadius.circular(10),
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
