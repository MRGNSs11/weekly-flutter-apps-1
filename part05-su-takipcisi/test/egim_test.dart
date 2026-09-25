import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:su_takipcisi/ui/su/egim.dart';

const g = 9.81;

(double, double) _yatir(double derece) {
  final r = derece * math.pi / 180;
  // Sağa (saat yönünde) yatırınca x = -g·sin, y = g·cos.
  return (-g * math.sin(r), g * math.cos(r));
}

void main() {
  test('telefon dikken yüzey düz', () {
    expect(Egim.hesapla(0, g), 0);
  });

  test('sağa yatınca su sağa toplanır: eğim eksi', () {
    final (x, y) = _yatir(10);
    expect(Egim.hesapla(x, y), closeTo(-math.tan(10 * math.pi / 180), 1e-9));
  });

  test('sola yatınca eğim artı, sağdakinin tam tersi', () {
    final (xs, ys) = _yatir(-10);
    final (xr, yr) = _yatir(10);
    expect(Egim.hesapla(xs, ys), closeTo(-Egim.hesapla(xr, yr), 1e-9));
  });

  test('çok yatınca üst sınırda kalır', () {
    final (x, y) = _yatir(60);
    expect(Egim.hesapla(x, y), -Egim.enFazla);
  });

  test('telefon masada yatarken (x, y küçük) eğim 0', () {
    expect(Egim.hesapla(1.2, -0.8), 0);
  });

  test('baş aşağı tutulunca da sınırın dışına çıkmaz', () {
    final (x, y) = _yatir(150);
    expect(Egim.hesapla(x, y).abs(), Egim.enFazla);
  });
}
