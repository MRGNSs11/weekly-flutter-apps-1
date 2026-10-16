import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/kayit.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';

final ornek = OyunDurumu.izgaradan(
  [
    [2, 4, 8, 16],
    [0, 0, 32, 0],
    [0, 2048, 0, 0],
    [0, 0, 0, 2],
  ],
  skor: 21000,
  hamle: 512,
);

/// Geçerli bir kaydın tek alanını bozar.
String bozulmus(String alan, Object? deger) {
  final m = jsonDecode(oyunuYaz(ornek)) as Map<String, Object?>;
  m[alan] = deger;
  return jsonEncode(m);
}

List<int> duz(List<int> Function(List<int> l) degistir) =>
    degistir([for (final s in ornek.izgara) ...s]);

void main() {
  test('yazıp okuyunca aynı tahta, skor, hamle, kazandı', () {
    final d = oyunuOku(oyunuYaz(ornek))!;
    expect(d.izgara, ornek.izgara);
    expect(d.skor, 21000);
    expect(d.hamle, 512);
    expect(d.kazandi, isTrue);
    expect(d.bitti, isFalse);
  });

  test('kimlikler yeniden verilir ve hepsi farklı', () {
    final d = oyunuOku(oyunuYaz(ornek))!;
    final idler = d.kareler.map((k) => k.id).toSet();
    expect(idler.length, d.kareler.length);
    expect(d.sonrakiId, greaterThan(idler.reduce((a, b) => a > b ? a : b)));
  });

  group('bozuk kayıt → null (uygulama yeni oyunla açılır)', () {
    final durumlar = <String, String?>{
      'kayıt yok': null,
      'JSON değil': 'ab{c',
      'liste, nesne değil': '[1,2,3]',
      'sürüm farklı': bozulmus('surum', 99),
      'ızgara 15 hücre': bozulmus('izgara', duz((l) => l..removeLast())),
      'ızgara 17 hücre': bozulmus('izgara', duz((l) => l..add(0))),
      'hücre 3 (2\'nin kuvveti değil)': bozulmus(
        'izgara',
        duz((l) => l..[0] = 3),
      ),
      'hücre 1': bozulmus('izgara', duz((l) => l..[0] = 1)),
      'hücre negatif': bozulmus('izgara', duz((l) => l..[0] = -2)),
      'hücre çok büyük (2^18)': bozulmus('izgara', duz((l) => l..[0] = 262144)),
      'hücre metin': bozulmus('izgara', [for (var i = 0; i < 16; i++) '2']),
      'tahta boş': bozulmus('izgara', List.filled(16, 0)),
      'skor negatif': bozulmus('skor', -1),
      'skor ondalık': bozulmus('skor', 1.5),
      'skor akıl dışı büyük': bozulmus('skor', 999999999),
      'hamle eksik': bozulmus('hamle', null),
      'kazandı metin': bozulmus('kazandi', 'evet'),
    };
    durumlar.forEach((ad, metin) {
      test(ad, () => expect(oyunuOku(metin), isNull));
    });
  });

  test('bitmiş tahta kaydı bozuk sayılır', () {
    final bitmis = jsonEncode({
      'surum': kayitSurumu,
      'izgara': [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 8],
      'skor': 100,
      'hamle': 50,
      'kazandi': false,
    });
    expect(oyunuOku(bitmis), isNull);
  });

  test('kazandı yanlış yazılmış ama tahtada 2048 varsa doğru okunur', () {
    expect(oyunuOku(bozulmus('kazandi', false))!.kazandi, isTrue);
  });
}
