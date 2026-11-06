import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'tema.dart';

/// B12 — ses tek bir beyaz çizgi. İki ucu sabit, ortası en çok oynar.
/// [degerler] boşsa (hazır, duraklatıldı) hafifçe dalgalanan düz çizgi.
class SesCizgisi extends StatefulWidget {
  const SesCizgisi({super.key, required this.degerler, this.canli = false});

  /// Son seviyeler (0..1), en yenisi sonda.
  final List<double> degerler;
  final bool canli;

  /// Ekrandaki nokta sayısı (taslakta 40).
  static const nokta = 40;

  @override
  State<SesCizgisi> createState() => _SesCizgisiState();
}

class _SesCizgisiState extends State<SesCizgisi>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _faz = ValueNotifier(0.0);
  Duration _onceki = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((gecen) {
      final dt = (gecen - _onceki).inMicroseconds / 1e6;
      _onceki = gecen;
      // Taslak: kayıtta 70 ms'de .5, boşta 80 ms'de .15 radyan.
      _faz.value += dt * (widget.canli ? 7.1 : 1.9);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _faz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _CizgiBoyasi(widget.degerler, _faz),
      size: Size.infinite,
    ),
  );
}

class _CizgiBoyasi extends CustomPainter {
  _CizgiBoyasi(this.degerler, this.faz) : super(repaint: faz);

  final List<double> degerler;
  final ValueNotifier<double> faz;

  @override
  void paint(Canvas canvas, Size size) {
    const n = SesCizgisi.nokta;
    final son = degerler.length > n
        ? degerler.sublist(degerler.length - n)
        : degerler;
    final bos = son.isEmpty;
    final orta = size.height / 2;

    Offset nokta(int i) {
      final t = i / (n - 1);
      // Kısa kayıtta eksik noktalar sola (eski) doğru sessiz sayılır.
      final j = i - (n - son.length);
      final v = bos ? .04 : (j >= 0 ? son[j] : 0.0);
      final y =
          orta +
          v *
              size.height *
              .42 *
              math.sin(t * math.pi) *
              math.sin(i * 1.7 + faz.value);
      return Offset(t * size.width, y);
    }

    final yol = Path();
    var onceki = nokta(0);
    yol.moveTo(onceki.dx, onceki.dy);
    for (var i = 1; i < n; i++) {
      final p = nokta(i);
      final orta2 = Offset((onceki.dx + p.dx) / 2, (onceki.dy + p.dy) / 2);
      yol.quadraticBezierTo(onceki.dx, onceki.dy, orta2.dx, orta2.dy);
      onceki = p;
    }

    canvas
      ..drawPath(
        yol,
        Paint()
          ..color = Renk.lilaBeyaz.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        yol,
        Paint()
          ..color = Renk.lilaBeyaz
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_CizgiBoyasi eski) => eski.degerler != degerler;
}
