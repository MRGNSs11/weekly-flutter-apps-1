import 'dart:math' as math;

import 'package:deprem_haritasi/deprem/deprem.dart';
import 'package:deprem_haritasi/deprem/sismogram.dart';
import 'package:flutter_test/flutter_test.dart';

const saat = Sismogram.saatMs;
final t0 = DateTime.utc(2026, 10, 4, 12).millisecondsSinceEpoch.toDouble();

Deprem d(double saatSonra, double m) => Deprem(
  enlem: 38,
  boylam: 35,
  buyukluk: m,
  derinlikKm: 7,
  zaman: DateTime.fromMillisecondsSinceEpoch(
    (t0 + saatSonra * saat).round(),
    isUtc: true,
  ),
  yer: 'x',
);

void main() {
  group('genlik', () {
    test('deprem yokken taban değeri', () {
      expect(Sismogram.genlik([], t0), Sismogram.taban);
    });

    test('tepe anında taban + m^2,15 × 2,1', () {
      final g = Sismogram.genlik([d(0, 4)], t0);
      expect(g, closeTo(Sismogram.taban + math.pow(4, 2.15) * 2.1, 1e-9));
    });

    test('17 dakika uzakta katkı 1/e katına düşer', () {
      final tam = math.pow(3, 2.15) * 2.1;
      final g = Sismogram.genlik([d(0, 3)], t0 + Sismogram.yayilmaMs);
      expect(g - Sismogram.taban, closeTo(tam / math.e, 1e-9));
    });

    test('1,2 saatten uzak deprem katkı vermez', () {
      expect(Sismogram.genlik([d(1.3, 5)], t0), Sismogram.taban);
      expect(Sismogram.genlik([d(-1.3, 5)], t0), Sismogram.taban);
    });

    test('yakın iki deprem toplanır', () {
      final tek = Sismogram.genlik([d(0, 3)], t0);
      final cift = Sismogram.genlik([d(0, 3), d(0, 3)], t0);
      expect(
        cift - Sismogram.taban,
        closeTo(2 * (tek - Sismogram.taban), 1e-9),
      );
    });
  });

  test('işaret −1…1 aralığında ve aynı an için hep aynı', () {
    for (var i = 0; i < 2000; i++) {
      final t = t0 + i * 997.0 * 60;
      final s = Sismogram.isaret(t);
      expect(s, inInclusiveRange(-1, 1));
      expect(Sismogram.isaret(t), s);
    }
  });

  test('altSinir ilk "t ve sonrası" indeksini verir', () {
    final l = [d(0, 1), d(1, 1), d(2, 1)];
    expect(Sismogram.altSinir(l, t0 - 1), 0);
    expect(Sismogram.altSinir(l, t0), 0);
    expect(Sismogram.altSinir(l, t0 + 1), 1);
    expect(Sismogram.altSinir(l, t0 + 2 * saat), 2);
    expect(Sismogram.altSinir(l, t0 + 9 * saat), 3);
    expect(Sismogram.altSinir([], t0), 0);
  });

  group('enBuyukYakin', () {
    test('±1,5 saat içindeki en büyüğü seçer', () {
      final l = [d(-1, 2.1), d(-0.2, 3.4), d(1, 2.8), d(2, 4.5)];
      expect(Sismogram.enBuyukYakin(l, t0)!.buyukluk, 3.4);
    });

    test('aralık boşsa null', () {
      expect(Sismogram.enBuyukYakin([d(2, 4), d(-2, 4)], t0), isNull);
      expect(Sismogram.enBuyukYakin([], t0), isNull);
    });

    test('sınırdaki deprem dahil', () {
      expect(Sismogram.enBuyukYakin([d(1.5, 3)], t0), isNotNull);
      expect(Sismogram.enBuyukYakin([d(-1.5, 3)], t0), isNotNull);
    });
  });

  test('sinirla oynatma çizgisini son 7 gün içinde tutar', () {
    final simdi = t0;
    expect(Sismogram.sinirla(simdi + 5, simdi), simdi);
    expect(
      Sismogram.sinirla(simdi - 8 * 24 * saat, simdi),
      simdi - 7 * 24 * saat,
    );
    expect(Sismogram.sinirla(simdi - saat, simdi), simdi - saat);
  });
}
