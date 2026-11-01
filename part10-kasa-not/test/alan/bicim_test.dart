import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/alan/bicim.dart';

/// Kullanıcının Enter'ına benzet: imleçte `\n` ekle.
Duzen? enter(String metin, [int? imlec]) {
  final i = imlec ?? metin.length;
  return listeDevam(
    metin,
    '${metin.substring(0, i)}\n${metin.substring(i)}',
    i + 1,
  );
}

void main() {
  group('Enter ile liste devamı', () {
    test('görev satırından sonra boş görev gelir (işaretli olsa da)', () {
      final d = enter('- [x] Süt')!;
      expect(d.metin, '- [x] Süt\n- [ ] ');
      expect(d.imlec, d.metin.length);
    });
    test('madde ve girinti korunur', () {
      expect(enter('  * elma')!.metin, '  * elma\n  * ');
    });
    test('numaralı liste bir artar', () {
      expect(enter('1. ilk\n2. ikinci')!.metin, endsWith('2. ikinci\n3. '));
    });
    test('boş maddede Enter listeyi bitirir', () {
      final d = enter('- [ ] Süt\n- [ ] ')!;
      expect(d.metin, '- [ ] Süt\n');
      expect(d.imlec, d.metin.length);
    });
    test('liste olmayan satır ve yapıştırma dokunulmaz', () {
      expect(enter('düz yazı'), isNull);
      expect(listeDevam('- a', '- a\nb\nc', 4), isNull);
    });
  });

  group('araç çubuğu', () {
    test('☑ satırın başına görev öneki koyar, ikinci basış kaldırır', () {
      final d = satirOneki('a\nEkmek', 4, '- [ ] ');
      expect(d.metin, 'a\n- [ ] Ekmek');
      expect(satirOneki(d.metin, d.imlec, '- [ ] ').metin, 'a\nEkmek');
    });
    test('madde öneki görev önekine dönüşür', () {
      expect(satirOneki('- Ekmek', 3, '- [ ] ').metin, '- [ ] Ekmek');
    });
    test('# başlık', () {
      expect(satirOneki('Plan', 0, '# ').metin, '# Plan');
    });
    test('seçim kalın olur; seçim yoksa imleç işaretlerin ortasına', () {
      expect(sarmala('bir iki', 4, 7, '**').metin, 'bir **iki**');
      final d = sarmala('ab', 1, 1, '`');
      expect(d.metin, 'a``b');
      expect(d.imlec, 2);
    });
  });
}
