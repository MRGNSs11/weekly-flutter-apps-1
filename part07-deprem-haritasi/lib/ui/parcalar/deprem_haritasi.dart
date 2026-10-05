import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// latlong2'nin kendi `Path` sınıfı var, dart:ui'ninkiyle çakışıyor.
import 'package:latlong2/latlong.dart' hide Path;

import '../../deprem/deprem.dart';
import '../../deprem/kumele.dart';
import '../../deprem/sismogram.dart';
import '../tema.dart';

/// OSM haritası (gri) + mor çizginin gösterdiği anın son 24 saati.
///
/// Noktalar yaşlandıkça solar: az önceki deprem koyu, 23 saat önceki
/// neredeyse görünmez. 3 ve üstü mor.
class DepremHaritasi extends StatefulWidget {
  const DepremHaritasi({
    super.key,
    required this.olaylar,
    required this.an,
    required this.secili,
    required this.onDeprem,
  });

  final List<Deprem> olaylar;
  final ValueListenable<double> an;
  final ValueListenable<Deprem?> secili;
  final ValueChanged<Deprem> onDeprem;

  /// Türkiye ve komşu denizler.
  static final sinir = LatLngBounds(
    const LatLng(35.7, 25.8),
    const LatLng(42.2, 44.8),
  );

  @override
  State<DepremHaritasi> createState() => _DepremHaritasiState();
}

class _DepremHaritasiState extends State<DepremHaritasi>
    with SingleTickerProviderStateMixin {
  final _harita = MapController();
  late final AnimationController _halka = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  /// Karolar diske önbelleklenir: `cache/fm_cache`, en fazla 50 MB.
  /// OSM'in kullanım kuralı da önbellek istiyor (PLAN B5/2).
  late final _karolar = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 50000000,
    ),
  );

  /// Karolar griye çevrilir; noktalar renkli kalır.
  static const _gri = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  void dispose() {
    _halka.dispose();
    super.dispose();
  }

  List<Deprem> _gorunen(double an) {
    final l = widget.olaylar;
    return l.sublist(
      Sismogram.altSinir(l, an - 24 * Sismogram.saatMs),
      Sismogram.altSinir(l, an + 1),
    );
  }

  void _dokun(TapPosition konum) {
    final kamera = _harita.camera;
    Deprem? en;
    var enUzak = 24.0;
    for (final e in _gorunen(widget.an.value)) {
      final p = kamera.latLngToScreenOffset(LatLng(e.enlem, e.boylam));
      final d = (p - konum.relative!).distance;
      if (d < enUzak) {
        enUzak = d;
        en = e;
      }
    }
    if (en != null) widget.onDeprem(en);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _harita,
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: DepremHaritasi.sinir,
          padding: const EdgeInsets.all(4),
        ),
        backgroundColor: Renk.zemin,
        minZoom: 4,
        maxZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (konum, _) => _dokun(konum),
      ),
      children: [
        ColorFiltered(
          colorFilter: _gri,
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.omergunes.deprem_haritasi',
            tileProvider: _karolar,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: widget.an,
          builder: (_, an, _) => _NoktaKatmani(_gorunen(an), an),
        ),
        _HalkaKatmani(widget.secili, _halka),
        // OSM kuralı: atıf haritanın üstünde görünür olmalı. Paketin hazır
        // atıf kutusu ("flutter_map | ©…") taslağa göre çok büyük; taslaktaki
        // gibi 9 punto, yarı saydam.
        const Align(
          alignment: Alignment.bottomRight,
          child: ColoredBox(
            color: Color(0x8CFFFFFF),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Renk.murekkep),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Noktaları kendisi çizer (yüzlerce `CircleMarker` widget'ı yerine tek
/// `CustomPaint`). Haritanın her kıpırdamasında kamera değişir, yeniden çizer.
class _NoktaKatmani extends StatelessWidget {
  const _NoktaKatmani(this.olaylar, this.an);
  final List<Deprem> olaylar;
  final double an;

  @override
  Widget build(BuildContext context) {
    final kamera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _NoktaCizici(olaylar, an, kamera),
      ),
    );
  }
}

class _NoktaCizici extends CustomPainter {
  _NoktaCizici(this.olaylar, this.an, this.kamera);
  final List<Deprem> olaylar;
  final double an;
  final MapCamera kamera;

  /// Kümeleme (PLAN K1.11, Should) şimdilik KAPALI: taslakta noktalar üst
  /// üste binip yoğunluğu kendileri gösteriyor; sayılı koyu daireler haritayı
  /// ağırlaştırıyordu. Açmak için true.
  static const kumelemeAcik = false;
  static const hucre = 16.0;

  @override
  void paint(Canvas c, Size s) {
    final noktalar = [
      for (final e in olaylar)
        (e, kamera.latLngToScreenOffset(LatLng(e.enlem, e.boylam))),
    ];
    final boya = Paint();
    final kumeler = kumelemeAcik
        ? kumele(noktalar, (n) => n.$2, hucre: hucre)
        : [
            for (final n in noktalar) Kume([n], n.$2),
          ];
    for (final k in kumeler) {
      if (k.sayi == 1) {
        final (e, p) = k.uyeler.single;
        final yas = ((an - e.ms) / (24 * Sismogram.saatMs)).clamp(0.0, 1.0);
        boya.color = (e.buyukluk >= 3 ? Renk.mor : Renk.murekkep).withValues(
          alpha: .12 + .75 * (1 - yas),
        );
        c.drawCircle(p, 2 + e.buyukluk * 1.6, boya);
      } else {
        _kume(c, k);
      }
    }
  }

  void _kume(Canvas c, Kume<(Deprem, Offset)> k) {
    var enBuyuk = 0.0, enYeni = 0;
    for (final (e, _) in k.uyeler) {
      if (e.buyukluk > enBuyuk) enBuyuk = e.buyukluk;
      if (e.ms > enYeni) enYeni = e.ms;
    }
    final yas = ((an - enYeni) / (24 * Sismogram.saatMs)).clamp(0.0, 1.0);
    final r = 9 + k.sayi.clamp(2, 30) * .45;
    c.drawCircle(
      k.merkez,
      r,
      Paint()
        ..color = (enBuyuk >= 3 ? Renk.mor : Renk.murekkep).withValues(
          alpha: .35 + .6 * (1 - yas),
        ),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '${k.sayi}',
        style: Yazi.sans(10, wght: 700, renk: Renk.zemin),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, k.merkez - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_NoktaCizici e) =>
      e.olaylar != olaylar || e.an != an || e.kamera != kamera;
}

/// Seçili depremin yerinde genişleyip sönen iki mor halka (katalog A8).
class _HalkaKatmani extends StatelessWidget {
  const _HalkaKatmani(this.secili, this.halka);
  final ValueListenable<Deprem?> secili;
  final Animation<double> halka;

  @override
  Widget build(BuildContext context) {
    final kamera = MapCamera.of(context);
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: secili,
        builder: (_, e, _) => e == null
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _HalkaCizici(
                  kamera.latLngToScreenOffset(LatLng(e.enlem, e.boylam)),
                  e.buyukluk,
                  halka,
                ),
              ),
      ),
    );
  }
}

class _HalkaCizici extends CustomPainter {
  _HalkaCizici(this.p, this.m, this.halka) : super(repaint: halka);
  final Offset p;
  final double m;
  final Animation<double> halka;

  @override
  void paint(Canvas c, Size s) {
    final boya = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final k in const [0.0, 0.5]) {
      final f = (halka.value + k) % 1;
      boya.color = Renk.mor.withValues(alpha: 1 - f);
      c.drawCircle(p, (8 + m * 9) * f, boya);
    }
  }

  @override
  bool shouldRepaint(_HalkaCizici e) => e.p != p || e.m != m;
}
