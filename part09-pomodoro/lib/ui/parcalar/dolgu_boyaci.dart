import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tema.dart';

/// Kıvrımlı kenar O6 (PLAN B2.4): genlik 4,5 px, dalga boyu 26 px.
const kenarGenlik = 4.5;
const kenarDalgaBoyu = 26.0;

/// Faz hızı, radyan / ms.
const kenarHiz = 0.005;

/// Rakamın üst kenarı, ekran yüksekliğinin oranı.
const rakamKonumu = 0.33;

/// Dolgunun bir karesi: seviye 0 (boş) – 1 (dolu), kenarın fazı.
class DolguKaresi {
  const DolguKaresi({required this.seviye, required this.dalga});
  final double seviye;
  final double dalga;
}

/// Dolgunun üst kenarı: sinüs. `ClipPath` ve boyama aynı yolu kullanır.
Path dolguYolu(Size s, DolguKaresi k) {
  final y0 = s.height * (1 - k.seviye);
  final yol = Path()..moveTo(0, s.height);
  for (double x = 0; x <= s.width + 5; x += 5) {
    final y =
        y0 + kenarGenlik * math.sin(x * 2 * math.pi / kenarDalgaBoyu + k.dalga);
    yol.lineTo(x, y);
  }
  yol
    ..lineTo(s.width, s.height)
    ..close();
  return yol;
}

/// "Dolan ekran" (PLAN B2): zemin rakamı, dolgu ve dolgunun içindeki beyaz
/// rakam. Aynı yazı iki katmanda çizilir, üstteki dolgunun şekliyle kırpılır.
class DolguBoyaci extends CustomPainter {
  DolguBoyaci({
    required this.kare,
    required this.renk,
    required this.metin,
    required this.nefes,
  }) : super(repaint: Listenable.merge([kare, nefes]));

  final ValueListenable<DolguKaresi> kare;
  final Color renk;
  final String metin;

  /// Duraklatılmışken nabız: 0 → 1 → 0 (PLAN B2.4).
  final ValueListenable<double> nefes;

  // Yazı saniyede bir değişir; her karede yeniden ölçülmez.
  late final _zeminYazi = _yazi(Renk.yazi);
  late final _dolguYazi = _yazi(Renk.dolguYazi);

  TextPainter _yazi(Color c) => TextPainter(
    text: TextSpan(
      text: metin,
      style: Yazi.rakam.copyWith(color: c),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final yol = dolguYolu(size, kare.value);
    final n = nefes.value;
    final olcek = 1 - 0.03 * n;
    final opaklik = 1 - 0.28 * n;

    void rakam(TextPainter tp) {
      final merkez = Offset(
        size.width / 2,
        size.height * rakamKonumu + tp.height / 2,
      );
      canvas
        ..save()
        ..translate(merkez.dx, merkez.dy)
        ..scale(olcek)
        ..translate(-tp.width / 2, -tp.height / 2);
      if (opaklik < 1) {
        canvas.saveLayer(
          Offset.zero & tp.size,
          Paint()..color = Color.fromRGBO(0, 0, 0, opaklik),
        );
      }
      tp.paint(canvas, Offset.zero);
      if (opaklik < 1) canvas.restore();
      canvas.restore();
    }

    rakam(_zeminYazi);
    canvas
      ..save()
      ..clipPath(yol);
    canvas.drawRect(Offset.zero & size, Paint()..color = renk);
    rakam(_dolguYazi);
    canvas.restore();
  }

  @override
  bool shouldRepaint(DolguBoyaci old) =>
      old.renk != renk || old.metin != metin || old.kare != kare;
}
