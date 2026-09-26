import 'package:flutter/material.dart';

import '../../liste/bas_harf.dart';
import '../tema.dart';

/// Kiraz karo, içinde krem harf. Hiç eğik değil (Ömer: "yamuk olmasın").
/// Altta 3 dp koyu kiraz şerit = kabartma (CSS: inset 0 -3px 0).
class Karo extends StatelessWidget {
  const Karo(
    this.harf, {
    super.key,
    this.genislik = 24,
    this.yukseklik = 27,
    this.punto = 15,
  });

  /// Liste başlığı: 28×32, 18 pt.
  const Karo.baslik(this.harf, {super.key})
    : genislik = 28,
      yukseklik = 32,
      punto = 18;

  /// Başla ekranı başlığı: 32×38, 22 pt.
  const Karo.buyuk(this.harf, {super.key})
    : genislik = 32,
      yukseklik = 38,
      punto = 22;

  final String harf;
  final double genislik;
  final double yukseklik;
  final double punto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: genislik,
      height: yukseklik,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Renk.kiraz,
            Renk.kiraz,
            Renk.kirazKoyu,
            Renk.kirazKoyu,
          ],
          stops: [0, 1 - 3 / yukseklik, 1 - 3 / yukseklik, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000), // .28
            offset: Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        harf,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: Yazi.karo,
          fontSize: punto,
          height: 1,
          color: Renk.krem,
        ),
      ),
    );
  }
}

/// Yan yana, aynı hizada karolar: "LİSTE", "ORTAK".
class KaroSatiri extends StatelessWidget {
  const KaroSatiri(this.kelime, {super.key, this.buyuk = false});

  final String kelime;
  final bool buyuk;

  @override
  Widget build(BuildContext context) {
    final harfler = turkceBuyuk(kelime).split('');
    return Semantics(
      label: kelime,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < harfler.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            buyuk ? Karo.buyuk(harfler[i]) : Karo.baslik(harfler[i]),
          ],
        ],
      ),
    );
  }
}
