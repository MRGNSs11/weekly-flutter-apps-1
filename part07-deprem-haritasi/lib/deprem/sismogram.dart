import 'dart:math' as math;

import 'deprem.dart';

/// Sismograf şeridinin hesapları. Çizimden bağımsız, saf Dart.
///
/// Şerit gerçek bir sismogram değil: her deprem, zamanında büyüklüğüyle
/// orantılı bir tepe olarak çiziliyor. Böylece 7 günlük ~700 kayıt tek
/// bakışta okunuyor.
abstract final class Sismogram {
  static const saatMs = 3600 * 1000;

  /// Şerit ölçeği: 1 saat = 7 dp (taslak `pxH`).
  static const dpSaat = 7.0;

  /// Deprem yokken bile çizgi hafifçe titrer.
  static const taban = 1.6;

  /// Tepenin genişliği: 17 dakikada genlik 1/e'ye düşer.
  static const yayilmaMs = 0.28 * saatMs;

  /// Bu uzaklıktan sonra bir depremin katkısı hesaba katılmaz.
  static const etkiMs = 1.2 * saatMs;

  /// Oynatma çizgisine bu kadar yakın depremler "seçili" sayılır.
  static const secimMs = 1.5 * saatMs;

  /// Şeridin geriye gidebileceği en uzak an.
  static const geriMs = 7 * 24 * saatMs;

  /// [t] anındaki genlik (dp). [olaylar] eskiden yeniye sıralı olmalı.
  static double genlik(List<Deprem> olaylar, double t) {
    var a = taban;
    final son = altSinir(olaylar, t + etkiMs);
    for (var i = altSinir(olaylar, t - etkiMs); i < son; i++) {
      final q = (t - olaylar[i].ms) / yayilmaMs;
      a += math.pow(olaylar[i].buyukluk, 2.15) * 2.1 * math.exp(-q * q);
    }
    return a;
  }

  /// Dalganın o pikseldeki yönü, −1…1. Zamana bağlı ve sabit: şerit
  /// kaydırılınca aynı an aynı şekilde çizilir, titreme olmaz.
  static double isaret(double t) {
    final i = (t / (saatMs / dpSaat)).floor();
    final x = math.sin(i * 12.9898 + 78.233) * 43758.5453;
    return (x - x.floorToDouble()) * 2 - 1;
  }

  /// `olaylar[i].ms >= t` olan ilk indeks (ikili arama).
  static int altSinir(List<Deprem> olaylar, double t) {
    var a = 0, b = olaylar.length;
    while (a < b) {
      final m = (a + b) >> 1;
      if (olaylar[m].ms < t) {
        a = m + 1;
      } else {
        b = m;
      }
    }
    return a;
  }

  /// Oynatma çizgisinin ±1,5 saat içindeki en büyük deprem; yoksa `null`.
  static Deprem? enBuyukYakin(List<Deprem> olaylar, double t) {
    Deprem? en;
    final son = altSinir(olaylar, t + secimMs + 1);
    for (var i = altSinir(olaylar, t - secimMs); i < son; i++) {
      final e = olaylar[i];
      if (en == null || e.buyukluk > en.buyukluk) en = e;
    }
    return en;
  }

  /// Oynatma çizgisini şimdi − 7 gün … şimdi arasında tutar.
  static double sinirla(double t, double simdi) =>
      t.clamp(simdi - geriMs, simdi).toDouble();
}
