import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/uygulama/kaydedici.dart';
import 'package:ses_kaydedici/uygulama/kayit_kontrol.dart';
import 'package:ses_kaydedici/veri/kayit_deposu.dart';
import 'package:ses_kaydedici/veri/veritabani.dart';

import '../sahte/sahte.dart';

void main() {
  late Veritabani db;
  late KayitDeposu depo;
  late SahteKaydedici mik;
  late SahteSistem sistem;
  late KayitKontrol k;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = Veritabani.test(NativeDatabase.memory());
    depo = KayitDeposu(db);
    mik = SahteKaydedici();
    sistem = SahteSistem();
    k = KayitKontrol(
      kaydedici: mik,
      sistem: sistem,
      depo: depo,
      klasor: () async => '/kayitlar',
      boyutOku: (_) async => 300 * 1024,
      saat: () => DateTime(2026, 11, 6, 14, 32, 5),
    );
  });
  tearDown(() async {
    k.dispose();
    await db.close();
  });

  Future<void> bekle() => Future<void>.delayed(Duration.zero);

  test('başta hazır', () => expect(k.asama, Asama.hazir));

  test(
    'izin yoksa önce ön açıklama; Android penceresi henüz sorulmaz',
    () async {
      mik.izin = false;
      await k.kaydet();
      expect(k.asama, Asama.onIzin);
      expect(mik.izinIstendi, isFalse);
      expect(mik.cagrilar, isEmpty);
      expect(sistem.cagrilar, isEmpty);
    },
  );

  test('ön açıklamada Devam + izin verildi → kayıt hemen başlar', () async {
    mik.izin = false;
    await k.kaydet();
    mik.izin = true;
    await k.izinIsteVeBasla();
    expect(mik.izinIstendi, isTrue);
    expect(k.asama, Asama.kayit);
    expect(mik.cagrilar, ['baslat']);
  });

  test(
    'ön açıklamada Devam + ret → izinYok; sonraki Kaydet doğrudan izinYok',
    () async {
      mik.izin = false;
      await k.kaydet();
      await k.izinIsteVeBasla();
      expect(k.asama, Asama.izinYok);
      expect(mik.cagrilar, isEmpty);
      await k.tekrarSor();
      expect(k.asama, Asama.izinYok);
      await k.kaydet();
      expect(k.asama, Asama.izinYok);
    },
  );

  test('Şimdi değil → hazır', () async {
    mik.izin = false;
    await k.kaydet();
    k.simdiDegil();
    expect(k.asama, Asama.hazir);
  });

  test('izin varsa ön açıklama görünmez', () async {
    await k.kaydet();
    expect(k.asama, Asama.kayit);
    expect(mik.izinIstendi, isFalse);
  });

  test('ayarlardan dönünce izin verildiyse hazır (sormadan yoklar)', () async {
    mik.izin = false;
    await k.kaydet();
    await k.izinIsteVeBasla();
    mik.izinIstendi = false;
    mik.izin = true;
    await k.izniYokla();
    expect(k.asama, Asama.hazir);
    expect(mik.izinIstendi, isFalse);
  });

  test('tekrar sor reddedilirse izinYok kalır', () async {
    mik.izin = false;
    await k.kaydet();
    await k.izinIsteVeBasla();
    await k.tekrarSor();
    expect(k.asama, Asama.izinYok);
  });

  test('ayarları aç kanala gider', () async {
    await k.ayarlariAc();
    expect(sistem.cagrilar, ['ayarlariAc']);
  });

  test(
    'kaydet: bildirim izni istenir, servis açılır, dosya adı tarihli',
    () async {
      await k.kaydet();
      expect(k.asama, Asama.kayit);
      expect(sistem.cagrilar, ['bildirimIzniIste', 'servisBaslat']);
      expect(mik.yol, '/kayitlar/kayit_20261106_143205.ogg');
    },
  );

  test('seviyeler 0..1 olarak toplanır', () async {
    await k.kaydet();
    mik.seviye
      ..add(-60)
      ..add(-30)
      ..add(0);
    await bekle();
    expect(k.ornekler, [0, .5, 1]);
  });

  test('duraklat → devam; duraklıyken gelen seviye yazılmaz', () async {
    await k.kaydet();
    await k.duraklat();
    expect(k.asama, Asama.duraklatildi);
    mik.seviye.add(-30);
    await bekle();
    expect(k.ornekler, isEmpty);
    await k.devam();
    expect(k.asama, Asama.kayit);
    expect(mik.cagrilar, ['baslat', 'duraklat', 'devam']);
  });

  test('telefon gelince mikrofon duraklar → ekran da duraklatıldı', () async {
    await k.kaydet();
    mik.durum.add(KaydediciDurumu.duraklatildi);
    await bekle();
    expect(k.asama, Asama.duraklatildi);
    await k.devam();
    expect(k.asama, Asama.kayit);
  });

  test('durdur: kayıt listeye düşer, servis kapanır', () async {
    await k.kaydet();
    mik.seviye
      ..add(-30)
      ..add(-15);
    await bekle();
    await k.durdur();
    expect(k.asama, Asama.hazir);
    expect(sistem.servisAcik, isFalse);
    final liste = await depo.izle().first;
    expect(liste, hasLength(1));
    final kayit = liste.single;
    expect(kayit.ad, '6 Kas 14:32');
    expect(kayit.dosyaYolu, '/kayitlar/kayit_20261106_143205.ogg');
    expect(kayit.boyutBayt, 300 * 1024);
    expect(kayit.dalga, hasLength(2));
    expect(kayit.olusturma, DateTime(2026, 11, 6, 14, 32, 5));
    expect(k.ornekler, isEmpty);
  });

  test('duraklatılmışken de durdurulabilir', () async {
    await k.kaydet();
    await k.duraklat();
    await k.durdur();
    expect(await depo.izle().first, hasLength(1));
  });

  test('iptal: dosya silinir, listeye yazılmaz, servis kapanır', () async {
    await k.kaydet();
    mik.seviye.add(-30);
    await bekle();
    await k.iptal();
    expect(mik.cagrilar.last, 'iptal');
    expect(k.asama, Asama.hazir);
    expect(sistem.servisAcik, isFalse);
    expect(await depo.izle().first, isEmpty);
  });

  test('kayıttayken ikinci kaydet bir şey yapmaz', () async {
    await k.kaydet();
    await k.kaydet();
    expect(mik.cagrilar, ['baslat']);
  });

  test('kayıt başlamazsa servis kapatılır', () async {
    final hatali = _HataliKaydedici();
    final k2 = KayitKontrol(
      kaydedici: hatali,
      sistem: sistem,
      depo: depo,
      klasor: () async => '/k',
      boyutOku: (_) async => 0,
    );
    await expectLater(k2.kaydet(), throwsA(isA<StateError>()));
    expect(sistem.servisAcik, isFalse);
    expect(k2.asama, Asama.hazir);
    k2.dispose();
  });
}

class _HataliKaydedici extends SahteKaydedici {
  @override
  Future<void> baslat(String yol) async => throw StateError('mikrofon meşgul');
}
