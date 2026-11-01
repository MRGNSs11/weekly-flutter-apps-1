import 'package:flutter/material.dart';

/// R4 Okyanus — PLAN.md B2.1. Kaynak taslak: `renkler.html` → `P[3]`.
@immutable
class Renkler extends ThemeExtension<Renkler> {
  const Renkler({
    required this.zemin,
    required this.kart,
    required this.cizgi,
    required this.metin,
    required this.soluk,
    required this.vurgu,
    required this.vurgu2,
    required this.cam,
    required this.serit,
    required this.seritMetin,
    required this.kaynak,
    required this.kaynakMetin,
  });

  final List<Color> zemin; // 160° gradyan
  final Color kart, cizgi, metin, soluk, vurgu, vurgu2, cam;
  final Color serit, seritMetin, kaynak, kaynakMetin;

  static const aydinlik = Renkler(
    zemin: [Color(0xFFDCECFB), Color(0xFFE9F6F8)],
    kart: Color(0xE0FFFFFF), // %88
    cizgi: Color(0x00000000),
    metin: Color(0xFF132033),
    soluk: Color(0xFF6F7F93),
    vurgu: Color(0xFF1F6FD1),
    vurgu2: Color(0xFF9CC8FF),
    cam: Color(0x80FFFFFF), // %50
    serit: Color(0xFF132033),
    seritMetin: Color(0xFFFFFFFF),
    kaynak: Color(0xFF132033),
    kaynakMetin: Color(0xFFD3E1F2),
  );

  static const karanlik = Renkler(
    zemin: [Color(0xFF0A1220), Color(0xFF0D1A2C)],
    kart: Color(0x0FFFFFFF), // %6
    cizgi: Color(0x12FFFFFF), // %7
    metin: Color(0xFFE4EDF8),
    soluk: Color(0xFF8193A8),
    vurgu: Color(0xFF5AA9FF),
    vurgu2: Color(0xFFA9D1FF),
    cam: Color(0x8C0A1220), // %55
    serit: Color(0xFF173257),
    seritMetin: Color(0xFFFFFFFF),
    kaynak: Color(0xFF060B14),
    kaynakMetin: Color(0xFFD3E1F2),
  );

  static Renkler of(BuildContext c) => Theme.of(c).extension<Renkler>()!;

  @override
  Renkler copyWith() => this;

  @override
  Renkler lerp(Renkler? other, double t) => t < .5 ? this : (other ?? this);
}

/// Değişken font: kalınlık `wght` ekseniyle verilir, yoksa Android'de
/// her kalınlık aynı görünür.
TextStyle yazi(
  double boyut, {
  FontWeight kalinlik = FontWeight.w400,
  Color? renk,
  bool mono = false,
  double? satir,
}) => TextStyle(
  fontFamily: mono ? 'JetBrainsMono' : 'DMSans',
  fontSize: boyut,
  fontWeight: kalinlik,
  fontVariations: [FontVariation('wght', kalinlik.value.toDouble())],
  color: renk,
  height: satir,
);

ThemeData temaYap(Brightness parlaklik) {
  final r = parlaklik == Brightness.light ? Renkler.aydinlik : Renkler.karanlik;
  return ThemeData(
    brightness: parlaklik,
    fontFamily: 'DMSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: r.vurgu,
      brightness: parlaklik,
      primary: r.vurgu,
    ),
    scaffoldBackgroundColor: r.zemin.first,
    extensions: [r],
  );
}
