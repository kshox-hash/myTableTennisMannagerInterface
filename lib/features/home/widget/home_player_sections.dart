import "package:flutter/material.dart";
import "package:myttmi/core/ui/premium_motion.dart";
import "package:myttmi/core/clubs/club_crests.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/features/calendar/models/calendar_event.dart";
import "package:myttmi/features/home/widget/home_v2.dart";
import "package:myttmi/features/player/models/player_category_view_model.dart";
import "package:myttmi/features/player/models/tournament_match_model.dart";

/// Secciones del Inicio del jugador: datos primero, color solo para estado.
/// (Mi grupo · Últimos resultados · Mis campeonatos.)

const _accent = Color(0xFF8EC5FF); // azul hielo: títulos de sección / lo mío
const _muted = Color(0x99FFFFFF);
const _faint = Color(0x59FFFFFF);
const _win = Color(0xFF3DDC97); // ganado
const _loss = Color(0xFFFF6B6B); // perdido
const _gold = Color(0xFFA6D32D); // clasifica (Oro / llave): lima de la web
const _silver = Color(0xFFC0C7CF); // clasifica a Plata: plateado de la web

TextStyle _s(double size, {FontWeight w = FontWeight.w500, Color c = Colors.white, double? ls}) =>
    TextStyle(fontFamily: "Montserrat", fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: 1.2);

TextStyle _n(double size, {FontWeight w = FontWeight.w700, Color c = Colors.white}) => TextStyle(
    fontFamily: AppTypography.display,
    fontSize: size,
    fontWeight: w,
    color: c,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()]);

/// Título de sección: mayúsculas chicas espaciadas + acción opcional.
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const HomeSectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10), // 24 entre secciones
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: _s(11, w: FontWeight.w700, c: _accent, ls: 1.4))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: _s(12, w: FontWeight.w600, c: _muted)),
            ),
        ],
      ),
    );
  }
}

/// Mi grupo: tabla chica con mi fila resaltada y los que clasifican marcados.
class HomeGroupTable extends StatelessWidget {
  final String groupName;
  final String category;
  final List<PlayerStanding> standings;
  final String myId;
  final int qualifiers;
  /// Oro y Plata: el puesto siguiente a los clasificados va a Plata (como en la web).
  final bool hasSilver;
  final VoidCallback onTap;
  const HomeGroupTable({
    super.key,
    required this.groupName,
    required this.category,
    required this.standings,
    required this.myId,
    required this.onTap,
    this.qualifiers = 2,
    this.hasSilver = false,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [...standings]..sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));
    return HomeCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("Grupo ${groupName.replaceFirst(RegExp(r"^GR-?", caseSensitive: false), "")}",
                  style: _s(15, w: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(12, c: _muted))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 22),
              Expanded(child: Text("JUGADOR", style: _s(9.5, w: FontWeight.w700, c: _faint, ls: 1))),
              SizedBox(width: 30, child: Text("PJ", textAlign: TextAlign.center, style: _s(9.5, w: FontWeight.w700, c: _faint))),
              SizedBox(width: 30, child: Text("PG", textAlign: TextAlign.center, style: _s(9.5, w: FontWeight.w700, c: _faint))),
              SizedBox(width: 40, child: Text("SETS", textAlign: TextAlign.right, style: _s(9.5, w: FontWeight.w700, c: _faint))),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) _row(rows[i], i),
          // Leyenda dentro de la tarjeta (como la web: "Clasifica a Oro / a Plata").
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              children: [
                _dot(_gold),
                Text(hasSilver ? "Clasifica a Oro" : "Clasifica a la llave", style: _s(10.5, c: _muted)),
                if (hasSilver) ...[
                  const SizedBox(width: 14),
                  _dot(_silver),
                  Text("Clasifica a Plata", style: _s(10.5, c: _muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _row(PlayerStanding r, int i) {
    final me = r.idUser == myId;
    final pos = r.position ?? i + 1;
    // Como la web: clasificado (Oro/llave) en círculo lima, Plata en plateado.
    final qualifies = r.qualifiedToBracket;
    final silver = hasSilver && !qualifies && pos == qualifiers + 1 && r.played > 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      color: me ? const Color(0x268EC5FF) : Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: qualifies ? _gold : (silver ? _silver : Colors.transparent),
            ),
            child: Text("$pos", style: _n(11.5, c: qualifies || silver ? const Color(0xFF16210A) : _muted)),
          ),
          const SizedBox(width: 8),
          // Escudo del club al lado del nombre (como en la web) y el club debajo.
          ClubCrest(idUser: r.idUser, size: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me ? "Tú" : r.playerName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(13, w: me ? FontWeight.w800 : FontWeight.w500)),
                if ((r.clubName ?? "").trim().isNotEmpty)
                  Text(r.clubName!.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(10.5, c: _faint)),
              ],
            ),
          ),
          SizedBox(width: 30, child: Text("${r.played}", textAlign: TextAlign.center, style: _n(13, c: _muted))),
          SizedBox(width: 30, child: Text("${r.won}", textAlign: TextAlign.center, style: _n(13))),
          SizedBox(
            width: 40,
            child: Text("${r.setsFor}-${r.setsAgainst}", textAlign: TextAlign.right, style: _n(13, c: _muted)),
          ),
        ],
      ),
    );
  }
}

/// Últimos resultados: una línea por partido (rival, torneo, sets, G/P).
class HomeRecentResults extends StatelessWidget {
  final List<PlayerMatchHistoryItem> items;
  final String myId;
  final void Function(PlayerMatchHistoryItem) onOpen;
  const HomeRecentResults({super.key, required this.items, required this.myId, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF), indent: 14, endIndent: 14),
            _line(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(PlayerMatchHistoryItem m) {
    final iAmP1 = m.player1Id == myId;
    final rival = iAmP1 ? m.player2Name : m.player1Name;
    final mine = iAmP1 ? m.setsPlayer1 : m.setsPlayer2;
    final theirs = iAmP1 ? m.setsPlayer2 : m.setsPlayer1;
    final won = m.winnerId != null && m.winnerId == myId;
    final stage = m.groupName != null ? "Grupo ${m.groupName}" : "Llave";
    return InkWell(
      onTap: () => onOpen(m),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              color: (won ? _win : _loss).withValues(alpha: 0.16),
              child: Text(won ? "G" : "P", style: _s(12, w: FontWeight.w800, c: won ? _win : _loss)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("vs $rival", maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(14, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text("${m.tournamentName} · $stage",
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(11.5, c: _muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CountUpText(mine, style: _n(18, c: won ? Colors.white : _muted)),
            Text("-", style: _n(18, c: _muted)),
            CountUpText(theirs, style: _n(18, c: won ? Colors.white : _muted)),
          ],
        ),
      ),
    );
  }
}

/// Mis campeonatos: lista compacta con fecha a la izquierda y estado.
class HomeMyTournaments extends StatelessWidget {
  final List<CalendarEvent> events;
  final void Function(CalendarEvent) onOpen;
  const HomeMyTournaments({super.key, required this.events, required this.onOpen});

  static const _months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF), indent: 14, endIndent: 14),
            _line(events[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(CalendarEvent e) {
    final live = e.inProgress;
    return InkWell(
      onTap: () => onOpen(e),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Column(
                children: [
                  Text("${e.date.day}", style: _n(18)),
                  Text(_months[e.date.month - 1], style: _s(9.5, w: FontWeight.w700, c: _muted, ls: 0.8)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.tournamentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(14, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(e.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _s(11.5, c: _muted)),
                ],
              ),
            ),
            if (live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0x33FF4D5E),
                child: Text("EN CURSO", style: _s(9.5, w: FontWeight.w800, c: const Color(0xFFFF6B7A), ls: 0.8)),
              ),
          ],
        ),
      ),
    );
  }
}
