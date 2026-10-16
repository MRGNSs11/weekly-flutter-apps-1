import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../oyun/kurallar.dart' show Yon;
import '../oyun/oyun_notifier.dart';
import 'katman.dart';
import 'parcalar.dart';
import 'tahta.dart';
import 'tema.dart';

/// Tek ekran: skorlar, tahta, düğmeler. Kaydırma algısı, tahtanın eğimi,
/// geri sarma efekti ve katmanın zamanlaması burada.
class OyunEkrani extends ConsumerStatefulWidget {
  const OyunEkrani({super.key});

  static const tahtaAnahtari = ValueKey('tahta');
  static const skorAnahtari = ValueKey('skor');

  @override
  ConsumerState<OyunEkrani> createState() => _OyunEkraniState();
}

class _OyunEkraniState extends ConsumerState<OyunEkrani>
    with TickerProviderStateMixin {
  /// Kaydırmanın hamle sayılması için en az yol (taslak: 24 px).
  static const kaydirmaEsigi = 24.0;

  late final AnimationController _egim = AnimationController(
    vsync: this,
    duration: Sure.egim,
  );
  late final AnimationController _geri = AnimationController(
    vsync: this,
    duration: Sure.geriSarma,
  );
  Yon _egimYonu = Yon.sol;
  double _egimDerece = 7;

  Offset _surukleme = Offset.zero;
  Katman _gorunenKatman = Katman.yok;
  Timer? _katmanZamani;

  bool get _azHareket => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _gorunenKatman = ref.read(oyunProvider).katman;
  }

  @override
  void dispose() {
    _katmanZamani?.cancel();
    _egim.dispose();
    _geri.dispose();
    super.dispose();
  }

  void _egil(Yon yon, double derece) {
    if (_azHareket) return;
    _egimYonu = yon;
    _egimDerece = derece;
    _egim.forward(from: 0);
  }

  void _olayaTepki(Oyun o) {
    if (o.olay == Olay.hamle) _egil(o.sonHamle!.yon, 7);
    if (o.olay == Olay.geriAl && !_azHareket) _geri.forward(from: 0);

    _katmanZamani?.cancel();
    if (o.katman == Katman.yok) {
      setState(() => _gorunenKatman = Katman.yok);
      return;
    }
    // Katman, tahtadaki sahne (2048 ya da kurşunlaşma) bitince açılır.
    final bekle = _azHareket
        ? const Duration(milliseconds: 300)
        : o.katman == Katman.kazandi
        ? Sure.kayma + Sure.zirveKatman
        : Sure.kayma +
              Sure.kursunBaslangic +
              Duration(
                milliseconds: (o.durum.kareler.length - 1) * Sure.kursunAdim,
              ) +
              Sure.kursun +
              Sure.kursunKatman;
    _katmanZamani = Timer(bekle, () {
      if (mounted) setState(() => _gorunenKatman = o.katman);
    });
  }

  void _kaydirmaBitti() {
    final d = _surukleme;
    _surukleme = Offset.zero;
    if (d.distance < kaydirmaEsigi) return;
    final yon = d.dx.abs() > d.dy.abs()
        ? (d.dx > 0 ? Yon.sag : Yon.sol)
        : (d.dy > 0 ? Yon.asagi : Yon.yukari);
    final oyun = ref.read(oyunProvider);
    if (oyun.katman != Katman.yok) return;
    if (!ref.read(oyunProvider.notifier).kaydir(yon)) _egil(yon, 3);
  }

  /// Tahtanın eğimi: 90 ms'de yatar, kalan sürede yaylanarak düzelir.
  Matrix4 _egimMatrisi() {
    final t = _egim.value;
    if (t == 0 || t == 1) return Matrix4.identity();
    const yatma = 90 / 470;
    final oran = t < yatma
        ? t / yatma
        : 1 - Curves.easeOutBack.transform((t - yatma) / (1 - yatma));
    final aci = _egimDerece * math.pi / 180 * oran;
    // Parmağın gittiği kenar aşağı basılır, karşı kenar kalkar.
    final m = Matrix4.identity()..setEntry(3, 2, 1 / 700);
    switch (_egimYonu) {
      case Yon.sol:
        m.rotateY(aci);
      case Yon.sag:
        m.rotateY(-aci);
      case Yon.yukari:
        m.rotateX(-aci);
      case Yon.asagi:
        m.rotateX(aci);
    }
    return m;
  }

  Widget _geriSarmaEfekti(Widget tahta) {
    return AnimatedBuilder(
      animation: _geri,
      child: tahta,
      builder: (context, child) {
        if (!_geri.isAnimating) return child!;
        final t = _geri.value; // 650 ms
        final gri = (1 - t * 650 / 450).clamp(0.0, 1.0); // ilk 450 ms
        final isaretOpak = t < 0.3
            ? t / 0.3 * 0.75
            : 0.75 * (1 - (t - 0.3) / 0.7);
        final isaretAci = t < 0.3
            ? lerpDouble(40, 0, t / 0.3)!
            : lerpDouble(0, -20, (t - 0.3) / 0.7)!;
        return Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 0.75 * gri,
                sigmaY: 0.75 * gri,
              ),
              child: ColorFiltered(
                colorFilter: _doygunluk(1 - gri),
                child: child,
              ),
            ),
            IgnorePointer(
              child: Transform.rotate(
                angle: isaretAci * math.pi / 180,
                child: Icon(
                  Icons.undo_rounded,
                  size: 120,
                  color: Renk.soluk.withValues(alpha: isaretOpak),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// s = 1 renkli, s = 0 gri.
  static ColorFilter _doygunluk(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return ColorFilter.matrix([
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final oyun = ref.watch(oyunProvider);
    final n = ref.read(oyunProvider.notifier);
    ref.listen(oyunProvider, (onceki, simdi) {
      if (onceki?.olaySayaci != simdi.olaySayaci) _olayaTepki(simdi);
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _surukleme = Offset.zero,
              onPanUpdate: (d) => _surukleme += d.delta,
              onPanEnd: (_) => _kaydirmaBitti(),
              child: LayoutBuilder(
                builder: (context, kutu) {
                  // Tahta genişliğe göre ölçeklenir; kısa ekranda yüksekliğe sığar.
                  final genislik = math.min(kutu.maxWidth - 40, 380.0);
                  final boy = math.min(genislik, kutu.maxHeight - 300);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SkorKutusu(
                                etiket: 'SKOR',
                                deger: oyun.durum.skor,
                                degerAnahtari: OyunEkrani.skorAnahtari,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SkorKutusu(
                                etiket: 'EN İYİ',
                                deger: oyun.enIyi,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('2 0 4 8', style: Yazi.baslik),
                        const SizedBox(height: 14),
                        SizedBox.square(
                          dimension: boy,
                          child: FittedBox(
                            child: AnimatedBuilder(
                              animation: _egim,
                              builder: (context, child) => Transform(
                                alignment: Alignment.center,
                                transform: _egimMatrisi(),
                                child: child,
                              ),
                              child: _geriSarmaEfekti(
                                Tahta(
                                  key: OyunEkrani.tahtaAnahtari,
                                  oyun: oyun,
                                  azHareket: _azHareket,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: KilDugme(
                                yazi: 'Geri al',
                                ikon: Icons.undo_rounded,
                                onTap:
                                    oyun.geriAlinabilir &&
                                        _gorunenKatman == Katman.yok
                                    ? n.geriAl
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: KilDugme(
                                yazi: 'Yeni oyun',
                                onTap: n.yeniOyun,
                                vurgulu: true,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Kaydır · tahta parmağını izler',
                          style: Yazi.ipucu,
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_gorunenKatman != Katman.yok)
              Positioned.fill(
                child: OyunKatmani(
                  tur: _gorunenKatman,
                  skor: oyun.durum.skor,
                  devamEt: n.devamEt,
                  geriAl: n.geriAl,
                  yeniOyun: n.yeniOyun,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
