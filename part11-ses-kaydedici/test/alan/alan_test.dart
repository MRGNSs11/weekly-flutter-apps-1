import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/alan/ad.dart';
import 'package:ses_kaydedici/alan/boyut.dart';
import 'package:ses_kaydedici/alan/dalga.dart';
import 'package:ses_kaydedici/alan/hiz.dart';
import 'package:ses_kaydedici/alan/konum.dart';
import 'package:ses_kaydedici/alan/seviye.dart';
import 'package:ses_kaydedici/alan/sure.dart';

void main() {
  group('seviye', () {
    test('eşik ve altı 0, 0 dB ve üstü 1', () {
      expect(seviye(-160), 0);
      expect(seviye(-60), 0);
      expect(seviye(0), 1);
      expect(seviye(3), 1);
    });
    test('arası doğrusal', () {
      expect(seviye(-30), closeTo(.5, 1e-9));
      expect(seviye(-15), closeTo(.75, 1e-9));
    });
    test('NaN sessizlik', () => expect(seviye(double.nan), 0));
  });

  group('dalga', () {
    test('her kova en büyüğünü alır: kısa patlama kaybolmaz', () {
      final ornekler = List<double>.filled(100, .1)..[37] = .9;
      final s = sikistir(ornekler, 10);
      expect(s, hasLength(10));
      expect(s[3], .9);
      expect(s.where((v) => v == .9), hasLength(1));
    });
    test('örnek azsa olduğu gibi', () {
      expect(sikistir([.2, .4], 10), [.2, .4]);
    });
    test('boş ya da 0 çubuk', () {
      expect(sikistir([], 10), isEmpty);
      expect(sikistir([.5], 0), isEmpty);
    });
    test('kovalar tüm örnekleri kapsar (bölünmeyen uzunluk)', () {
      final ornekler = List<double>.generate(103, (i) => i == 102 ? 1 : 0);
      expect(sikistir(ornekler, 10).last, 1);
    });
    test('kodla / çöz: 1 bayt, sınır dışı kırpılır', () {
      final b = kodla([0, .5, 1, 1.4, -.2]);
      expect(b, [0, 128, 255, 255, 0]);
      final geri = coz(b);
      expect(geri[1], closeTo(.5, 1 / 255));
      expect(geri[2], 1);
    });
  });

  group('süre', () {
    test('dakika:saniye', () {
      expect(sureYaz(Duration.zero), '00:00');
      expect(sureYaz(const Duration(minutes: 3, seconds: 7)), '03:07');
      expect(sureYaz(const Duration(seconds: 59, milliseconds: 999)), '00:59');
    });
    test('bir saati geçince saat de', () {
      expect(
        sureYaz(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
    test(
      'eksi süre 00:00',
      () => expect(sureYaz(const Duration(seconds: -5)), '00:00'),
    );
  });

  group('konum', () {
    const toplam = Duration(minutes: 4, seconds: 48);
    test('dokunulan yer orantılı', () {
      expect(dokunulanKonum(50, 200, toplam), const Duration(seconds: 72));
    });
    test('dışarı taşan sürükleme baş / sona yapışır', () {
      expect(dokunulanKonum(-10, 200, toplam), Duration.zero);
      expect(dokunulanKonum(250, 200, toplam), toplam);
    });
    test('genişlik ya da süre 0', () {
      expect(dokunulanKonum(10, 0, toplam), Duration.zero);
      expect(dokunulanKonum(10, 200, Duration.zero), Duration.zero);
    });
    test('ilerleme oranı', () {
      expect(ilerlemeOrani(const Duration(seconds: 72), toplam), .25);
      expect(ilerlemeOrani(const Duration(hours: 1), toplam), 1);
      expect(ilerlemeOrani(Duration.zero, Duration.zero), 0);
    });
  });

  group('ad', () {
    final t = DateTime(2026, 11, 6, 14, 32, 5);
    test('varsayılan ad ve dosya adı', () {
      expect(varsayilanAd(t), '6 Kas 14:32');
      expect(dosyaAdi(t), 'kayit_20261106_143205.ogg');
      expect(varsayilanAd(DateTime(2026, 2, 1, 9, 5)), '1 Şub 09:05');
    });
    test('tarih etiketi', () {
      final simdi = DateTime(2026, 11, 6, 20);
      expect(tarihEtiketi(DateTime(2026, 11, 6, 10, 5), simdi), 'Bugün 10:05');
      expect(tarihEtiketi(DateTime(2026, 11, 5, 18, 20), simdi), 'Dün 18:20');
      expect(tarihEtiketi(DateTime(2026, 11, 3, 9, 30), simdi), '3 Kas 09:30');
      expect(tarihEtiketi(DateTime(2025, 12, 31, 23), simdi), '31 Ara 2025');
    });
    test('dün, yıl ve ay dönümünde de dün', () {
      expect(
        tarihEtiketi(
          DateTime(2025, 12, 31, 23, 59),
          DateTime(2026, 1, 1, 0, 1),
        ),
        'Dün 23:59',
      );
    });
    test('yeniden adlandırma', () {
      expect(temizAd('  Fizik   dersi  ', 'eski'), 'Fizik dersi');
      expect(temizAd('   ', 'eski'), 'eski');
      expect(temizAd('a' * 80, 'eski'), hasLength(60));
    });
  });

  group('boyut', () {
    test('MB virgüllü, küçükse KB', () {
      expect(boyutYaz(0), '0 KB');
      expect(boyutYaz(49 * 1024), '49 KB');
      expect(boyutYaz(300 * 1024), '0,3 MB');
      expect(boyutYaz(1258291), '1,2 MB');
    });
  });

  group('hız', () {
    test('döngü', () {
      expect(sonrakiHiz(1), 1.5);
      expect(sonrakiHiz(1.5), 2);
      expect(sonrakiHiz(2), 1);
      expect(sonrakiHiz(.75), 1);
    });
    test('yazı', () {
      expect(hizYaz(1), '1x');
      expect(hizYaz(1.5), '1,5x');
      expect(hizYaz(2), '2x');
    });
  });
}
