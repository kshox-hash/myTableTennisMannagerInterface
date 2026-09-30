/// "myttm torneo comunal san miguel" -> "Myttm Torneo Comunal San Miguel".
///
/// Los organizadores escriben los nombres como les sale (todo en minúscula,
/// todo en mayúscula); mostrarlos así se veía descuidado. Cada palabra con
/// mayúscula inicial, salvo artículos/preposiciones cortas en medio ("de",
/// "la", "y"…). Una palabra que ya trae mayúsculas internas y no está toda
/// en mayúscula ("MyTTM", "McDonald") se respeta tal cual.
String prettyTitle(String raw) {
  const small = {"de", "del", "la", "las", "el", "los", "y", "en", "a", "al", "o", "e", "con", "por", "para"};
  final words = raw.trim().split(RegExp(r"\s+"));
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.isEmpty) continue;
    final lower = w.toLowerCase();
    final isAllCaps = w == w.toUpperCase();
    final hasMixedCase = !isAllCaps && w != lower;
    if (lower == "myttm") {
      out.add("MyTTM");
    } else if (hasMixedCase) {
      out.add(w);
    } else if (i > 0 && small.contains(lower)) {
      out.add(lower);
    } else if (isAllCaps && w.length <= 4 && RegExp(r"[A-ZÁÉÍÓÚÑ]").hasMatch(w) && words.length > 1) {
      // Siglas cortas en mayúscula ("MYTTM" no, pero "FECHITEME"/"TTM"/"U23" sí se respetan)
      out.add(w);
    } else {
      out.add(lower[0].toUpperCase() + lower.substring(1));
    }
  }
  return out.join(" ");
}

const _months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

/// "2026-09-29 05:54:13.061-03" / ISO -> "29 sep 2026 · 05:54" (hora local).
/// Si no se puede leer, devuelve el texto tal cual.
String prettyDateTime(String raw) {
  var s = raw.trim().replaceFirst(" ", "T");
  // Postgres manda la zona como "-03"; DateTime.parse necesita "-03:00".
  s = s.replaceFirstMapped(RegExp(r"([+-]\d{2})$"), (m) => "${m[1]}:00");
  final d = DateTime.tryParse(s)?.toLocal();
  if (d == null) return raw;
  final hh = d.hour.toString().padLeft(2, "0");
  final mm = d.minute.toString().padLeft(2, "0");
  return "${d.day} ${_months[d.month - 1]} ${d.year} · $hh:$mm";
}
