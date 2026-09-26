import 'package:flutter/material.dart';

/// Görsel yön E3 "Retro Pastel · düz harf karosu" (PLAN.md B2).
/// Kaynak: tasarimlar-6.html. 60-30-10: kapı %60 · krem not %30 · kiraz %10.
abstract final class Renk {
  // %60 — kapı (100° gradyan)
  static const kapi = [
    Color(0xFFCFE6DA),
    Color(0xFFC2DDCF),
    Color(0xFFD3E9DE),
    Color(0xFFBFD9CB),
  ];
  static const kapiDuraklari = [0.0, 0.45, 0.70, 1.0];

  // %30 — not kâğıdı, girdi zemini
  static const krem = Color(0xFFFFF8EA);

  // %10 — karo, ana düğme, ekle düğmesi, çizgi
  static const kiraz = Color(0xFFC8233A);
  static const kirazKoyu = Color(0xFF7E1020);

  static const murekkep = Color(0xFF2D3B35);
  static const soluk = Color(0xFF5D6F66);
  static const rozet = Color(0xFF8C9492);
  static const girdiKenar = Color(0x2E000000); // rgba(0,0,0,.18)

  // krom kulp (90° gradyan)
  static const kulp = [Color(0xFF9FA7A5), Color(0xFFF4F6F6), Color(0xFF8C9492)];
  static const kulpDuraklari = [0.0, 0.45, 1.0];
}

abstract final class Yazi {
  static const el = 'Kalam';
  static const karo = 'ArchivoBlack';
  static const serif = 'Fraunces';
}

/// B2.4 — bütün yaylanmalar bu eğriyle: cubic-bezier(.34,1.56,.64,1).
const yay = Cubic(0.34, 1.56, 0.64, 1);

/// Çizginin soldan sağa çekilişi: cubic-bezier(.6,0,.3,1).
const cizgiEgrisi = Cubic(0.6, 0, 0.3, 1);

ThemeData tema() => ThemeData(
  fontFamily: Yazi.el,
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: const ColorScheme.light(
    primary: Renk.kiraz,
    onPrimary: Renk.krem,
    surface: Renk.krem,
    onSurface: Renk.murekkep,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Renk.kiraz,
    selectionColor: Renk.kiraz.withValues(alpha: 0.25),
    selectionHandleColor: Renk.kiraz,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Renk.murekkep,
    contentTextStyle: TextStyle(fontFamily: Yazi.el, color: Renk.krem),
  ),
);
