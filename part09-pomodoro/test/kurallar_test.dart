import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/ayarlar.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/kurallar.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';

void main() {
  const a = Ayarlar();
  final t0 = DateTime(2026, 10, 22, 10);
  const bos = PomodoroDurumu();

  PomodoroDurumu tamamla(PomodoroDurumu d, DateTime t) {
    final b = baslat(d, a, t);
    return ilerlet(b, b.bitis!);
  }

  test('baslat: bosta → calisiyor, bitiş = şimdi + süre', () {
    final d = baslat(bos, a, t0);
    expect(d.durum, Durum.calisiyor);
    expect(d.bitis, t0.toUtc().add(const Duration(minutes: 25)));
    expect(d.toplam, const Duration(minutes: 25));
  });

  test('duraklat: kalan = bitiş − şimdi', () {
    final d = duraklat(baslat(bos, a, t0), t0.add(const Duration(minutes: 10)));
    expect(d.durum, Durum.duraklatildi);
    expect(d.kalan, const Duration(minutes: 15));
    expect(d.bitis, isNull);
  });

  test('devam: bitiş = şimdi + kalan', () {
    final t1 = t0.add(const Duration(minutes: 10));
    final t2 = t0.add(const Duration(hours: 2));
    final d = devam(duraklat(baslat(bos, a, t0), t1), t2);
    expect(d.durum, Durum.calisiyor);
    expect(d.bitis, t2.toUtc().add(const Duration(minutes: 15)));
  });

  test('+1 dk çalışırken bitişi, toplamı uzatır', () {
    final b = baslat(bos, a, t0);
    final d = dakikaEkle(b, t0);
    expect(d.bitis, b.bitis!.add(const Duration(minutes: 1)));
    expect(d.toplam, const Duration(minutes: 26));
  });

  test('+1 dk duraklatılmışken kalanı uzatır', () {
    final p = duraklat(baslat(bos, a, t0), t0);
    final d = dakikaEkle(p, t0);
    expect(d.kalan, const Duration(minutes: 26));
    expect(d.toplam, const Duration(minutes: 26));
  });

  test('bitir: aynı fazda bosta, sayılmaz', () {
    final d = bitir(baslat(bos, a, t0), t0.add(const Duration(minutes: 3)));
    expect(d.durum, Durum.bosta);
    expect(d.faz, Faz.calisma);
    expect(d.bugunSayisi, 0);
    expect(d.donguSayaci, 0);
  });

  test('atla: sıradaki fazda bosta, çalışma sayılmaz', () {
    final d = atla(baslat(bos, a, t0), t0);
    expect(d.faz, Faz.kisaMola);
    expect(d.durum, Durum.bosta);
    expect(d.donguSayaci, 0);
    expect(d.bugunSayisi, 0);
  });

  group('geçersiz eylem durumu değiştirmez', () {
    test('bostayken duraklat, devam, +1, bitir', () {
      expect(duraklat(bos, t0), bos);
      expect(devam(bos, t0), bos);
      expect(dakikaEkle(bos, t0), bos);
      expect(bitir(bos, t0), bos);
    });
    test('çalışırken baslat ve devam', () {
      final b = baslat(bos, a, t0);
      expect(baslat(b, a, t0), b);
      expect(devam(b, t0), b);
    });
    test('bilinmeyen eylem kimliği', () {
      final b = baslat(bos, a, t0);
      expect(eylem('uc', b, a, t0), b);
    });
  });

  test('4 çalışmadan sonra uzun mola, uzun moladan sonra sayaç 0', () {
    var d = bos;
    var t = t0;
    final fazlar = <Faz>[];
    for (var i = 0; i < 8; i++) {
      d = tamamla(d, t);
      t = t.add(const Duration(hours: 1));
      fazlar.add(d.faz);
    }
    expect(fazlar, [
      Faz.kisaMola,
      Faz.calisma,
      Faz.kisaMola,
      Faz.calisma,
      Faz.kisaMola,
      Faz.calisma,
      Faz.uzunMola,
      Faz.calisma,
    ]);
    expect(d.donguSayaci, 0);
    expect(d.bugunSayisi, 4);
  });

  test('eylem kimlikleri doğru fonksiyona gider', () {
    final b = eylem('baslat', bos, a, t0);
    expect(b.durum, Durum.calisiyor);
    expect(eylem('duraklat', b, a, t0).durum, Durum.duraklatildi);
    expect(eylem('dakika_ekle', b, a, t0).toplam, const Duration(minutes: 26));
    expect(eylem('bitir', b, a, t0).durum, Durum.bosta);
    expect(eylem('atla', b, a, t0).faz, Faz.kisaMola);
  });

  test('süre değişikliği çalışan fazı etkilemez', () {
    final b = baslat(bos, a, t0);
    final yeni = a.kopya(calismaSn: 50 * 60);
    expect(kalanSure(b, yeni, t0), const Duration(minutes: 25));
  });

  test('ayarlar sınır dışı değeri aralığa çeker', () {
    final x = a.kopya(calismaSn: 500 * 60, kisaMolaSn: 0);
    expect(x.calismaSn, 90 * 60);
    expect(x.kisaMolaSn, 5);
  });
}
