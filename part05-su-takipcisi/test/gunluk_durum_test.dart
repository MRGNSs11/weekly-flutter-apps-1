import 'package:flutter_test/flutter_test.dart';
import 'package:su_takipcisi/su/gunluk_durum.dart';

void main() {
  final pazartesi = DateTime(2026, 9, 28, 23, 59);
  final sali = DateTime(2026, 9, 29, 0, 0, 1);

  group('gün değişimi', () {
    test('gece yarısını geçince sayı sıfırlanır, ayarlar korunur', () {
      final dun = GunlukDurum(
        sayi: 6,
        hedef: 10,
        bardakMl: 330,
        tarih: GunlukDurum.gunAnahtari(pazartesi),
      );
      final bugun = dun.bugunIcin(sali);
      expect(bugun.sayi, 0);
      expect(bugun.hedef, 10);
      expect(bugun.bardakMl, 330);
      expect(bugun.tarih, '2026-09-29');
    });

    test('aynı gün içinde hiçbir şey değişmez', () {
      final d = GunlukDurum.ilk(pazartesi).ekle().ekle();
      expect(identical(d.bugunIcin(pazartesi), d), isTrue);
    });

    test('gün anahtarı Kotlin LocalDate biçiminde (sıfır dolgulu)', () {
      expect(GunlukDurum.gunAnahtari(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('sayma', () {
    test('geri al sıfırın altına inmez', () {
      final d = GunlukDurum.ilk(pazartesi).geriAl();
      expect(d.sayi, 0);
      expect(d.ekle().geriAl().geriAl().sayi, 0);
    });

    test('oran hedefi aşınca 1de kalır', () {
      var d = GunlukDurum.ilk(pazartesi).hedefiDegistir(2);
      expect(d.oran, 0);
      d = d.ekle();
      expect(d.oran, 0.5);
      d = d.ekle().ekle();
      expect(d.oran, 1);
      expect(d.hedefeUlasti, isTrue);
    });

    test('toplam ml bardak boyutuna göre', () {
      final d = GunlukDurum.ilk(pazartesi).bardagiDegistir(330).ekle().ekle();
      expect(d.toplamMl, 660);
    });
  });

  group('ayarlar', () {
    test('hedef 1–20 aralığına kırpılır', () {
      final d = GunlukDurum.ilk(pazartesi);
      expect(d.hedefiDegistir(0).hedef, 1);
      expect(d.hedefiDegistir(99).hedef, 20);
    });

    test('listede olmayan bardak boyutu reddedilir', () {
      final d = GunlukDurum.ilk(pazartesi);
      expect(d.bardagiDegistir(123).bardakMl, 250);
      expect(d.bardagiDegistir(500).bardakMl, 500);
    });
  });

  test('binlik ayırıcı', () {
    expect(binlikAyir(0), '0');
    expect(binlikAyir(250), '250');
    expect(binlikAyir(1250), '1.250');
    expect(binlikAyir(1000000), '1.000.000');
  });
}
