import 'package:flutter/material.dart';

/// "Sıvı Cam" tokenları. Kaynak: `tasarimlar.html` → `.cam` CSS'i ve
/// `CIZ.cam`. Değerler PLAN.md B2.1–B2.3'te donduruldu; buradan sapılmaz.
abstract final class Renk {
  static const bgUst = Color(0xFFDDF3F7);
  static const bgAlt = Color(0xFFC8ECF3);
  static const suUst = Color(0xFF05BFDB);
  static const suAlt = Color(0xFF0A4D68);
  static const arkaDalga = Color(0x8C05BFDB); // #05BFDB %55
  static const ink = Color(0xFF0A3A4F);
  static const muted = Color(0xFF4F7C8C);
  static const accent = Color(0xFF0A4D68);
  static const line = Color(0xFFB5DCE5);
  static const camDolgu = Color(0x38FFFFFF); // beyaz %22
  static const camCerceve = Color(0x8CFFFFFF); // beyaz %55
  static const camIsik = Color(0xB3FFFFFF); // beyaz %70
  static const damla = Color(0xFFE8FBFF);
  // Açık gökyüzünde damla seçilmiyordu (Ömer, cihaz testi) → ince koyu çerçeve.
  static const damlaCizgi = Color(0x990A4D68); // #0A4D68 %60
  static const kabarcik = Color(0x99FFFFFF); // beyaz %60
}

abstract final class Olcu {
  static const camYaricap = 28.0;
  static const camBlur = 12.0;
  static const dugmeYukseklik = 48.0;
  static const kenar = 16.0;
  static const altBosluk = 18.0;
  static const dugmeArasi = 8.0;

  /// Su en fazla ekranın %80'i, en az %4'ü (boşken de ince dalga görünür).
  static const suEnFazla = 0.80;
  static const suEnAz = 0.04;
}

/// Sora değişken font: kalınlık `fontWeight` yetmez, eksen de ayarlanmalı.
TextStyle sora(
  double boyut, {
  int kalinlik = 400,
  Color renk = Renk.ink,
  double harfAraligi = 0,
  double? satir,
}) => TextStyle(
  fontFamily: 'Sora',
  fontSize: boyut,
  fontWeight: FontWeight.values[(kalinlik ~/ 100 - 1).clamp(0, 8)],
  fontVariations: [FontVariation('wght', kalinlik.toDouble())],
  color: renk,
  letterSpacing: harfAraligi,
  height: satir,
);

ThemeData uygulamaTemasi() {
  final temel = ThemeData(
    useMaterial3: true,
    fontFamily: 'Sora',
    scaffoldBackgroundColor: Renk.bgUst,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Renk.accent,
      primary: Renk.accent,
      surface: Renk.bgUst,
      onSurface: Renk.ink,
    ),
  );
  return temel.copyWith(
    textTheme: temel.textTheme.apply(
      bodyColor: Renk.ink,
      displayColor: Renk.ink,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
