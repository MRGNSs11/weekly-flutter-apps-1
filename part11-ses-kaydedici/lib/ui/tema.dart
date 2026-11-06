import 'package:flutter/material.dart';

/// B2.1 — 60-30-10. Değerler taslağın `.y6` CSS'inden birebir.
abstract final class Renk {
  // 60: akan mor bulut
  static const bulutTaban = Color(0xFF1A0F2E);
  static const bulut1 = Color(0xFF6A3DF0);
  static const bulut2 = Color(0xFFC04CFD);
  static const bulut3 = Color(0xFF3A2BD8);
  static const kartMor = Color(0xFF2A1850);
  // 30: lila beyaz
  static const lilaBeyaz = Color(0xFFFBF8FF);
  static const sayfaCizgi = Color(0xFFEEE7F7);
  static const sayfaSoluk = Color(0xFF8E83A3);
  static const tutamacGri = Color(0xFFD8CFE8);
  // 10: tek vurgu
  static const turuncu = Color(0xFFFF7A59);
}

/// Outfit değişken font: kalınlık `wght` ekseniyle verilir.
/// [aralik] CSS'teki `letter-spacing` (em).
TextStyle yazi(
  double boyut,
  double kalinlik, {
  double aralik = 0,
  Color renk = Renk.lilaBeyaz,
  double opaklik = 1,
  double? satir,
}) => TextStyle(
  fontFamily: 'Outfit',
  fontSize: boyut,
  fontVariations: [FontVariation('wght', kalinlik)],
  letterSpacing: aralik * boyut,
  color: renk.withValues(alpha: opaklik),
  height: satir,
);

ThemeData tema() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Renk.bulutTaban,
  fontFamily: 'Outfit',
  colorScheme: const ColorScheme.dark(
    surface: Renk.bulutTaban,
    primary: Renk.turuncu,
    onSurface: Renk.lilaBeyaz,
  ),
);
