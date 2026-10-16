import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kil + Beton renkleri (PLAN B2.1, taslak `kil-renkler.html` K9).
/// Neumorfizm: zemin, tahta, kareler ve düğmeler aynı renk; ayrımı iki gölge
/// (sağ-alt koyu, sol-üst açık) yapar.
abstract final class Renk {
  static const zemin = Color(0xFFD8D8D5);
  static const golge = Color(0xFFB5B5B1);
  static const isik = Color(0xFFFAFAF8);
  static const yazi = Color(0xFF1E1E1C);
  static const soluk = Color(0xFF868683);
  static const vurgu = Color(0xFFFF4D00);

  /// Karedeki rakamın rengi: soluktan yazıya koyulaşır, 512 ve üstü vurgu.
  /// Taslak: `color-mix(yazi (25 + log2(v)·9)%, soluk)`.
  static Color rakam(int deger) {
    if (deger >= 512) return vurgu;
    final k = math.log(deger) / math.ln2;
    return Color.lerp(soluk, yazi, math.min(1, (25 + k * 9) / 100))!;
  }
}

/// Ölçüler (PLAN B2.3, taslak px = dp).
abstract final class Olcu {
  static const kare = 62.0;
  static const aralik = 9.0;
  static const kareKose = 16.0;
  static const tahtaKose = 24.0;
  static const tahta = 4 * kare + 5 * aralik; // 293

  /// Boş hücrenin ve kurşunlaşmış karenin içe basıklığı.
  static const cukur = -3.0;

  /// Karenin kabarıklığı: `1,5 + log2(v) × 0,75` (2 → 2,25 · 2048 → 9).
  static double kabarma(int deger) => 1.5 + (math.log(deger) / math.ln2) * 0.75;

  /// 2048 sahnesinde kazanan karenin kabarıklığı.
  static const zirve = 9.0;
}

/// Animasyon süreleri (PLAN B2.4).
abstract final class Sure {
  static const kayma = Duration(milliseconds: 110);
  static const geriKayma = Duration(milliseconds: 300);
  static const dogma = Duration(milliseconds: 380);
  static const yogurma = Duration(milliseconds: 340);
  static const egim = Duration(milliseconds: 470);
  static const geriSarma = Duration(milliseconds: 650);
  static const sonme = Duration(milliseconds: 500);
  static const kursun = Duration(milliseconds: 350);
  static const nefes = Duration(milliseconds: 1200);

  /// 2048 sahnesi: kayma bittikten kaç ms sonra başlar, karelerin uzaklık
  /// başına gecikmesi, katmanın kayma bittikten sonra ne zaman açılacağı.
  static const zirveBaslangic = Duration(milliseconds: 260);
  static const zirveAdim = 90;
  static const zirveKatman = Duration(milliseconds: 1900);

  /// Kurşunlaşma: başlangıç, kareler arası, son kareden sonra katman.
  static const kursunBaslangic = Duration(milliseconds: 200);
  static const kursunAdim = 45;
  static const kursunKatman = Duration(milliseconds: 500);
}

/// Yazı stilleri (PLAN B2.2). Nunito değişken font: kalınlık `wght` ekseniyle
/// veriliyor, yoksa hep 400 çizilir.
abstract final class Yazi {
  static TextStyle nunito(
    double boy, {
    double wght = 800,
    Color renk = Renk.yazi,
    double yukseklik = 1.2,
    double harfAraligi = 0,
  }) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: boy,
    fontVariations: [FontVariation('wght', wght)],
    color: renk,
    height: yukseklik,
    letterSpacing: harfAraligi,
  );

  /// Karedeki rakam: 1-2 hane 30, 3 hane %86, 4+ hane %68.
  static TextStyle rakam(int deger, {Color? renk}) {
    final hane = deger.toString().length;
    final boy = hane <= 2 ? 30.0 : (hane == 3 ? 30 * 0.86 : 30 * 0.68);
    return nunito(
      boy,
      wght: 900,
      renk: renk ?? Renk.rakam(deger),
      yukseklik: 1,
    );
  }

  static final skor = nunito(26, wght: 900, yukseklik: 1.15);
  static final etiket = nunito(10, renk: Renk.soluk, harfAraligi: 1.4);
  static final baslik = nunito(
    15,
    wght: 900,
    renk: Renk.soluk,
    harfAraligi: 4.5,
  );
  static final dugme = nunito(15);
  static final ipucu = nunito(12, wght: 700, renk: Renk.soluk);
  static final katmanBaslik = nunito(
    56,
    wght: 900,
    renk: Renk.vurgu,
    yukseklik: 1,
  );
  static final katmanBitti = nunito(34, wght: 900, yukseklik: 1);
  static final katmanMetin = nunito(15, wght: 700);
}

ThemeData temaKur() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Renk.zemin,
  fontFamily: 'Nunito',
  colorScheme: ColorScheme.fromSeed(seedColor: Renk.vurgu, surface: Renk.zemin),
  splashFactory: NoSplash.splashFactory,
);
