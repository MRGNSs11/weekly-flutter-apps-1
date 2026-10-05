import 'package:deprem_haritasi/deprem/zaman_metni.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('12 ay kısaltması, sırası doğru', () {
    expect(ZamanMetni.aylar.length, 12);
    expect(ZamanMetni.aylar.first, 'Oca');
    expect(ZamanMetni.aylar[9], 'Eki');
    expect(ZamanMetni.aylar.last, 'Ara');
  });

  test('saat ve tarih biçimi, tek haneler sıfırla', () {
    final z = DateTime(2026, 10, 5, 9, 7);
    expect(ZamanMetni.saat(z), '09:07');
    expect(ZamanMetni.tarihSaat(z), '5 Eki 09:07');
  });

  group('once', () {
    final simdi = DateTime(2026, 10, 5, 12);
    String o(Duration fark) => ZamanMetni.once(simdi.subtract(fark), simdi);

    test(
      'bir dakikadan az',
      () => expect(o(const Duration(seconds: 30)), 'az önce'),
    );
    test('dakika', () => expect(o(const Duration(minutes: 45)), '45 dk önce'));
    test(
      '60. dakikada saate geçer',
      () => expect(o(const Duration(minutes: 60)), '1 saat önce'),
    );
    test('saat', () => expect(o(const Duration(hours: 3)), '3 saat önce'));
    test(
      '47 saate kadar saat yazılır',
      () => expect(o(const Duration(hours: 47)), '47 saat önce'),
    );
    test(
      '48 saatte güne geçer',
      () => expect(o(const Duration(hours: 48)), '2 gün önce'),
    );
  });
}
