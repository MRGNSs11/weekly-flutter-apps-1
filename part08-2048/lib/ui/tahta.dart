import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../oyun/kare.dart';
import '../oyun/oyun_notifier.dart';
import 'kare_widget.dart';
import 'kil_yuzey.dart';
import 'tema.dart';

/// Tahtadaki bir karenin ekran tarafındaki kaydı. Kareler kimlikle eşlenir:
/// aynı kimlik eski konumundan yenisine kayar.
class _Gorunum {
  _Gorunum(Kare k, {required this.dogdu})
    : id = k.id,
      eskiSatir = k.satir,
      eskiSutun = k.sutun,
      satir = k.satir,
      sutun = k.sutun,
      deger = k.deger;

  final int id;
  int eskiSatir, eskiSutun, satir, sutun, deger;
  final bool dogdu;

  /// Birleşmede yeni değer kayma bitince gösterilir (o ana kadar eskisi).
  int? bekleyenDeger;
  int yogurma = 0;

  /// Birleşip yok olan kare: kayma bitene kadar çizilir, sonra silinir.
  bool olu = false;
  KareModu mod = KareModu.normal;
  Duration modGecikmesi = Duration.zero;

  void yerlestir(int s, int c) {
    eskiSatir = satir;
    eskiSutun = sutun;
    satir = s;
    sutun = c;
  }
}

/// 4×4 tahta: kayma, ölen kareler, gecikmeli yeni kare ve sahneler
/// (2048, kurşunlaşma). Oyunun kendisini bilmez; [oyun]daki son olayı
/// ekrana çevirir.
class Tahta extends StatefulWidget {
  const Tahta({super.key, required this.oyun, this.azHareket = false});

  final Oyun oyun;
  final bool azHareket;

  @override
  State<Tahta> createState() => _TahtaState();
}

class _TahtaState extends State<Tahta> with SingleTickerProviderStateMixin {
  late final AnimationController _kayma =
      AnimationController(vsync: this, duration: Sure.kayma)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _kaymaBitti();
        });

  final Map<int, _Gorunum> _kareler = {};
  Kare? _bekleyenYeni;
  late Oyun _islenen;

  @override
  void initState() {
    super.initState();
    _islenen = widget.oyun;
    for (final k in widget.oyun.durum.kareler) {
      _kareler[k.id] = _Gorunum(k, dogdu: true);
    }
    if (widget.oyun.katman == Katman.bitti) _kursunlas(hemen: true);
  }

  @override
  void didUpdateWidget(Tahta eski) {
    super.didUpdateWidget(eski);
    if (widget.oyun.olaySayaci != _islenen.olaySayaci) _uygula(widget.oyun);
  }

  void _uygula(Oyun o) {
    // Önceki kayma yarıda kaldıysa sonucu hemen yerine otursun.
    if (_kayma.isAnimating) _kaymaBitti();
    _islenen = o;
    for (final g in _kareler.values) {
      g
        ..mod = KareModu.normal
        ..modGecikmesi = Duration.zero;
    }

    final hamle = o.olay == Olay.hamle ? o.sonHamle : null;
    final yeniler = {for (final k in o.durum.kareler) k.id: k};
    final olenler = {for (final k in hamle?.olenler ?? const <Kare>[]) k.id: k};
    _kareler.removeWhere(
      (id, _) => !yeniler.containsKey(id) && !olenler.containsKey(id),
    );

    for (final k in olenler.values) {
      _kareler[k.id]
        ?..yerlestir(k.satir, k.sutun)
        ..olu = true;
    }
    for (final k in o.durum.kareler) {
      final g = _kareler[k.id];
      if (g == null) {
        if (k.id == hamle?.yeniKareId) {
          _bekleyenYeni = k; // kayma bitince doğar
        } else {
          _kareler[k.id] = _Gorunum(k, dogdu: true); // geri al / yeni oyun
        }
        continue;
      }
      g.yerlestir(k.satir, k.sutun);
      if (hamle != null && hamle.birlesenler.contains(k.id)) {
        g.bekleyenDeger = k.deger;
      } else {
        g.deger = k.deger;
      }
    }

    _kayma
      ..duration = o.olay == Olay.geriAl ? Sure.geriKayma : Sure.kayma
      ..forward(from: 0);
    setState(() {});
  }

  void _kaymaBitti() {
    _kareler.removeWhere((_, g) => g.olu);
    for (final g in _kareler.values) {
      g
        ..eskiSatir = g.satir
        ..eskiSutun = g.sutun;
      if (g.bekleyenDeger case final d?) {
        g
          ..deger = d
          ..bekleyenDeger = null
          ..yogurma += 1;
      }
    }
    if (_bekleyenYeni case final k?) {
      _kareler[k.id] = _Gorunum(k, dogdu: true);
      _bekleyenYeni = null;
    }
    if (_islenen.olay == Olay.hamle) {
      if (_islenen.katman == Katman.kazandi) _zirve();
      if (_islenen.katman == Katman.bitti) _kursunlas();
    }
    if (mounted) setState(() {});
  }

  /// 2048 sahnesi: kazanan kare kabarır, ötekiler uzaklık sırasıyla söner.
  void _zirve() {
    final ana = _kareler.values.where((g) => g.deger >= 2048).firstOrNull;
    if (ana == null) return;
    for (final g in _kareler.values) {
      if (g == ana) {
        g
          ..mod = KareModu.zirve
          ..modGecikmesi = Sure.zirveBaslangic;
        continue;
      }
      final uzaklik = math.sqrt(
        math.pow(g.satir - ana.satir, 2) + math.pow(g.sutun - ana.sutun, 2),
      );
      g
        ..mod = KareModu.sonuk
        ..modGecikmesi =
            Sure.zirveBaslangic +
            Duration(milliseconds: (uzaklik * Sure.zirveAdim).round());
    }
  }

  /// Kurşunlaşma: kareler satır sırasıyla içe çöker.
  void _kursunlas({bool hemen = false}) {
    final sirali = _kareler.values.toList()
      ..sort(
        (a, b) => a.satir != b.satir ? a.satir - b.satir : a.sutun - b.sutun,
      );
    for (var i = 0; i < sirali.length; i++) {
      sirali[i]
        ..mod = KareModu.kursun
        ..modGecikmesi = hemen
            ? Duration.zero
            : Sure.kursunBaslangic +
                  Duration(milliseconds: i * Sure.kursunAdim);
    }
  }

  @override
  void dispose() {
    _kayma.dispose();
    super.dispose();
  }

  static double _konum(int i) => Olcu.aralik + i * (Olcu.kare + Olcu.aralik);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: Olcu.tahta,
      child: KilYuzey(
        yukseklik: -4,
        kose: Olcu.tahtaKose,
        bulaniklik: 2.5,
        child: AnimatedBuilder(
          animation: _kayma,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_kayma.value);
            // Ölenler altta çizilir; birleşen kare onların üstüne oturur.
            final sirali = _kareler.values.toList()
              ..sort((a, b) => (a.olu ? 0 : 1) - (b.olu ? 0 : 1));
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var r = 0; r < 4; r++)
                  for (var c = 0; c < 4; c++)
                    Positioned(
                      left: _konum(c),
                      top: _konum(r),
                      width: Olcu.kare,
                      height: Olcu.kare,
                      child: const KilYuzey(yukseklik: Olcu.cukur),
                    ),
                for (final g in sirali)
                  Positioned(
                    key: ValueKey(g.id),
                    left: lerpDouble(_konum(g.eskiSutun), _konum(g.sutun), t),
                    top: lerpDouble(_konum(g.eskiSatir), _konum(g.satir), t),
                    width: Olcu.kare,
                    height: Olcu.kare,
                    child: RepaintBoundary(
                      child: KareWidget(
                        deger: g.deger,
                        dogdu: g.dogdu,
                        yogurma: g.yogurma,
                        mod: g.mod,
                        modGecikmesi: g.modGecikmesi,
                        azHareket: widget.azHareket,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
