import 'package:deprem_haritasi/deprem/kumele.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Offset k(Offset o) => o;

  test('uzak noktalar ayrı kalır', () {
    final s = kumele([const Offset(10, 10), const Offset(200, 10)], k);
    expect(s.length, 2);
    expect(s.every((x) => x.sayi == 1), isTrue);
  });

  test('aynı hücredeki noktalar birleşir, merkez ortalamadır', () {
    final s = kumele([const Offset(10, 10), const Offset(30, 50)], k);
    expect(s.length, 1);
    expect(s.single.sayi, 2);
    expect(s.single.merkez, const Offset(20, 30));
  });

  test('hücre boyu değiştirilebilir', () {
    final noktalar = [const Offset(10, 10), const Offset(30, 10)];
    expect(kumele(noktalar, k, hucre: 20).length, 2);
    expect(kumele(noktalar, k, hucre: 58).length, 1);
  });

  test('boş liste boş sonuç', () {
    expect(kumele(<Offset>[], k), isEmpty);
  });
}
