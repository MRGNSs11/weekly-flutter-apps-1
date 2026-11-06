import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/uygulama/liste_kontrol.dart';
import 'package:ses_kaydedici/veri/kayit_deposu.dart';
import 'package:ses_kaydedici/veri/veritabani.dart';

import '../sahte/sahte.dart';

void main() {
  late Veritabani db;
  late KayitDeposu depo;
  late SahteCalar calar;
  late List<String> silinenDosyalar;
  late ListeKontrol l;
  var saat = DateTime(2026, 11, 6, 10);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = Veritabani.test(NativeDatabase.memory());
    depo = KayitDeposu(db, saat: () => saat);
    calar = SahteCalar();
    silinenDosyalar = [];
    l = ListeKontrol(
      depo: depo,
      calar: calar,
      dosyaSil: (y) async => silinenDosyalar.add(y),
      geriAlSuresi: const Duration(milliseconds: 60),
    );
  });
  tearDown(() async {
    l.dispose();
    await db.close();
  });

  Future<void> bekle([int ms = 20]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  Future<int> ekle(String ad, DateTime t) => depo.ekle(
    ad: ad,
    dosyaYolu: '/k/$ad.ogg',
    sure: const Duration(minutes: 4, seconds: 47, milliseconds: 950),
    boyutBayt: 1000,
    dalga: const [.2, .8],
    olusturma: t,
  );

  test('liste depodan gelir, yeni üstte', () async {
    await ekle('eski', DateTime(2026, 11, 5));
    await ekle('yeni', DateTime(2026, 11, 6));
    await bekle();
    expect(l.kayitlar.map((k) => k.ad), ['yeni', 'eski']);
  });

  test('sayfa açılınca en yeni seçilir, çalmaz; süre çalardan', () async {
    await ekle('a', DateTime(2026, 11, 5));
    await ekle('b', DateTime(2026, 11, 6));
    await bekle();
    await l.acildi();
    expect(l.secili!.ad, 'b');
    expect(calar.cagrilar, ['durdur', 'yukle /k/b.ogg']);
    expect(l.toplam, const Duration(minutes: 4, seconds: 48));
    expect(l.caliyor, isFalse);
  });

  test('başka kayıt seçilince eski durur, konum sıfırlanır', () async {
    await ekle('a', DateTime(2026, 11, 5));
    await ekle('b', DateTime(2026, 11, 6));
    await bekle();
    await l.acildi();
    await l.oynatDuraklat();
    calar.konumAkisi.add(const Duration(seconds: 30));
    await bekle();
    await l.sec(l.kayitlar.last);
    expect(l.secili!.ad, 'a');
    expect(l.konum, Duration.zero);
    expect(calar.cagrilar, contains('durdur'));
  });

  test('oynat / duraklat çaların durumunu izler', () async {
    await ekle('a', saat);
    await bekle();
    await l.acildi();
    await l.oynatDuraklat();
    await bekle();
    expect(l.caliyor, isTrue);
    await l.oynatDuraklat();
    await bekle();
    expect(l.caliyor, isFalse);
  });

  test('sar: konum hemen güncellenir, çalara gider', () async {
    await ekle('a', saat);
    await bekle();
    await l.acildi();
    await l.sar(const Duration(seconds: 72));
    expect(l.konum, const Duration(seconds: 72));
    expect(calar.cagrilar.last, 'sar 72');
  });

  test(
    'hız 1 → 1,5 → 2 → 1, çalara gider ve seçim değişince korunur',
    () async {
      await ekle('a', saat);
      await ekle('b', DateTime(2026, 11, 7));
      await bekle();
      await l.acildi();
      await l.hizDegistir();
      expect(calar.sonHiz, 1.5);
      await l.hizDegistir();
      expect(l.hiz, 2);
      await l.sec(l.kayitlar.last);
      expect(calar.sonHiz, 2);
      await l.hizDegistir();
      expect(l.hiz, 1);
    },
  );

  test('sona gelince başa sarılır ve durur', () async {
    await ekle('a', saat);
    await bekle();
    await l.acildi();
    await l.oynatDuraklat();
    calar.bittiAkisi.add(null);
    await bekle();
    expect(l.konum, Duration.zero);
    expect(calar.cagrilar, containsAll(['duraklat', 'sar 0']));
  });

  test('yeniden adlandır: kırpılır, boşsa eski ad kalır', () async {
    await ekle('6 Kas 10:00', saat);
    await bekle();
    await l.acildi();
    await l.adDegistir('  Fizik dersi — hafta 6 ');
    await bekle();
    expect(l.secili!.ad, 'Fizik dersi — hafta 6');
    await l.adDegistir('   ');
    await bekle();
    expect(l.secili!.ad, 'Fizik dersi — hafta 6');
  });

  test('sil: listeden düşer, seçim kalkar; geri al geri getirir', () async {
    await ekle('Market listesi', saat);
    await bekle();
    await l.acildi();
    await l.sil(l.secili!);
    await bekle();
    expect(l.kayitlar, isEmpty);
    expect(l.secili, isNull);
    expect(l.silinen!.ad, 'Market listesi');
    await l.geriAl();
    await bekle(100);
    expect(l.kayitlar.single.ad, 'Market listesi');
    expect(silinenDosyalar, isEmpty);
  });

  test('geri al süresi dolunca dosya da silinir', () async {
    await ekle('a', saat);
    await bekle();
    await l.sil(l.kayitlar.single);
    await bekle(100);
    expect(l.silinen, isNull);
    expect(silinenDosyalar, ['/k/a.ogg']);
  });

  test('ikinci silme gelince ilkinin dosyası hemen silinir', () async {
    await ekle('a', saat);
    await ekle('b', DateTime(2026, 11, 7));
    await bekle();
    await l.sil(l.kayitlar.first);
    await bekle();
    await l.sil(l.kayitlar.first);
    expect(silinenDosyalar, ['/k/b.ogg']);
    expect(l.silinen!.ad, 'a');
  });

  test('kayıt başlarken çalan susar', () async {
    await ekle('a', saat);
    await bekle();
    await l.acildi();
    await l.oynatDuraklat();
    await bekle();
    await l.durdur();
    await bekle();
    expect(l.caliyor, isFalse);
  });
}
