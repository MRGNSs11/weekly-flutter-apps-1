import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../uygulama/rehber_kontrol.dart';
import 'tema.dart';

/// G7: ekran kararır, hedef ışıkta kalır, el hareketi gösterir, balonda
/// açıklama. Bütün dokunuşları yutar: hedefe ya da "Sonraki"ye basmak ilerletir.
class RehberKatmani extends StatefulWidget {
  const RehberKatmani({super.key, required this.rehber});
  final RehberKontrol rehber;

  @override
  State<RehberKatmani> createState() => _RehberKatmaniState();
}

class _RehberKatmaniState extends State<RehberKatmani>
    with SingleTickerProviderStateMixin {
  late final _hareket = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  Rect? _hedef;

  @override
  void initState() {
    super.initState();
    _olc();
  }

  @override
  void didUpdateWidget(RehberKatmani eski) {
    super.didUpdateWidget(eski);
    _olc();
  }

  /// Hedef ekranda yerleşene kadar her karede dener (sayfa geçişi sürerken
  /// konum değişir).
  void _olc() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.rehber.aktif) return;
      final kutu =
          widget.rehber.adim
                  .hedef(widget.rehber.hedefler)
                  .currentContext
                  ?.findRenderObject()
              as RenderBox?;
      final benim = context.findRenderObject() as RenderBox?;
      Rect? yeni;
      if (kutu != null && kutu.hasSize && benim != null && kutu.attached) {
        final sol = benim.globalToLocal(kutu.localToGlobal(Offset.zero));
        yeni = sol & kutu.size;
      }
      if (yeni != _hedef) setState(() => _hedef = yeni);
      _olc();
    });
  }

  @override
  void dispose() {
    _hareket.dispose();
    super.dispose();
  }

  void _ileri() {
    HapticFeedback.selectionClick();
    widget.rehber.ileri();
  }

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final a = widget.rehber.adim;
    final h = _hedef;
    final boyut = MediaQuery.sizeOf(context);
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    final isik = h?.inflate(6);
    final ustte = h != null && h.center.dy > boyut.height / 2;

    return Stack(
      children: [
        // Karartma + ışık deliği; her dokunuş yutulur.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              if (isik != null && isik.contains(d.localPosition)) _ileri();
            },
            child: AnimatedBuilder(
              animation: _hareket,
              builder: (context, _) => CustomPaint(
                painter: _Isik(isik, hareketsiz ? 0 : _hareket.value),
              ),
            ),
          ),
        ),
        if (h != null)
          AnimatedBuilder(
            animation: _hareket,
            builder: (context, _) {
              final t = hareketsiz ? 0.0 : _hareket.value;
              final bas = a.hareket == RehberHareketi.basiliTut
                  ? (t > .15 && t < .8)
                  : (t > .55 && t < .7);
              return Positioned(
                left: (h.center.dx + 6).clamp(0, boyut.width - 48),
                top: h.center.dy + (h.height / 2).clamp(0, 18) - 6,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: bas ? .82 : 1,
                    child: Icon(
                      Icons.touch_app_rounded,
                      size: 44,
                      // Aydınlıkta koyu, karanlıkta açık: kartın üstünde görünsün.
                      color: r.metin,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: r.zemin.first.withValues(alpha: .9),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (h != null)
          Positioned(
            left: 16,
            right: 16,
            top: ustte ? null : h.bottom + 34,
            bottom: ustte ? boyut.height - h.top + 34 : null,
            child: Material(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF1B2A40),
              borderRadius: BorderRadius.circular(18),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      a.baslik,
                      style: yazi(16, kalinlik: FontWeight.w700, renk: r.metin),
                    ),
                    const SizedBox(height: 4),
                    Text(a.metin, style: yazi(13.5, renk: r.metin, satir: 1.4)),
                    Row(
                      children: [
                        Text(
                          '${widget.rehber.adimNo + 1} / ${rehberAdimlari.length}',
                          style: yazi(12, renk: r.soluk),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.rehber.bitir,
                          child: Text('Atla', style: yazi(13, renk: r.soluk)),
                        ),
                        TextButton(
                          onPressed: _ileri,
                          child: Text(
                            widget.rehber.adimNo + 1 < rehberAdimlari.length
                                ? 'Sonraki →'
                                : 'Bitir ✓',
                            style: yazi(
                              13,
                              kalinlik: FontWeight.w700,
                              renk: r.vurgu,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Isik extends CustomPainter {
  _Isik(this.isik, this.t);
  final Rect? isik;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final karanlik = Path()..addRect(Offset.zero & s);
    if (isik == null) {
      c.drawPath(karanlik, Paint()..color = const Color(0xAD09101E));
      return;
    }
    final delik = RRect.fromRectAndRadius(isik!, const Radius.circular(18));
    c.drawPath(
      Path.combine(PathOperation.difference, karanlik, Path()..addRRect(delik)),
      Paint()..color = const Color(0xAD09101E),
    );
    // Dışa doğru sönen nabız halkası
    final n = (t * 1.25).clamp(0.0, 1.0);
    c.drawRRect(
      delik.inflate(2 + n * 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: (1 - n) * .9),
    );
  }

  @override
  bool shouldRepaint(_Isik eski) => eski.isik != isik || eski.t != t;
}
