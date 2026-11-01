import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/alan/arama.dart';
import 'package:kasa_not/alan/baslik.dart';
import 'package:kasa_not/alan/gorev.dart';

void main() {
  group('baslikCikar', () {
    test('ilk dolu satırı alır, # işaretini atar', () {
      expect(baslikCikar('# Market listesi\n- [ ] Süt'), 'Market listesi');
    });
    test('baştaki boş satırları ve boşlukları atlar', () {
      expect(baslikCikar('\n\n   ###   Plan  \nx'), 'Plan');
    });
    test('boş not "Adsız not" olur', () {
      expect(baslikCikar('  \n \n'), adsizNot);
      expect(baslikCikar('#   '), adsizNot);
    });
    test('özet başlıktan sonraki satırlardır', () {
      expect(ozetSatirlari('# A\n\nb\nc', enFazla: 1), ['b']);
    });
  });

  group('arama', () {
    test('büyük I ve küçük ı aynı', () {
      expect(eslesir('Ispanak yemeği', 'ıspanak'), isTrue);
    });
    test('İ ile i aynı (birleşen nokta sorunu yok)', () {
      expect(eslesir('İzmir gezisi', 'izmir'), isTrue);
      expect(eslesir('izmir gezisi', 'İZMİR'), isTrue);
    });
    test('Türkçe harfler sadeleşir', () {
      expect(eslesir('Çorba tarifi', 'corba'), isTrue);
    });
    test('boş sorgu her şeyle eşleşir, olmayan kelime eşleşmez', () {
      expect(eslesir('x', '  '), isTrue);
      expect(eslesir('Market', 'banka'), isFalse);
    });
  });

  group('gorevDegistir', () {
    const metin = '# Liste\n- [x] Süt\n- [ ] Ekmek\n  * [ ] iç içe';
    test('ilk kutu işaretliden boşa', () {
      expect(gorevDegistir(metin, 0), contains('- [ ] Süt'));
    });
    test('ortadaki kutu boştan işaretliye', () {
      expect(gorevDegistir(metin, 1), contains('- [x] Ekmek'));
    });
    test('son (iç içe) kutu değişir, girinti korunur', () {
      expect(gorevDegistir(metin, 2), endsWith('  * [x] iç içe'));
    });
    test('kod bloğu içindeki kutu sayılmaz', () {
      const kodlu = '```\n- [ ] kod\n```\n- [ ] gerçek';
      expect(gorevSatirlari(kodlu), [3]);
      expect(gorevDegistir(kodlu, 0), endsWith('- [x] gerçek'));
      expect(gorevDegistir(kodlu, 0), contains('- [ ] kod'));
    });
    test('aralık dışı indeks metni değiştirmez', () {
      expect(gorevDegistir(metin, 9), metin);
      expect(gorevDegistir(metin, -1), metin);
    });
  });
}
