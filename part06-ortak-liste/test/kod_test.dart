import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ortak_liste/liste/kod.dart';

void main() {
  test('alfabede karışan karakter yok ve 31 karakter', () {
    for (final c in ['0', 'O', '1', 'I', 'L']) {
      expect(Kod.alfabe.contains(c), isFalse, reason: c);
    }
    expect(Kod.alfabe.length, 31);
  });

  test('üretilen kod 6 hane ve yalnız alfabeden', () {
    final r = Random(1);
    for (var i = 0; i < 500; i++) {
      final kod = Kod.uret(r);
      expect(kod.length, 6);
      expect(Kod.gecerliMi(kod), isTrue, reason: kod);
    }
  });

  test('aynı tohum aynı kodu verir', () {
    expect(Kod.uret(Random(42)), Kod.uret(Random(42)));
  });

  test('küçük harf ve boşluk düzeltilir', () {
    expect(Kod.normalize(' k7m 4xp '), 'K7M4XP');
    expect(Kod.gecerliMi(Kod.normalize('k7m4xp')), isTrue);
  });

  test('eksik, fazla ve alfabe dışı kod reddedilir', () {
    expect(Kod.gecerliMi('K7M4X'), isFalse);
    expect(Kod.gecerliMi('K7M4XPA'), isFalse);
    expect(Kod.gecerliMi('K7M0XP'), isFalse); // sıfır
    expect(Kod.gecerliMi('K7MIXP'), isFalse); // I
  });

  test('süzgeç yazarken alfabe dışını atar ve 6 hanede keser', () {
    expect(Kod.suz('k7-m0 4xpqq'), 'K7M4XP');
    expect(Kod.suz('ı'), ''); // ı → I, I alfabede yok
  });
}
