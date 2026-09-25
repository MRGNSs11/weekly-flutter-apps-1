import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:su_takipcisi/ui/su/su_fizigi.dart';

SuFizigi _sahne() => SuFizigi(rastgele: math.Random(1))
  ..genislik = 400
  ..yukseklik = 800
  ..enAzPx = 100;

void _sure(SuFizigi f, double saniye, {double dt = 1 / 60}) {
  for (var t = 0.0; t < saniye; t += dt) {
    f.ilerle(dt);
  }
}

void main() {
  test('seviye hedefe yumuşakça yaklaşır', () {
    final f = _sahne()..hedefOran = 1;
    f.ilerle(1 / 60);
    expect(f.gosterilenOran, greaterThan(0));
    expect(f.gosterilenOran, lessThan(.1));
    _sure(f, 3);
    expect(f.gosterilenOran, closeTo(1, .001));
  });

  test('boşken bile su en az enAzPx yüksekliğinde, doluyken en fazla %80', () {
    final f = _sahne();
    expect(f.taban, 800 - 100);
    f.hedefOran = 1;
    _sure(f, 3);
    expect(f.taban, closeTo(800 * .2, .5));
  });

  test('damla yüzeye değince 1 halka ve 8 sıçrama parçası oluşur', () {
    final f = _sahne()..damlaBirak();
    expect(f.damlalar, hasLength(1));
    var adim = 0;
    while (f.damlalar.isNotEmpty && adim++ < 600) {
      f.ilerle(1 / 60);
    }
    expect(f.damlalar, isEmpty);
    expect(f.halkalar.where((h) => h.yuzey), hasLength(1));
    expect(f.sicrama.length, lessThanOrEqualTo(8));
    expect(f.sicrama, isNotEmpty);
    expect(f.sallanma, greaterThan(.5));
  });

  test('damla suya değince çarpma bildirimi tam bir kez gelir', () {
    var carpma = 0;
    final f = _sahne()..carpinca = () => carpma++;
    f.damlaBirak();
    _sure(f, 3);
    expect(carpma, 1);
  });

  test('halka ve sıçrama zamanla kaybolur', () {
    final f = _sahne()
      ..damlaBirak()
      ..dokun(200, 750);
    _sure(f, 5);
    expect(f.halkalar, isEmpty);
    expect(f.sicrama, isEmpty);
  });

  test('kare hızından bağımsız: 60 ve 120 Hz aynı yere varır', () {
    final a = _sahne()..hedefOran = .5;
    final b = _sahne()..hedefOran = .5;
    _sure(a, .5, dt: 1 / 60);
    _sure(b, .5, dt: 1 / 120);
    expect(a.gosterilenOran, closeTo(b.gosterilenOran, .02));
  });

  test('eğim hedefe oturur ve yüzeyi bir yana yatırır', () {
    final f = _sahne()..egimHedef = .3;
    _sure(f, 4);
    expect(f.egim, closeTo(.3, .01));
    final sol = f.yuzeyY(0, 500, 0, 170, 0);
    final sag = f.yuzeyY(400, 500, 0, 170, 0);
    expect(sag - sol, closeTo(400 * .3, 1));
  });

  test('gökyüzüne dokunmak halka açmaz, suya dokunmak açar', () {
    final f = _sahne(); // taban 700
    f.dokun(200, 300);
    expect(f.dokunmaHalkalari, isEmpty);
    f.dokun(200, 750);
    expect(f.dokunmaHalkalari, hasLength(1));
  });

  test('en fazla 4 dokunma halkası; beşincide en eskisi düşer', () {
    final f = _sahne();
    for (var i = 0; i < 5; i++) {
      f.dokun(i * 10.0, 750);
    }
    final xler = f.dokunmaHalkalari.map((h) => h.x).toList();
    expect(xler, [10, 20, 30, 40]);
  });

  test('hareket azaltılınca efekt oluşmaz, seviye anında oturur', () {
    final f = _sahne()
      ..hareketAzaltilmis = true
      ..hedefOran = .7
      ..damlaBirak()
      ..dokun(10, 10);
    f.ilerle(1 / 60);
    expect(f.damlalar, isEmpty);
    expect(f.halkalar, isEmpty);
    expect(f.gosterilenOran, .7);
  });
}
