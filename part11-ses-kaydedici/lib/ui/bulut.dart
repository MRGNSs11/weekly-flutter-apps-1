import 'package:flutter/material.dart';

import 'tema.dart';

/// T7 — akan mor bulut. Paket yok: üç radyal gradyan, taslaktaki CSS'in
/// aynısı (%140 boyutlu zemin, konumu 0 → %100 ileri-geri kayar).
/// [hizli]: kayıtta 12 sn yerine 3 sn, doygunluk ×1,25, parlaklık ×1,1.
class Bulut extends StatefulWidget {
  const Bulut({super.key, this.hizli = false});

  final bool hizli;

  @override
  State<Bulut> createState() => _BulutState();
}

class _BulutState extends State<Bulut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _sure,
  )..repeat(reverse: true);

  Duration get _sure => Duration(seconds: widget.hizli ? 3 : 12);

  @override
  void didUpdateWidget(Bulut eski) {
    super.didUpdateWidget(eski);
    if (eski.hizli != widget.hizli) {
      _c
        ..duration = _sure
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boya = RepaintBoundary(
      child: CustomPaint(
        painter: _BulutBoyasi(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        ),
        size: Size.infinite,
      ),
    );
    if (!widget.hizli) return boya;
    return ColorFiltered(colorFilter: _parlak, child: boya);
  }
}

/// CSS `filter: saturate(1.25) brightness(1.1)`.
final _parlak = ColorFilter.matrix(_doygunluk(1.25, 1.1));

List<double> _doygunluk(double s, double p) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final a = 1 - s;
  return [
    (r * a + s) * p, g * a * p, b * a * p, 0, 0, //
    r * a * p, (g * a + s) * p, b * a * p, 0, 0, //
    r * a * p, g * a * p, (b * a + s) * p, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

class _BulutBoyasi extends CustomPainter {
  _BulutBoyasi(this.t) : super(repaint: t);

  final Animation<double> t;

  // (merkez x, merkez y, yarıçap x, yarıçap y, renk) — zemin görseline göre.
  static const _lekeler = [
    (.20, .25, .60, .50, Renk.bulut1),
    (.85, .40, .55, .45, Renk.bulut2),
    (.40, .90, .70, .55, Renk.bulut3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Renk.bulutTaban);
    final zemin = Size(size.width * 1.4, size.height * 1.4);
    final kayma = Offset(-.4 * size.width, -.4 * size.height) * t.value;
    for (final (x, y, rx, ry, renk) in _lekeler) {
      final merkez = kayma + Offset(x * zemin.width, y * zemin.height);
      canvas
        ..save()
        ..translate(merkez.dx, merkez.dy)
        ..scale(rx * zemin.width, ry * zemin.height)
        ..drawCircle(
          Offset.zero,
          1,
          Paint()
            ..shader = RadialGradient(
              colors: [renk, renk.withValues(alpha: 0)],
              stops: const [0, .7],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BulutBoyasi eski) => false;
}
