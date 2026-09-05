import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/domain/turkish_text.dart';

void main() {
  group('normalizeTurkish', () {
    test('Türkçe harfleri ASCII karşılığına indirir', () {
      expect(normalizeTurkish('Çoban Salatası'), 'coban salatasi');
      expect(
        normalizeTurkish('Zeytinyağlı Yaprak Sarma'),
        'zeytinyagli yaprak sarma',
      );
      expect(normalizeTurkish('Şöbiyet'), 'sobiyet');
    });

    test('büyük İ, tek bir "i" üretir', () {
      // Dart'ta 'İ'.toLowerCase() → 'i' + U+0307 (birleşen üst nokta), yani
      // iki kod birimi. Bu testi kaybedersek "İzmir" araması sessizce çalışmaz.
      final result = normalizeTurkish('İ');
      expect(result, 'i');
      expect(result.runes.length, 1);
    });

    test('büyük I, Türkçe kurala göre ı olur ve i ile birleşir', () {
      expect(normalizeTurkish('IZGARA'), 'izgara');
      expect(normalizeTurkish('Islama Köfte'), 'islama kofte');
    });

    test('şapkalı harfleri de sadeleştirir', () {
      expect(normalizeTurkish('kâğıt helva'), 'kagit helva');
    });

    test('baştaki, sondaki ve fazla boşlukları temizler', () {
      expect(normalizeTurkish('  ÇOBAN   SALATA '), 'coban salata');
      expect(normalizeTurkish('a\n\nb'), 'a b');
    });

    test('boş metin boş kalır', () {
      expect(normalizeTurkish(''), '');
      expect(normalizeTurkish('   '), '');
    });

    test('rakam ve noktalama olduğu gibi kalır', () {
      expect(
        normalizeTurkish('1 su bardağı (250 ml)'),
        '1 su bardagi (250 ml)',
      );
    });
  });

  group('buildSearchText', () {
    test('ad ile malzemeleri birleştirir', () {
      final text = buildSearchText('Mercimek Çorbası', [
        '1 su bardağı kırmızı mercimek',
        '1 adet soğan',
      ]);
      expect(text, contains('mercimek corbasi'));
      expect(text, contains('sogan'));
    });

    test('malzemesiz tarifte yalnızca adı kullanır', () {
      expect(buildSearchText('Menemen', const []), 'menemen');
    });
  });

  group('matchesQuery', () {
    final searchText = buildSearchText('Mercimek Çorbası', [
      '1 su bardağı kırmızı mercimek',
      '2 yemek kaşığı tereyağı',
    ]);

    test('Türkçe karakter yazılmadan da bulur', () {
      expect(matchesQuery(searchText, 'corba'), isTrue);
      expect(matchesQuery(searchText, 'ÇORBA'), isTrue);
      expect(matchesQuery(searchText, 'Çorba'), isTrue);
    });

    test('malzemeden de bulur', () {
      expect(matchesQuery(searchText, 'tereyagi'), isTrue);
      expect(matchesQuery(searchText, 'tereyağı'), isTrue);
    });

    test('boş sorgu her şeyle eşleşir', () {
      expect(matchesQuery(searchText, ''), isTrue);
      expect(matchesQuery(searchText, '   '), isTrue);
    });

    test('alakasız sorguyu eşleştirmez', () {
      expect(matchesQuery(searchText, 'baklava'), isFalse);
    });
  });
}
