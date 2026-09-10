/// El driver pg de Postgres serializa columnas bigint/numeric como STRING en
/// el JSON (para no perder precisión), mientras que integer/int viene como
/// número — no hay forma de saber cuál es cuál sin mirar el schema, así que
/// todo parseo numérico desde el backend tiene que aceptar ambos casos. Un
/// `as num?` directo revienta con un TypeError apenas el campo es un string
/// ("1" en vez de 1).
num? numOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

int intOrDefault(dynamic v, [int fallback = 0]) => numOrNull(v)?.toInt() ?? fallback;

int? intOrNull(dynamic v) => numOrNull(v)?.toInt();
