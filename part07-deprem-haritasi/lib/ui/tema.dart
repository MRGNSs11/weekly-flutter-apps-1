import 'package:flutter/material.dart';

/// Sismogram Şeridi renkleri (PLAN B2.1, taslak `tasarimlar.html` `.k1`).
/// 60-30-10: zemin %60 · yüzey %30 · mor %10.
abstract final class Renk {
  static const zemin = Color(0xFFE9EDE6);
  static const yuzey = Color(0xFFFFFFFF);
  static const mor = Color(0xFFB5121B); // karmin (2026-10-10, eski mor 6A2CFF)
  static const murekkep = Color(0xFF17241D);
  static const soluk = Color(0xFF5F6E66);
  static const bantVurgu = Color(0xFFF59A9F);
  static const ayrac = Color(0xFFCFD8D1);
  static const izgara = Color(0x1F17241D); // rgba(23,36,29,.12)
}

/// Yazı stilleri (PLAN B2.2; 2026-10-10 Instrument → Bricolage Grotesque,
/// `font-secenekleri.html` #6). Değişken font: kalınlık `fontWeight` ile
/// değil `wght` ekseniyle veriliyor, yoksa hep 400 çizilir. `opsz` de
/// boyla birlikte veriliyor (tarayıcı bunu kendisi yapar, Flutter yapmaz).
abstract final class Yazi {
  static TextStyle sans(
    double boy, {
    double wght = 400,
    Color renk = Renk.murekkep,
    double yukseklik = 1.25,
  }) => TextStyle(
    fontFamily: 'BricolageGrotesque',
    fontSize: boy,
    fontVariations: [
      FontVariation('wght', wght),
      FontVariation('opsz', boy.clamp(12, 96).toDouble()),
    ],
    color: renk,
    height: yukseklik,
  );

  /// Başlık ve büyük sayı: aynı aile, kalın.
  static TextStyle iri(double boy, {Color renk = Renk.murekkep}) =>
      sans(boy, wght: 800, renk: renk, yukseklik: 1);

  static final baslik = iri(26);
  static final dev = iri(62, renk: Renk.mor).copyWith(letterSpacing: -1.2);
  static final yer = sans(15, wght: 600);
  static final alt = sans(12, renk: Renk.soluk);
  static final bant = sans(12.5, renk: Renk.zemin);
  static final bantSayi = sans(12.5, wght: 700, renk: Renk.bantVurgu);
  static final saatEtiketi = sans(10, wght: 600, renk: Renk.soluk);
  static final ipucu = sans(11, renk: Renk.soluk).copyWith(letterSpacing: 0.66);
  static final afad = sans(
    11,
    wght: 700,
    renk: Renk.mor,
  ).copyWith(letterSpacing: 1.32);
  static final cizgiTarihi = sans(11, wght: 700, renk: Renk.mor);
}

ThemeData temaKur() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Renk.zemin,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Renk.mor,
    primary: Renk.mor,
    surface: Renk.zemin,
  ),
  fontFamily: 'BricolageGrotesque',
);
