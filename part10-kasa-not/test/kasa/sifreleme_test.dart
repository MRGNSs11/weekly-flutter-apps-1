import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/kasa/sifreleme.dart';

void main() {
  final s = Sifreleme();
  final anahtar = List<int>.generate(32, (i) => i);
  final baskaAnahtar = List<int>.generate(32, (i) => 255 - i);

  test('şifrele → çöz aynı metni verir (Türkçe + emoji)', () async {
    const metin = '# Doğum günü\nPasta Cumartesi 14:00 🎂';
    final veri = await s.sifrele(metin, anahtar);
    expect(await s.coz(veri, anahtar), metin);
  });

  test('şifreli veride düz metin geçmez', () async {
    final veri = await s.sifrele('gizli kelime', anahtar);
    expect(String.fromCharCodes(veri).contains('gizli'), isFalse);
  });

  test('aynı metin her seferinde farklı şifrelenir (yeni nonce)', () async {
    final a = await s.sifrele('aynı', anahtar);
    final b = await s.sifrele('aynı', anahtar);
    expect(a, isNot(equals(b)));
    expect(a.sublist(0, 12), isNot(equals(b.sublist(0, 12))));
  });

  test('yanlış anahtar hata verir, çöp metin vermez', () async {
    final veri = await s.sifrele('metin', anahtar);
    expect(() => s.coz(veri, baskaAnahtar), throwsA(isA<SifrelemeHatasi>()));
  });

  test('bozulmuş ya da kısa veri çökertmez, hata verir', () async {
    final veri = await s.sifrele('metin', anahtar);
    veri[20] ^= 0xFF;
    expect(() => s.coz(veri, anahtar), throwsA(isA<SifrelemeHatasi>()));
    expect(
      () => s.coz(Uint8List.fromList([1, 2, 3]), anahtar),
      throwsA(isA<SifrelemeHatasi>()),
    );
  });
}
