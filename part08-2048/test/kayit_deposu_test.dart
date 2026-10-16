import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/kayit_deposu.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<KayitDeposu> depo([Map<String, Object> ilk = const {}]) async {
  SharedPreferences.setMockInitialValues(ilk);
  return KayitDeposu(await SharedPreferences.getInstance());
}

void main() {
  test('kayıt yoksa en iyi skor 0, yarım oyun yok', () async {
    final d = await depo();
    expect(d.enIyiOku(), 0);
    expect(d.oyunOku(), isNull);
  });

  test('en iyi skor yazılır ve okunur', () async {
    final d = await depo();
    await d.enIyiYaz(12480);
    expect(d.enIyiOku(), 12480);
  });

  test('yarım oyun yazılır, okunur, silinir', () async {
    final d = await depo();
    await d.oyunYaz(
      OyunDurumu.izgaradan([
        [2, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], skor: 40),
    );
    expect(d.oyunOku()!.skor, 40);
    await d.oyunSil();
    expect(d.oyunOku(), isNull);
  });

  test('tutulan anahtarlar yalnız bu ikisi', () async {
    final d = await depo();
    await d.enIyiYaz(1);
    await d.oyunYaz(
      OyunDurumu.izgaradan([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {
      KayitDeposu.enIyiAnahtari,
      KayitDeposu.oyunAnahtari,
    });
  });

  test('bozuk kayıt çökertmez, null döner', () async {
    final d = await depo({KayitDeposu.oyunAnahtari: '{bozuk'});
    expect(d.oyunOku(), isNull);
  });
}
