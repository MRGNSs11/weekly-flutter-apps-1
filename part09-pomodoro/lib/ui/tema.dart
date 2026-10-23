import 'package:flutter/material.dart';

import '../alan/faz.dart';

/// R1 Gece mavisi (PLAN B2.1).
abstract final class Renk {
  static const zemin = Color(0xFFE8EDF5);
  static const yazi = Color(0xFF14213D);
  static const vurgu = Color(0xFF1F3A93);
  static const mola = Color(0xFF3FA796);
  static const dolguYazi = Color(0xFFFFFFFF);

  /// Noktalar ve küçük butonlar (%90 beyaz).
  static const hap = Color(0xE6FFFFFF);

  /// Üst satırdaki haplar: faz etiketi, Bugün, Atla, Ayarlar (%85 beyaz).
  static const hapUst = Color(0xD9FFFFFF);
  static const hapYazi = Color(0xFF1D1D1D);
  static const bantYazi = zemin;
  static const konfetiSari = Color(0xFFF4D35E);

  static Color faz(Faz f) => f == Faz.calisma ? vurgu : mola;
}

abstract final class Yazi {
  static const rakam = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 86,
    height: 1,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle inter(double boyut, int kalinlik, {Color? renk}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: boyut,
        height: 1.2,
        fontWeight: FontWeight.values[kalinlik ~/ 100 - 1],
        fontVariations: [FontVariation('wght', kalinlik.toDouble())],
        color: renk,
      );
}

/// Faz rengi geçişi ve diğer süreler (PLAN B2.4).
abstract final class Sure {
  static const fazRengi = Duration(milliseconds: 600);
  static const ikonDonusum = Duration(milliseconds: 250);
  static const nefes = Duration(milliseconds: 2400);
  static const artiBir = Duration(milliseconds: 600);
  static const bant = Duration(milliseconds: 300);
  static const noktaPop = Duration(milliseconds: 400);
  static const noktaAktif = Duration(milliseconds: 1600);
}

ThemeData pomodoroTemasi() => ThemeData(
  colorSchemeSeed: Renk.vurgu,
  scaffoldBackgroundColor: Renk.zemin,
  fontFamily: 'Inter',
);
