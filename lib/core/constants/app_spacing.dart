/// Escala de espaciado de la app (márgenes, separaciones, rellenos).
///
/// Todo espacio usa uno de estos valores — antes había valores sueltos (3, 5,
/// 18, 22, 28…) y la app se veía "armada a mano". Los SizedBox existentes ya
/// se normalizaron a esta escala; lo nuevo debería usar estas constantes.
///
/// Tipografía: la escala equivalente es 11 · 12 · 13 · 14 · 16 · 18 · 20 ·
/// 22 · 24 · 28 · 32 · 40 (ver AppTypography para los estilos con nombre).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 6;
  static const double sm = 8;
  static const double m = 12;
  static const double md = 14;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}
