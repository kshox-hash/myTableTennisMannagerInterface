/// Estados posibles de un partido (grupo o llave). Antes cada pantalla tenía
/// su propia copia de este mapa y terminaron mostrando textos distintos para
/// el mismo estado — este es el único lugar donde se define el texto (mismo
/// criterio que el panel admin, ver matchStatusLabels.ts).
const Map<String, String> matchStatusLabel = {
  "scheduled": "Por jugar",
  "pending": "Por definir",
  "ready": "Listo para jugar",
  "played": "Jugado",
  "walkover": "W.O.",
  "bye": "Pase directo",
};

/// Motivo de un resultado no jugado (backend 060_match_result_reason.sql).
/// Mismos textos que la web (resultReason.ts). Antes la app decía "no se
/// presentó" en cualquier W.O., aunque el organizador lo hubiera cerrado por
/// lesión o abandono.
const Map<String, String> resultReasonLabel = {
  "no_show": "No se presentó",
  "injury": "Lesión",
  "retired": "Abandono",
  "disqualified": "Descalificación",
};

/// Estado corto para listas: "W.O. · Lesión" (o el estado normal).
String matchStatusText(String status, [String? resultReason]) {
  final base = matchStatusLabel[status] ?? status;
  final reason = status == "walkover" ? resultReasonLabel[resultReason] : null;
  return reason == null ? base : "$base · $reason";
}

/// Explicación del W.O. en el detalle del partido. [loserName] es quien
/// perdió por W.O.; [winnerName] quien se lo lleva.
String walkoverText(String? reason, {String? loserName, String? winnerName}) {
  final who = loserName != null ? " de $loserName" : "";
  final gana = winnerName != null ? " El partido se da por ganado a $winnerName." : "";
  return switch (reason) {
    "no_show" => "No se jugó: ${loserName ?? "un jugador"} no se presentó.$gana",
    "injury" => "Se definió por lesión$who.$gana",
    "retired" => "Se definió por abandono$who.$gana",
    "disqualified" => "Se definió por descalificación$who.$gana",
    _ => "No se jugó (W.O.).$gana",
  };
}

/// Nombre de una ronda de la llave — el único lugar donde se define (antes
/// había 7 copias y la misma final salía como "Final", "Ronda 3" o
/// "Ronda 3 de 3" según la pantalla). Ronda 0 es la pre-llave (partido de
/// definición para completar un cuadro que no es potencia de 2). Sin
/// [totalRounds] no se puede saber cuál es la final: queda "Ronda N".
String matchRoundLabel(int round, [int? totalRounds]) {
  if (round == 0) return "Pre-llave";
  final total = totalRounds ?? 0;
  if (total <= 0 || round > total) return "Ronda $round";
  return switch (total - round) {
    0 => "Final",
    1 => "Semifinal",
    2 => "Cuartos de final",
    3 => "Octavos de final",
    _ => "Ronda $round",
  };
}

/// "GR-3" → "Grupo 3" (los grupos se guardan como GR-N; antes algunas
/// pantallas mostraban "Grupo GR-3").
String groupLabel(String? name) {
  final n = (name ?? "").trim();
  if (n.isEmpty) return "Grupo";
  final m = RegExp(r"^GR-?(\w+)$", caseSensitive: false).firstMatch(n);
  return "Grupo ${m != null ? m.group(1) : n}";
}
