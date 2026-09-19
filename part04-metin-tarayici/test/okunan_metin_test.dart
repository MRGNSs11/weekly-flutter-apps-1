import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:metin_tarayici/ocr/okunan_metin.dart';

/// Haftanın test edilen katmanı: ML Kit çıktısını okunur metne çevirme.
///
/// Model ve kamera test edilmiyor (ikisi de cihaza bağlı). Dönüşüm saf
/// olduğu için burada eksiksiz test edilebiliyor.

/// Tek satırlık blok üretir. Yer bilgisi vermezsek bloklar sıralanamaz,
/// o yüzden her testte kutu elle veriliyor.
OkunanBlok blok(
  List<String> satirlar, {
  double sol = 0,
  double ust = 0,
  double genislik = 200,
  double satirYuksekligi = 20,
}) {
  return OkunanBlok(
    satirlar: [
      for (var i = 0; i < satirlar.length; i++)
        OkunanSatir(
          metin: satirlar[i],
          kutu: Rect.fromLTWH(
            sol,
            ust + i * satirYuksekligi,
            genislik,
            satirYuksekligi,
          ),
        ),
    ],
  );
}

void main() {
  group('satır birleştirme', () {
    test('bir bloğun satırları tek paragrafa akar', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['Talep eğrisi, fiyat ile', 'talep edilen miktar']),
      ]);

      expect(sonuc.metin, 'Talep eğrisi, fiyat ile talep edilen miktar');
    });

    test('satırlar yukarıdan aşağı sıralanır, geliş sırası önemsiz', () {
      final karisik = OkunanBlok(
        satirlar: [
          OkunanSatir(metin: 'ikinci', kutu: Rect.fromLTWH(0, 20, 100, 20)),
          OkunanSatir(metin: 'birinci', kutu: Rect.fromLTWH(0, 0, 100, 20)),
        ],
      );

      expect(MetinDuzenleyici.duzenle([karisik]).metin, 'birinci ikinci');
    });

    test('satır içindeki fazla boşluklar teke iner', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['iki    kelime  ', '  arada boşluk']),
      ]);

      expect(sonuc.metin, 'iki kelime arada boşluk');
    });

    test('boş satırlar atılır, araya çift boşluk bırakmaz', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['ilk', '   ', 'son']),
      ]);

      expect(sonuc.metin, 'ilk son');
    });
  });

  group('tireyle bölünmüş kelimeler', () {
    test('satır sonundaki tire kelimeyi birleştirir', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['eko-', 'nomi notu']),
      ]);

      expect(sonuc.metin, 'ekonomi notu');
    });

    test('Türkçe küçük harfle devam eden kelime de birleşir', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['değiş-', 'şiklik']),
      ]);

      expect(sonuc.metin, 'değişşiklik');
    });

    test('büyük harfle başlayan satır birleştirilmez — tire kalır', () {
      // "Ankara-" + "İstanbul" bitişik yazılırsa ad bozulur.
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['Ankara-', 'İstanbul hattı']),
      ]);

      expect(sonuc.metin, 'Ankara- İstanbul hattı');
    });

    test('rakamla biten tire yıl aralığıdır, kelime değil', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['2024-', '2025 dönemi']),
      ]);

      expect(sonuc.metin, '2024- 2025 dönemi');
    });

    test('madde imi olan tire birleştirmez', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['-', 'ilk madde']),
      ]);

      expect(sonuc.metin, '- ilk madde');
    });

    test('yumuşak tire de kelime böler', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['baş­lık', 'devam']),
      ]);

      // Satır ortasındaki yumuşak tireye dokunmuyoruz, sadece satır sonuna.
      expect(sonuc.metin, 'baş­lık devam');
    });
  });

  group('blok sıralaması', () {
    test('bloklar yukarıdan aşağı sıralanır', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['alttaki'], ust: 400),
        blok(['üstteki'], ust: 0),
      ]);

      expect(sonuc.metin, 'üstteki\n\nalttaki');
    });

    test('yan yana iki sütun soldan sağa okunur', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['sağ sütun'], sol: 300, ust: 10, genislik: 200),
        blok(['sol sütun'], sol: 0, ust: 12, genislik: 200),
      ]);

      expect(sonuc.metin, 'sol sütun\n\nsağ sütun');
    });

    test('alt alta duran bloklar sütun sanılmaz', () {
      // Dikey örtüşme yok: ikisi ayrı banda düşmeli.
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['sonra'], sol: 0, ust: 100),
        blok(['önce'], sol: 300, ust: 0),
      ]);

      expect(sonuc.metin, 'önce\n\nsonra');
    });

    test('sıralama, blokların geldiği sıraya göre değişmez', () {
      final bloklar = [
        blok(['A'], sol: 0, ust: 0),
        blok(['B'], sol: 300, ust: 4),
        blok(['C'], sol: 0, ust: 200),
      ];

      final duz = MetinDuzenleyici.duzenle(bloklar).metin;
      final ters = MetinDuzenleyici.duzenle(bloklar.reversed.toList()).metin;

      expect(duz, 'A\n\nB\n\nC');
      expect(ters, duz);
    });

    test('paragraflar arasına boş satır girer', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['ilk paragraf'], ust: 0),
        blok(['ikinci paragraf'], ust: 100),
      ]);

      expect(sonuc.metin.split('\n\n'), hasLength(2));
    });
  });

  group('boş sonuç', () {
    test('hiç blok yoksa sonuç boştur', () {
      final sonuc = MetinDuzenleyici.duzenle([]);

      expect(sonuc.doluMu, isFalse);
      expect(sonuc.kelimeSayisi, 0);
    });

    test('sadece boşluk okunduysa metin var sayılmaz', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['   ', '\t']),
      ]);

      expect(sonuc.doluMu, isFalse);
    });
  });

  group('kelime sayısı', () {
    test('ekranda yazan sayı gerçek kelime sayısıdır', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['bir iki üç'], ust: 0),
        blok(['dört beş'], ust: 100),
      ]);

      expect(sonuc.kelimeSayisi, 5);
    });

    test('birleşen tireli kelime tek sayılır', () {
      final sonuc = MetinDuzenleyici.duzenle([
        blok(['eko-', 'nomi']),
      ]);

      expect(sonuc.kelimeSayisi, 1);
    });

    test('boş metnin kelime sayısı sıfırdır', () {
      expect(MetinDuzenleyici.kelimeSay('   '), 0);
    });
  });

  group('Türkçe', () {
    test('Türkçe harfler olduğu gibi korunur, düzeltilmez', () {
      // Model "ı" yerine "i" okuyabilir; bilerek düzeltmiyoruz.
      // Yanlış düzeltme, yanlış okumadan beterdir (PLAN.md E).
      const ham = 'Işık ılık ıhlamur İstanbul ğüşçö';
      final sonuc = MetinDuzenleyici.duzenle([blok([ham])]);

      expect(sonuc.metin, ham);
    });
  });
}
