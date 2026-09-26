import 'package:flutter_test/flutter_test.dart';
import 'package:ortak_liste/liste/urun.dart';

Urun _u(String id, {bool alindi = false, int dakika = 0}) => Urun(
  id: id,
  ad: id,
  alindi: alindi,
  ekleyen: 'ben',
  olusturma: DateTime(2026, 9, 26, 12, dakika),
);

void main() {
  test('alınmayanlar üstte, her grupta yeni olan önce', () {
    final sirali = Urun.sirala([
      _u('eski', dakika: 1),
      _u('alindi-yeni', alindi: true, dakika: 9),
      _u('yeni', dakika: 5),
      _u('alindi-eski', alindi: true, dakika: 2),
    ]);
    expect(sirali.map((u) => u.id), [
      'yeni',
      'eski',
      'alindi-yeni',
      'alindi-eski',
    ]);
  });

  test('ad temizlenir: kenar boşluğu atılır, çoklu boşluk teke iner', () {
    expect(Urun.adiDuzelt('  kuru   kayısı '), 'kuru kayısı');
  });

  test('boş ve 60 karakteri aşan ad reddedilir', () {
    expect(Urun.adiDuzelt(''), isNull);
    expect(Urun.adiDuzelt('    '), isNull);
    expect(Urun.adiDuzelt('a' * 60), 'a' * 60);
    expect(Urun.adiDuzelt('a' * 61), isNull);
  });

  test('toMap → fromMap gidiş dönüş aynı ürünü verir', () {
    final u = _u('süt', alindi: true, dakika: 7);
    final geri = Urun.fromMap(u.id, u.toMap());
    expect(geri.ad, u.ad);
    expect(geri.alindi, u.alindi);
    expect(geri.ekleyen, u.ekleyen);
    expect(geri.olusturma, u.olusturma);
  });

  test('bozuk belge çökertmez, varsayılana düşer', () {
    final u = Urun.fromMap('x', {'ad': 42, 'alindi': 'evet'});
    expect(u.ad, '');
    expect(u.alindi, isFalse);
    expect(u.ekleyen, '');
  });
}
