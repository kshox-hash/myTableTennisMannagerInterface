/// Estados posibles de un partido (grupo o llave). Antes cada pantalla tenía
/// su propia copia de este mapa y terminaron mostrando textos distintos para
/// el mismo estado — este es el único lugar donde se define el texto (mismo
/// criterio que el panel admin, ver matchStatusLabels.ts).
const Map<String, String> matchStatusLabel = {
  "scheduled": "Por jugar",
  "pending": "Por definir",
  "ready": "Listo para jugar",
  "played": "Jugado",
  "walkover": "No se jugó",
  "bye": "Pase directo",
};

/// Ronda 0 es la pre-llave (partido de definición para completar un cuadro
/// que no es potencia de 2) — no un número de ronda real.
String matchRoundLabel(int round) => round == 0 ? "Pre-llave" : "Ronda $round";
