import 'dart:convert';

import 'kurallar.dart' show hamleVar, tahtaBoyu;
import 'oyun_durumu.dart';

/// Yarım kalan oyunun kaydı: yalnız o anki tahta + skor + hamle sayısı.
/// Geri al geçmişi kaydedilmez; uygulama yeniden açılınca geri al boş başlar.
///
/// Kayıt diskten okunur, yani bozuk olabilir (yarım yazılmış, elle
/// değiştirilmiş). [oyunuOku] hiçbir şeye güvenmez: tutarsız bir alan
/// görürse null döner ve uygulama yeni oyunla açılır, çökmez.

const int kayitSurumu = 1;

/// En büyük olası kare: 4×4 tahtada 2^17 = 131072.
const int _enBuyukKare = 131072;

/// Skor için akla yatkın üst sınır (her karenin tek tek oluşmasının
/// toplamından çok büyük); aşan kayıt bozuk sayılır.
const int _enBuyukSkor = 10000000;

String oyunuYaz(OyunDurumu d) => jsonEncode({
  'surum': kayitSurumu,
  'izgara': [for (final satir in d.izgara) ...satir],
  'skor': d.skor,
  'hamle': d.hamle,
  'kazandi': d.kazandi,
});

OyunDurumu? oyunuOku(String? metin) {
  if (metin == null) return null;
  final Object? veri;
  try {
    veri = jsonDecode(metin);
  } on FormatException {
    return null;
  }
  if (veri is! Map<String, Object?>) return null;
  if (veri['surum'] != kayitSurumu) return null;

  final izgara = veri['izgara'];
  final skor = veri['skor'];
  final hamle = veri['hamle'];
  final kazandi = veri['kazandi'];
  if (izgara is! List || izgara.length != tahtaBoyu * tahtaBoyu) return null;
  if (skor is! int || skor < 0 || skor > _enBuyukSkor) return null;
  if (hamle is! int || hamle < 0) return null;
  if (kazandi is! bool) return null;

  final degerler = <int>[];
  for (final v in izgara) {
    if (v is! int || !_gecerliHucre(v)) return null;
    degerler.add(v);
  }
  if (degerler.every((v) => v == 0)) return null;

  final durum = OyunDurumu.izgaradan(
    [
      for (var r = 0; r < tahtaBoyu; r++)
        degerler.sublist(r * tahtaBoyu, (r + 1) * tahtaBoyu),
    ],
    skor: skor,
    hamle: hamle,
  );

  // Bitmiş oyun kaydedilmez; böyle bir kayıt bozuk sayılır.
  if (!hamleVar(durum.kareler)) return null;
  return durum.copyWith(kazandi: kazandi || durum.kazandi);
}

/// 0 (boş) ya da 2..131072 arasında 2'nin kuvveti.
bool _gecerliHucre(int v) =>
    v == 0 || (v >= 2 && v <= _enBuyukKare && (v & (v - 1)) == 0);
