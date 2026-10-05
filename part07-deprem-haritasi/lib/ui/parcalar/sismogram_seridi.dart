import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../deprem/deprem.dart';
import '../../deprem/sismogram.dart';
import '../../deprem/zaman_metni.dart';
import '../tema.dart';

/// Ekranın alt kısmındaki sismograf kâğıdı (katalog U1 + C7).
///
/// Ortadaki mor çizgi [oynatT] anını gösterir; kâğıt sola-sağa sürüklenince
/// zaman geri-ileri gider. Çizim her karede yeniden yapılıyor ama yalnız bu
/// şeridin içinde (`RepaintBoundary`), harita etkilenmiyor.
class SismogramSeridi extends StatelessWidget {
  const SismogramSeridi({
    super.key,
    required this.olaylar,
    required this.oynatT,
    required this.yukseklik,
    required this.altBosluk,
    required this.onBasla,
    required this.onSurukle,
    required this.onBitti,
  });

  final List<Deprem> olaylar;
  final ValueListenable<double> oynatT;
  final double yukseklik;
  final double altBosluk;
  final VoidCallback onBasla;
  final ValueChanged<double> onSurukle;
  final VoidCallback onBitti;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sismogram şeridi. Sola ya da sağa sürükleyerek zamanda gezin.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onBasla(),
        onHorizontalDragUpdate: (d) => onSurukle(d.delta.dx),
        onHorizontalDragEnd: (_) => onBitti(),
        onHorizontalDragCancel: onBitti,
        child: SizedBox(
          height: yukseklik,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: altBosluk,
                child: RepaintBoundary(
                  child: CustomPaint(painter: SismogramCizici(olaylar, oynatT)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8 + altBosluk,
                child: Text(
                  '← sürükle · zamanda gez →',
                  textAlign: TextAlign.center,
                  style: Yazi.ipucu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SismogramCizici extends CustomPainter {
  SismogramCizici(this.olaylar, this.oynatT) : super(repaint: oynatT);

  final List<Deprem> olaylar;
  final ValueListenable<double> oynatT;

  static const _altPay = 26.0; // saat etiketleri + ipucu için
  static const _altiSaat = 6 * Sismogram.saatMs;

  final _dalga = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeJoin = StrokeJoin.round
    ..color = Renk.murekkep;
  final _izgara = Paint()
    ..strokeWidth = 1
    ..color = Renk.izgara;
  final _cizgi = Paint()
    ..strokeWidth = 2
    ..color = Renk.mor;

  void _yaz(Canvas c, String s, TextStyle st, double ortaX, double ustY) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(ortaX - tp.width / 2, ustY));
  }

  @override
  void paint(Canvas c, Size s) {
    final t = oynatT.value;
    final w = s.width, h = s.height;
    final orta = h * .52;
    final sol = t - (w / 2) / Sismogram.dpSaat * Sismogram.saatMs;
    final sag = sol + w / Sismogram.dpSaat * Sismogram.saatMs;

    // 6 saatlik ızgara + yerel saat etiketi (UTC 6'nın katlarına hizalı:
    // Türkiye'de 03 · 09 · 15 · 21).
    for (
      var g = (sol / _altiSaat).ceil() * _altiSaat;
      g < sag;
      g += _altiSaat
    ) {
      final x = (g - sol) / Sismogram.saatMs * Sismogram.dpSaat;
      c.drawLine(Offset(x, 14), Offset(x, h - _altPay), _izgara);
      final yerel = DateTime.fromMillisecondsSinceEpoch(g.round());
      _yaz(c, ZamanMetni.saat(yerel), Yazi.saatEtiketi, x, h - _altPay - 4);
    }

    // Dalga: her piksel sütunu bir an; genlik o ana yakın depremlerden.
    final yol = Path();
    final tavan = orta - 8;
    for (var px = 0; px <= w; px++) {
      final tt = sol + px / Sismogram.dpSaat * Sismogram.saatMs;
      final a = Sismogram.genlik(olaylar, tt);
      final y = orta + (a < tavan ? a : tavan) * Sismogram.isaret(tt);
      px == 0 ? yol.moveTo(0, y) : yol.lineTo(px.toDouble(), y);
    }
    c.drawPath(yol, _dalga);

    // Oynatma çizgisi + anın tarihi.
    c.drawLine(Offset(w / 2, 18), Offset(w / 2, h - _altPay), _cizgi);
    final yerel = DateTime.fromMillisecondsSinceEpoch(t.round());
    _yaz(c, ZamanMetni.tarihSaat(yerel), Yazi.cizgiTarihi, w / 2, 2);
  }

  @override
  bool shouldRepaint(SismogramCizici eski) => eski.olaylar != olaylar;
}
