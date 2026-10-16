import 'package:flutter/material.dart';

import 'tema.dart';

/// Kil yüzeyi: tek bir [yukseklik] değeriyle kabarık, düz ya da içe basık.
///
/// - `yukseklik > 0`: dışa kabarık. Sağ-altta koyu, sol-üstte açık gölge,
///   ikisi de `yukseklik` kadar kayık (CSS `g g 2g` + `-g -g 2g`).
/// - `yukseklik == 0`: düz, yalnız zemin rengi.
/// - `yukseklik < 0`: içe basık. Gölgeler yüzeyin içinde (CSS `inset`).
///
/// Uygulamadaki animasyonların çoğu bu tek sayının animasyonu: kare
/// çukurdan doğar (−3 → +g), yoğrulur (+g → −4 → +g), kurşunlaşır (→ −3).
///
/// Flutter'ın `BoxShadow`'unda iç gölge yok; içe basıklık "delikli
/// dikdörtgen" yöntemiyle çizilir: yüzeyin dışını kaplayan, ortasında yüzey
/// biçiminde bir delik olan şekil kaydırılıp bulanıklaştırılır ve yüzeyin
/// içine kırpılır. Deliğin kenarından taşan gölge, iç gölge olarak görünür.
class KilYuzey extends StatelessWidget {
  const KilYuzey({
    super.key,
    required this.yukseklik,
    this.kose = Olcu.kareKose,
    this.renk = Renk.zemin,
    this.bulaniklik = 2,
    this.child,
  });

  final double yukseklik;
  final double kose;
  final Color renk;

  /// Bulanıklık yarıçapı = |yukseklik| × bu katsayı (taslakta çoğunlukla 2,
  /// tahtanın çukurunda 2,5).
  final double bulaniklik;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: KilBoyaci(
      yukseklik: yukseklik,
      kose: kose,
      renk: renk,
      bulaniklik: bulaniklik,
    ),
    child: child,
  );
}

class KilBoyaci extends CustomPainter {
  const KilBoyaci({
    required this.yukseklik,
    required this.kose,
    required this.renk,
    required this.bulaniklik,
  });

  final double yukseklik;
  final double kose;
  final Color renk;
  final double bulaniklik;

  /// CSS'teki bulanıklık yarıçapı, Flutter'daki sigma'nın iki katı.
  static MaskFilter _bulanik(double yaricap) =>
      MaskFilter.blur(BlurStyle.normal, yaricap / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(kose),
    );
    final g = yukseklik;

    if (g > 0.05) {
      final mf = _bulanik(g * bulaniklik);
      canvas
        ..drawRRect(
          rr.shift(Offset(g, g)),
          Paint()
            ..color = Renk.golge
            ..maskFilter = mf,
        )
        ..drawRRect(
          rr.shift(Offset(-g, -g)),
          Paint()
            ..color = Renk.isik
            ..maskFilter = mf,
        );
    }

    canvas.drawRRect(rr, Paint()..color = renk);

    if (g < -0.05) {
      final m = -g;
      final mf = _bulanik(m * bulaniklik);
      final dis = Rect.fromLTWH(
        -size.width,
        -size.height,
        size.width * 3,
        size.height * 3,
      );
      Path delikli(Offset kayma) => Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(dis)
        ..addRRect(rr.shift(kayma));
      canvas
        ..save()
        ..clipRRect(rr)
        ..drawPath(
          delikli(Offset(m, m)),
          Paint()
            ..color = Renk.golge
            ..maskFilter = mf,
        )
        ..drawPath(
          delikli(Offset(-m, -m)),
          Paint()
            ..color = Renk.isik
            ..maskFilter = mf,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(KilBoyaci eski) =>
      eski.yukseklik != yukseklik ||
      eski.kose != kose ||
      eski.renk != renk ||
      eski.bulaniklik != bulaniklik;
}
