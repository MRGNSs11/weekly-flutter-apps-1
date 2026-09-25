import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'su_fizigi.dart';

/// Su sahnesini çizer. `tasarimlar.html` → `CIZ.cam` + `efektCiz` birebir.
class SuBoyaci extends CustomPainter {
  SuBoyaci(this.fizik, {required Listenable kare}) : super(repaint: kare);

  final SuFizigi fizik;

  static const _halkaRengi = Color(0x99FFFFFF); // beyaz %60

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = fizik.taban;
    final f = fizik.faz;
    final tumAlan = Offset.zero & size;

    // Su üstü: dikey geçiş.
    canvas.drawRect(
      tumAlan,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Renk.bgUst, Renk.bgAlt],
        ).createShader(tumAlan),
    );

    // Arka dalga: 6 px yukarıda, 1.2 kat hızlı.
    canvas.drawPath(
      _dalga(w, h, t - 6, 6, 130, f * 1.2 + 1),
      Paint()..color = Renk.arkaDalga,
    );

    // Ön dalga: yüzeyden dibe koyulaşan su.
    final on = _dalga(w, h, t, 7, 170, f);
    canvas.drawPath(
      on,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Renk.suUst, Renk.suAlt],
        ).createShader(Rect.fromLTRB(0, t, w, h)),
    );

    // Kabarcıklar yalnız suyun içinde.
    canvas.save();
    canvas.clipPath(on);
    final kabarcikKalem = Paint()
      ..color = Renk.kabarcik
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final b in fizik.kabarciklar) {
      final by = t + (h - t) * b.y;
      final bx = b.x * w + math.sin(f * 2 + b.y * 9) * 3;
      canvas.drawCircle(Offset(bx, by), b.r, kabarcikKalem);
    }
    canvas.restore();

    _efektler(canvas, w, h, t);
  }

  void _efektler(Canvas canvas, double w, double h, double t) {
    // Dokunma halkaları: düz (dalgasız) yüzeyin altında kalır.
    canvas.save();
    canvas.clipPath(_dalga(w, h, t, 0, 999, 0));
    for (final hk in fizik.halkalar) {
      if (hk.yuzey) continue;
      final kalem = Paint()
        ..color = _halkaRengi.withValues(alpha: _halkaRengi.a * hk.a)
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(hk.x, hk.y), hk.r, kalem..strokeWidth = 2);
      canvas.drawCircle(Offset(hk.x, hk.y), hk.r * .6, kalem..strokeWidth = 1);
    }
    canvas.restore();

    // Damla taslağın 1.5 katı ve ince koyu çerçeveli (PLAN.md B2.5/7):
    // açık gökyüzünde beyaz damla seçilmiyordu. Ucu yine d.y'nin 13×1.5 üstünde.
    const k = 1.5;
    final damlaBoya = Paint()..color = Renk.damla;
    final damlaCizgi = Paint()
      ..color = Renk.damlaCizgi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final d in fizik.damlalar) {
      final yol = Path()
        ..moveTo(d.x, d.y - 13 * k)
        ..cubicTo(
          d.x + 7 * k,
          d.y - 3 * k,
          d.x + 6 * k,
          d.y + 6 * k,
          d.x,
          d.y + 6 * k,
        )
        ..cubicTo(
          d.x - 6 * k,
          d.y + 6 * k,
          d.x - 7 * k,
          d.y - 3 * k,
          d.x,
          d.y - 13 * k,
        );
      canvas.drawPath(yol, damlaBoya);
      canvas.drawPath(yol, damlaCizgi);
    }
    for (final p in fizik.sicrama) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        2.4,
        Paint()..color = Renk.damla.withValues(alpha: p.omur.clamp(0.0, 1.0)),
      );
    }
  }

  Path _dalga(
    double w,
    double h,
    double y,
    double genlik,
    double boy,
    double f,
  ) {
    final yol = Path()..moveTo(-10, h + 10);
    for (double px = -10; px <= w + 10; px += 3) {
      yol.lineTo(px, fizik.yuzeyY(px, y, genlik, boy, f));
    }
    return yol
      ..lineTo(w + 10, h + 10)
      ..close();
  }

  @override
  bool shouldRepaint(SuBoyaci old) => old.fizik != fizik;
}
