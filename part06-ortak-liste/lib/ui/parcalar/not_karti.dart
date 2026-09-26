import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../liste/bas_harf.dart';
import '../../liste/urun.dart';
import '../tema.dart';
import 'karo.dart';

/// Her notun hafif eğikliği, derece. ±3.6° arası, ürün kimliğinden türetilir
/// (taslak: `((i*37)%9 − 4) × 0.9`). Kimlikten türediği için not yer
/// değiştirse de, uygulama kapanıp açılsa da açısı aynı kalır.
double notAcisi(String id) {
  final toplam = id.codeUnits.fold<int>(0, (a, b) => a + b);
  return ((toplam * 37) % 9 - 4) * 0.9;
}

/// Buzdolabına yapışık not: krem kart + tepesinde baş harf karosu.
///
/// Üç hareket (PLAN.md B2.4):
/// - giriş: yukarıdan düşer, yaylanarak oturur (750 ms)
/// - işaret: kart eğilip küçülür ve solar, karo düz aşağı kayar (450 ms)
/// - çizgi: kiraz çizgi adın üstünden soldan sağa çekilir (350 ms)
class NotKarti extends StatefulWidget {
  const NotKarti({
    super.key,
    required this.urun,
    required this.benEkledim,
    required this.girisZamani,
    required this.onTap,
    required this.onLongPress,
  });

  final Urun urun;
  final bool benEkledim;

  /// Düşme animasyonunun başlayacağı an. Geçmişte kaldıysa kart olduğu yerde
  /// çizilir — kart yer değiştirip yeniden kurulduğunda tekrar düşmesin diye.
  final DateTime girisZamani;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<NotKarti> createState() => _NotKartiState();
}

class _NotKartiState extends State<NotKarti> with TickerProviderStateMixin {
  static const _girisSuresi = Duration(milliseconds: 750);

  late final AnimationController _giris = AnimationController(
    vsync: this,
    duration: _girisSuresi,
  );
  late final AnimationController _isaret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.urun.alindi ? 1 : 0,
  );
  late final AnimationController _cizgi = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: widget.urun.alindi ? 1 : 0,
  );
  Timer? _bekleme;

  @override
  void initState() {
    super.initState();
    final kalan = widget.girisZamani.difference(DateTime.now());
    final gecen = -kalan.inMilliseconds;
    if (gecen >= _girisSuresi.inMilliseconds) {
      _giris.value = 1;
    } else if (kalan > Duration.zero) {
      _bekleme = Timer(kalan, _giris.forward);
    } else {
      _giris.forward(from: gecen / _girisSuresi.inMilliseconds);
    }
  }

  @override
  void didUpdateWidget(NotKarti eski) {
    super.didUpdateWidget(eski);
    if (eski.urun.alindi != widget.urun.alindi) {
      final hedef = widget.urun.alindi ? 1.0 : 0.0;
      _isaret.animateTo(hedef);
      _cizgi.animateTo(hedef);
    }
  }

  @override
  void dispose() {
    _bekleme?.cancel();
    _giris.dispose();
    _isaret.dispose();
    _cizgi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aci = notAcisi(widget.urun.id);
    return Semantics(
      button: true,
      label: '${widget.urun.ad}${widget.urun.alindi ? ', alındı' : ''}',
      hint: 'Dokun: işaretle. Basılı tut: sil.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: Listenable.merge([_giris, _isaret]),
          builder: (context, cocuk) {
            final g = yay.transform(_giris.value); // yay 1'i aşabilir
            final i = yay.transform(_isaret.value);
            final dinlenmeAcisi = lerpDouble(aci, aci * -3, i)!;
            final derece = lerpDouble(20, dinlenmeAcisi, g)!;
            final olcek = lerpDouble(1.1, 1, g)! * lerpDouble(1, 0.9, i)!;
            final saydamlik =
                _giris.value.clamp(0.0, 1.0) * (1 - 0.5 * _isaret.value);
            return Opacity(
              opacity: saydamlik.clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translateByDouble(0, -70 * (1 - g), 0, 1)
                  ..rotateZ(derece * math.pi / 180)
                  ..scaleByDouble(olcek, olcek, 1, 1),
                child: cocuk,
              ),
            );
          },
          child: _kart(),
        ),
      ),
    );
  }

  Widget _kart() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
          decoration: BoxDecoration(
            color: Renk.krem,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000), // .35
                offset: Offset(0, 7),
                blurRadius: 10,
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CizgiliAd(ad: widget.urun.ad, cizgi: _cizgi),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: _KimNoktasi(dolu: widget.benEkledim),
              ),
            ],
          ),
        ),
        Positioned(
          top: -12,
          left: 10,
          child: AnimatedBuilder(
            animation: _isaret,
            builder: (context, karo) {
              final i = yay.transform(_isaret.value);
              return Opacity(
                opacity: (1 - 0.2 * _isaret.value).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 6 * i),
                  child: karo,
                ),
              );
            },
            child: Karo(basHarf(widget.urun.ad)),
          ),
        ),
      ],
    );
  }
}

class _CizgiliAd extends StatelessWidget {
  const _CizgiliAd({required this.ad, required this.cizgi});

  final String ad;
  final Animation<double> cizgi;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CizgiBoyaci(
        CurvedAnimation(parent: cizgi, curve: cizgiEgrisi),
      ),
      child: Text(
        ad,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: Yazi.el,
          fontSize: 16,
          height: 1.15,
          color: Renk.murekkep,
        ),
      ),
    );
  }
}

/// Adın %52 yüksekliğinden geçen 2 dp kiraz çizgi, soldan sağa uzar.
class _CizgiBoyaci extends CustomPainter {
  _CizgiBoyaci(this.ilerleme) : super(repaint: ilerleme);

  final Animation<double> ilerleme;

  @override
  void paint(Canvas canvas, Size size) {
    if (ilerleme.value <= 0) return;
    final y = size.height * 0.52;
    final bas = -2.0;
    final son = bas + (size.width + 4) * ilerleme.value;
    canvas.drawLine(
      Offset(bas, y),
      Offset(son, y),
      Paint()
        ..color = Renk.kiraz
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CizgiBoyaci eski) => eski.ilerleme != ilerleme;
}

/// Kim ekledi: renk değil ŞEKİL. Dolu = ben, boş halka = öbür üye.
class _KimNoktasi extends StatelessWidget {
  const _KimNoktasi({required this.dolu});

  final bool dolu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dolu ? Renk.murekkep : null,
        border: Border.all(color: Renk.murekkep, width: 1.5),
      ),
    );
  }
}
