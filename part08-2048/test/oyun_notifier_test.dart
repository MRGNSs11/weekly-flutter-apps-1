import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/kurallar.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';
import 'package:oyun_2048/oyun/oyun_notifier.dart';
import 'package:oyun_2048/oyun/kayit_deposu.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> kur({
  OyunDurumu? baslangic,
  Map<String, Object> kayitli = const {},
}) async {
  SharedPreferences.setMockInitialValues(kayitli);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      rastgeleProvider.overrideWithValue(Random(1)),
      kayitDeposuProvider.overrideWithValue(KayitDeposu(prefs)),
      if (baslangic != null)
        baslangicDurumuProvider.overrideWithValue(baslangic),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Her yöne sırayla deneyip hamle olana dek kaydırır.
void birHamle(OyunNotifier n) {
  for (final y in Yon.values) {
    if (n.kaydir(y)) return;
  }
  fail('hiç hamle yok');
}

void main() {
  test('geri al tam olarak önceki durumu geri koyar', () async {
    final c = await kur();
    final n = c.read(oyunProvider.notifier);
    final once = c.read(oyunProvider).durum;
    birHamle(n);
    expect(c.read(oyunProvider).durum, isNot(same(once)));
    n.geriAl();
    // Kopya değil, aynı nesne: durum hiç değiştirilmediği için saklamak yetti.
    expect(c.read(oyunProvider).durum, same(once));
    expect(c.read(oyunProvider).olay, Olay.geriAl);
  });

  test('geçmiş en fazla 20 hamle tutar', () async {
    final c = await kur();
    final n = c.read(oyunProvider.notifier);
    var hamle = 0;
    while (hamle < 30 && c.read(oyunProvider).katman == Katman.yok) {
      birHamle(n);
      hamle++;
    }
    expect(hamle, 30);
    expect(c.read(oyunProvider).gecmis.length, OyunNotifier.gecmisSiniri);
    for (var i = 0; i < 25; i++) {
      n.geriAl();
    }
    expect(c.read(oyunProvider).gecmis, isEmpty);
    expect(c.read(oyunProvider).durum.hamle, 10, reason: '30 hamle − 20 geri');
  });

  test('geçmiş boşken geri al hiçbir şey yapmaz', () async {
    final c = await kur();
    final once = c.read(oyunProvider);
    c.read(oyunProvider.notifier).geriAl();
    expect(c.read(oyunProvider), same(once));
  });

  test('hareket olmayan yönde hamle sayılmaz, geçmişe girmez', () async {
    final c = await kur(
      baslangic: OyunDurumu.izgaradan([
        [2, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
    );
    expect(c.read(oyunProvider.notifier).kaydir(Yon.sol), isFalse);
    expect(c.read(oyunProvider).gecmis, isEmpty);
    expect(c.read(oyunProvider).olaySayaci, 0);
  });

  test('yeni oyun geçmişi temizler, en iyi skor kalır', () async {
    final c = await kur(
      baslangic: OyunDurumu.izgaradan([
        [64, 64, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], skor: 500),
    );
    final n = c.read(oyunProvider.notifier)..kaydir(Yon.sol);
    expect(c.read(oyunProvider).enIyi, 628);
    n.yeniOyun();
    final o = c.read(oyunProvider);
    expect(o.gecmis, isEmpty);
    expect(o.durum.skor, 0);
    expect(o.durum.kareler.length, 2);
    expect(o.enIyi, 628);
  });

  test(
    'en iyi skor kayıttan okunur, geçilince yazılır, geri al düşürmez',
    () async {
      final c = await kur(
        kayitli: {KayitDeposu.enIyiAnahtari: 600},
        baslangic: OyunDurumu.izgaradan([
          [64, 64, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ], skor: 500),
      );
      expect(c.read(oyunProvider).enIyi, 600);
      c.read(oyunProvider.notifier).kaydir(Yon.sol); // 500 + 128
      expect(c.read(oyunProvider).enIyi, 628);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(KayitDeposu.enIyiAnahtari), 628);
      c.read(oyunProvider.notifier).geriAl();
      expect(c.read(oyunProvider).durum.skor, 500);
      expect(c.read(oyunProvider).enIyi, 628);
    },
  );

  test(
    '2048 olunca "kazandın" katmanı; katmanda hamle yok; devam et sürdürür',
    () async {
      final c = await kur(
        baslangic: OyunDurumu.izgaradan([
          [1024, 1024, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
      );
      final n = c.read(oyunProvider.notifier);
      expect(n.kaydir(Yon.sol), isTrue);
      expect(c.read(oyunProvider).katman, Katman.kazandi);
      expect(n.kaydir(Yon.sag), isFalse, reason: 'katman açıkken oynanmaz');
      n.devamEt();
      expect(c.read(oyunProvider).katman, Katman.yok);
      expect(c.read(oyunProvider).olay, Olay.devam);
      expect(n.kaydir(Yon.sag), isTrue);
      expect(
        c.read(oyunProvider).katman,
        Katman.yok,
        reason: 'ikinci kez açılmaz',
      );
    },
  );

  test('oyun bitince "hamle kalmadı" katmanı; geri al kapatır', () async {
    final c = await kur(
      baslangic: OyunDurumu.izgaradan([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 64],
        [0, 8, 16, 32],
      ]),
    );
    final n = c.read(oyunProvider.notifier);
    expect(n.kaydir(Yon.sol), isTrue);
    expect(c.read(oyunProvider).katman, Katman.bitti);
    n.geriAl();
    expect(c.read(oyunProvider).katman, Katman.yok);
    expect(c.read(oyunProvider).durum.bitti, isFalse);
  });

  test('bitmiş bir tahtayla başlanırsa katman baştan açık', () async {
    final c = await kur(
      baslangic: OyunDurumu.izgaradan([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 8],
      ]).copyWith(bitti: true),
    );
    expect(c.read(oyunProvider).katman, Katman.bitti);
  });

  test('her değişiklikte olay sayacı bir artar', () async {
    final c = await kur();
    final n = c.read(oyunProvider.notifier);
    birHamle(n);
    n.geriAl();
    n.yeniOyun();
    expect(c.read(oyunProvider).olaySayaci, 3);
  });

  group('yarım oyun kaydı', () {
    test('her hamleden sonra yazılır; yeni bir oturum oradan açılır', () async {
      final c = await kur();
      final n = c.read(oyunProvider.notifier);
      birHamle(n);
      birHamle(n);
      final simdi = c.read(oyunProvider).durum;

      // Uygulamanın kapanıp açılması: aynı kayıtla yeni bir container.
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [
          rastgeleProvider.overrideWithValue(Random(9)),
          kayitDeposuProvider.overrideWithValue(KayitDeposu(prefs)),
        ],
      );
      addTearDown(c2.dispose);
      final acilan = c2.read(oyunProvider);
      expect(acilan.durum.izgara, simdi.izgara);
      expect(acilan.durum.skor, simdi.skor);
      expect(acilan.gecmis, isEmpty, reason: 'geri al geçmişi kaydedilmez');
    });

    test('geri al kaydı da günceller', () async {
      final c = await kur();
      final n = c.read(oyunProvider.notifier);
      final ilk = c.read(oyunProvider).durum;
      birHamle(n);
      n.geriAl();
      final prefs = await SharedPreferences.getInstance();
      expect(KayitDeposu(prefs).oyunOku()!.izgara, ilk.izgara);
    });

    test('yeni oyun kaydı siler', () async {
      final c = await kur();
      final n = c.read(oyunProvider.notifier);
      birHamle(n);
      n.yeniOyun();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(KayitDeposu.oyunAnahtari), isFalse);
    });

    test('oyun bitince kayıt silinir; geri alınca yeniden yazılır', () async {
      final c = await kur(
        baslangic: OyunDurumu.izgaradan([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 64],
          [0, 8, 16, 32],
        ]),
      );
      final n = c.read(oyunProvider.notifier);
      final prefs = await SharedPreferences.getInstance();
      n.kaydir(Yon.sol);
      expect(c.read(oyunProvider).katman, Katman.bitti);
      expect(prefs.containsKey(KayitDeposu.oyunAnahtari), isFalse);
      n.geriAl();
      expect(prefs.containsKey(KayitDeposu.oyunAnahtari), isTrue);
    });

    test('bozuk kayıtla açılış yeni oyun verir', () async {
      final c = await kur(kayitli: {KayitDeposu.oyunAnahtari: 'bozuk'});
      final o = c.read(oyunProvider);
      expect(o.durum.kareler.length, 2);
      expect(o.durum.skor, 0);
    });
  });
}
