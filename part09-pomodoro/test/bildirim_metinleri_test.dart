import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';
import 'package:pomodoro/bildirim/bildirim_metinleri.dart';
import 'package:pomodoro/bildirim/yerel_bildirim_servisi.dart';

void main() {
  test('faz etiketi: çalışmada sıra, molada ad', () {
    expect(fazEtiketi(const PomodoroDurumu(donguSayaci: 1)), 'Çalışma · 2/4');
    expect(fazEtiketi(const PomodoroDurumu(faz: Faz.kisaMola)), 'Kısa mola');
    expect(fazEtiketi(const PomodoroDurumu(faz: Faz.uzunMola)), 'Uzun mola');
  });

  test('sayaç gövdesi yerel saatle Bitiş HH:mm', () {
    final d = PomodoroDurumu(
      durum: Durum.calisiyor,
      bitis: DateTime(2026, 10, 23, 14, 5).toUtc(),
      toplam: const Duration(minutes: 25),
    );
    expect(sayacGovdesi(d), 'Bitiş 14:05');
  });

  test('duraklatıldı: başlık ve Kalan mm:ss (saniye yukarı yuvarlanır)', () {
    const d = PomodoroDurumu(
      faz: Faz.kisaMola,
      durum: Durum.duraklatildi,
      kalan: Duration(minutes: 12, seconds: 33, milliseconds: 400),
      toplam: Duration(minutes: 15),
    );
    expect(duraklatildiBasligi(d), 'Duraklatıldı · Kısa mola');
    expect(duraklatildiGovdesi(d), 'Kalan 12:34');
  });

  test('bitti metni tamamlanınca oluşacak durumdan hesaplanır', () {
    final bitis = DateTime(2026, 10, 23, 14).toUtc();
    final calisma = PomodoroDurumu(
      durum: Durum.calisiyor,
      bitis: bitis,
      toplam: const Duration(minutes: 25),
      donguSayaci: 1,
      bugunSayisi: 2,
      gun: '2026-10-23',
    );
    final m = bittiMetni(calisma);
    expect(m.baslik, 'Mola zamanı');
    expect(m.govde, 'Bugün 3 pomodoro');

    final dorduncu = calisma.kopya(donguSayaci: 3);
    expect(bittiMetni(dorduncu).baslik, 'Uzun mola zamanı');

    final mola = PomodoroDurumu(
      faz: Faz.kisaMola,
      durum: Durum.calisiyor,
      bitis: bitis,
      toplam: const Duration(minutes: 5),
      bugunSayisi: 2,
      gun: '2026-10-23',
    );
    expect(bittiMetni(mola).baslik, 'Çalışma zamanı');
    expect(bittiMetni(mola).govde, 'Bugün 2 pomodoro');
  });

  test('tz.UTC saat dilimi verisi yüklenmeden aynı anı verir', () {
    final an = DateTime(2026, 10, 22, 23, 50);
    final z = utcZaman(an);
    expect(z.millisecondsSinceEpoch, an.millisecondsSinceEpoch);
    expect(z.timeZoneOffset, Duration.zero);
  });
}
