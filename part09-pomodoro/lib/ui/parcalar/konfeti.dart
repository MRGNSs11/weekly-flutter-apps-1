import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tema.dart';

class _Parca {
  _Parca({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.renk,
    required this.don,
    required this.vd,
    required this.omur,
    required this.g,
  });

  double x, y, vx, vy, don;
  final double r, vd, omur, g;
  final Color renk;
  double yas = 0;
}

/// Pomodoro bitince parçacık; 4/4'te konfeti (PLAN B2.4, taslak `kutla`).
/// Hızlar px/ms, taslaktaki değerler.
class KonfetiKontrol extends ChangeNotifier {
  KonfetiKontrol(TickerProvider vsync) {
    _ticker = vsync.createTicker(_kare);
  }

  late final Ticker _ticker;
  final _parcalar = <_Parca>[];
  final _rnd = math.Random();
  Duration _onceki = Duration.zero;

  bool get bos => _parcalar.isEmpty;

  /// Küçük: [kaynak] noktasından 16 parçacık. Büyük: alttan 90 konfeti.
  void patlat({required Offset kaynak, required bool buyuk, Size? ekran}) {
    const renkler = [Renk.vurgu, Renk.mola, Renk.yazi, Renk.konfetiSari];
    final adet = buyuk ? 90 : 16;
    final o = buyuk && ekran != null
        ? Offset(ekran.width / 2, ekran.height * 470 / 640)
        : kaynak;
    for (var i = 0; i < adet; i++) {
      final a = buyuk
          ? -math.pi / 2 + (_rnd.nextDouble() - 0.5) * 1.6
          : _rnd.nextDouble() * math.pi * 2;
      final h = buyuk
          ? 0.5 + _rnd.nextDouble() * 0.55
          : 0.08 + _rnd.nextDouble() * 0.12;
      _parcalar.add(
        _Parca(
          x: o.dx,
          y: o.dy,
          vx: math.cos(a) * h,
          vy: math.sin(a) * h,
          r: buyuk ? 3 + _rnd.nextDouble() * 3 : 2 + _rnd.nextDouble() * 1.5,
          renk: renkler[i % renkler.length],
          don: _rnd.nextDouble() * 6,
          vd: (_rnd.nextDouble() - 0.5) * 0.02,
          omur: buyuk ? 1800 : 600,
          g: buyuk ? 0.0009 : 0.0002,
        ),
      );
    }
    if (!_ticker.isActive) {
      _onceki = Duration.zero;
      _ticker.start();
    }
  }

  void _kare(Duration gecen) {
    final dt = math.min(64.0, (gecen - _onceki).inMicroseconds / 1000);
    _onceki = gecen;
    _parcalar.removeWhere((p) {
      p
        ..yas += dt
        ..vy += p.g * dt
        ..x += p.vx * dt
        ..y += p.vy * dt
        ..don += p.vd * dt;
      return p.yas > p.omur;
    });
    if (_parcalar.isEmpty) _ticker.stop();
    notifyListeners();
  }

  void boya(Canvas c) {
    for (final p in _parcalar) {
      final alfa = (1 - p.yas / p.omur).clamp(0.0, 1.0);
      c
        ..save()
        ..translate(p.x, p.y)
        ..rotate(p.don);
      c.drawRect(
        Rect.fromLTWH(-p.r, -p.r * 0.6, p.r * 2, p.r * 1.2),
        Paint()..color = p.renk.withValues(alpha: alfa),
      );
      c.restore();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class KonfetiBoyaci extends CustomPainter {
  KonfetiBoyaci(this.k) : super(repaint: k);
  final KonfetiKontrol k;

  @override
  void paint(Canvas canvas, Size size) => k.boya(canvas);

  @override
  bool shouldRepaint(KonfetiBoyaci old) => old.k != k;
}
