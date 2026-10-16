import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/kare.dart';
import 'package:oyun_2048/oyun/kurallar.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';

/// Hamleden sonra eklenen rastgele kare hariç ızgara.
List<List<int>> yenisiz(HamleSonucu s) {
  final g = List.generate(4, (_) => List.filled(4, 0));
  for (final k in s.durum.kareler) {
    if (k.id != s.yeniKareId) g[k.satir][k.sutun] = k.deger;
  }
  return g;
}

HamleSonucu oyna(List<List<int>> izgara, Yon yon, {int tohum = 1}) =>
    kaydir(OyunDurumu.izgaradan(izgara), yon, Random(tohum))!;

void main() {
  group('kayma', () {
    const t = [
      [2, 0, 0, 2],
      [0, 4, 0, 0],
      [0, 0, 8, 0],
      [16, 0, 0, 0],
    ];

    test('sola', () {
      expect(yenisiz(oyna(t, Yon.sol)), [
        [4, 0, 0, 0],
        [4, 0, 0, 0],
        [8, 0, 0, 0],
        [16, 0, 0, 0],
      ]);
    });

    test('sağa', () {
      expect(yenisiz(oyna(t, Yon.sag)), [
        [0, 0, 0, 4],
        [0, 0, 0, 4],
        [0, 0, 0, 8],
        [0, 0, 0, 16],
      ]);
    });

    test('yukarı', () {
      expect(yenisiz(oyna(t, Yon.yukari)), [
        [2, 4, 8, 2],
        [16, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
    });

    test('aşağı', () {
      expect(yenisiz(oyna(t, Yon.asagi)), [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [2, 0, 0, 0],
        [16, 4, 8, 2],
      ]);
    });
  });

  group('birleşme', () {
    test('[2,2,2,2] → [4,4]: bir kare bir hamlede yalnız bir kez birleşir', () {
      final s = oyna([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sol);
      expect(yenisiz(s)[0], [4, 4, 0, 0]);
      expect(s.birlesenler.length, 2);
      expect(s.olenler.length, 2);
    });

    test('[4,4,8,0] → [8,8]: yeni oluşan 8 eski 8 ile zincir yapmaz', () {
      final s = oyna([
        [4, 4, 8, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sol);
      expect(yenisiz(s)[0], [8, 8, 0, 0]);
    });

    test('kayma yönündeki kenar önce birleşir: [2,2,2,0] sağa → [0,2,4]', () {
      final s = oyna([
        [2, 2, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sag);
      expect(yenisiz(s)[0], [0, 0, 2, 4]);
    });

    test('skor birleşen değerlerin toplamı kadar artar', () {
      final s = kaydir(
        OyunDurumu.izgaradan([
          [2, 2, 8, 8],
          [4, 4, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ], skor: 100),
        Yon.sol,
        Random(1),
      )!;
      expect(s.durum.skor, 100 + 4 + 16 + 8);
    });

    test('birleşmede kalan karenin kimliği korunur, öteki ölür', () {
      final d = OyunDurumu.izgaradan([
        [0, 0, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final sol = d.hucredeki(0, 2)!;
      final sag = d.hucredeki(0, 3)!;
      final s = kaydir(d, Yon.sol, Random(1))!;
      final kalan = s.durum.kareler.firstWhere((k) => k.id == sol.id);
      expect(kalan.deger, 4);
      expect((kalan.satir, kalan.sutun), (0, 0));
      expect(s.birlesenler, {sol.id});
      expect(s.olenler.single.id, sag.id);
      // Ölen kare de birleşme noktasına kayar (animasyon için).
      expect((s.olenler.single.satir, s.olenler.single.sutun), (0, 0));
    });

    test('hamle sayacı bir artar', () {
      final s = oyna([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sag);
      expect(s.durum.hamle, 1);
    });
  });

  group('hareket yok', () {
    test('hiçbir kare kıpırdamıyorsa null: hamle ve yeni kare yok', () {
      final d = OyunDurumu.izgaradan([
        [2, 4, 0, 0],
        [8, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(kaydir(d, Yon.sol, Random(1)), isNull);
      expect(kaydir(d, Yon.yukari, Random(1)), isNull);
      expect(kaydir(d, Yon.sag, Random(1)), isNotNull);
    });
  });

  group('yeni kare', () {
    test('her hamleden sonra boş bir hücreye tam bir kare eklenir', () {
      final s = oyna([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sag);
      expect(s.durum.kareler.length, 2);
      final yeni = s.durum.kareler.firstWhere((k) => k.id == s.yeniKareId);
      expect([2, 4], contains(yeni.deger));
      expect((yeni.satir, yeni.sutun), isNot((0, 3)));
    });

    test('aynı tohum aynı sonucu verir (deterministik)', () {
      const t = [
        [2, 0, 2, 0],
        [0, 0, 0, 0],
        [0, 4, 0, 0],
        [0, 0, 0, 0],
      ];
      expect(
        oyna(t, Yon.sol, tohum: 7).durum.izgara,
        oyna(t, Yon.sol, tohum: 7).durum.izgara,
      );
    });

    test('10.000 denemede 4 oranı %10 civarında', () {
      final r = Random(2048);
      var dort = 0;
      for (var i = 0; i < 10000; i++) {
        if (kareEkle(const [], r, 1)!.deger == 4) dort++;
      }
      expect(dort / 10000, closeTo(0.10, 0.015));
    });

    test('yeni kimlik durumdaki sayaçtan gelir ve sayaç artar', () {
      final d = OyunDurumu.izgaradan([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final s = kaydir(d, Yon.sag, Random(1))!;
      expect(s.yeniKareId, d.sonrakiId);
      expect(s.durum.sonrakiId, d.sonrakiId + 1);
    });

    test('tahta doluysa kareEkle null döner', () {
      final dolu = [
        for (var i = 0; i < 16; i++)
          Kare(id: i, satir: i ~/ 4, sutun: i % 4, deger: 2),
      ];
      expect(kareEkle(dolu, Random(1), 99), isNull);
    });

    test('yeni oyun: iki kare, skor 0', () {
      final d = yeniOyun(Random(3));
      expect(d.kareler.length, 2);
      expect(d.skor, 0);
      expect(d.kareler.map((k) => k.id).toSet().length, 2);
    });
  });

  group('oyun sonu ve kazanma', () {
    test('dolu ama yan yana eşit kare varsa bitmemiş', () {
      final d = OyunDurumu.izgaradan([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 4],
      ]);
      expect(hamleVar(d.kareler), isTrue);
    });

    test('dolu ve hiç eşit komşu yoksa bitmiş', () {
      final d = OyunDurumu.izgaradan([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 8],
      ]);
      expect(hamleVar(d.kareler), isFalse);
    });

    test('son boşluk dolup eşit komşu kalmayınca durum bitti olur', () {
      // Sola kayınca boşluk (3,3)'e geçer. Oraya 2 ya da 4 gelir; komşuları
      // 32 ve 64 olduğu için hangisi gelirse gelsin hamle kalmaz.
      final d = OyunDurumu.izgaradan([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 64],
        [0, 8, 16, 32],
      ]);
      for (final tohum in [1, 2, 3, 4, 5]) {
        final s = kaydir(d, Yon.sol, Random(tohum))!;
        expect(s.durum.kareler.length, 16);
        expect(s.durum.bitti, isTrue);
      }
    });

    test('2048 oluşunca kazandı doğru olur', () {
      final s = oyna([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Yon.sol);
      expect(s.durum.kazandi, isTrue);
      expect(s.durum.enBuyuk, 2048);
    });

    test('kazandıktan sonra devam edilen hamlede kazandı doğru kalır', () {
      final d = OyunDurumu.izgaradan([
        [2048, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(d.kazandi, isTrue);
      expect(kaydir(d, Yon.sag, Random(1))!.durum.kazandi, isTrue);
    });
  });

  test('durum değişmez: hamle eski durumu bozmaz', () {
    final d = OyunDurumu.izgaradan([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final once = d.izgara;
    kaydir(d, Yon.sol, Random(1));
    expect(d.izgara, once);
    expect(() => d.kareler.add(d.kareler.first), throwsUnsupportedError);
  });
}
