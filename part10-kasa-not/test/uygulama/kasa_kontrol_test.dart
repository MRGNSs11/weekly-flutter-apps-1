import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/uygulama/kasa_kontrol.dart';
import 'package:kasa_not/veri/not_deposu.dart';
import 'package:kasa_not/veri/veritabani.dart';

import '../sahte/sahte_kasa.dart';

void main() {
  late Veritabani db;
  late NotDeposu depo;
  late SahteKasaServisi servis;
  late SahteGizlilik gizlilik;
  late KasaKontrol kasa;

  Future<List<dynamic>> notlar() => depo.izle().first;

  setUp(() async {
    db = Veritabani.test(NativeDatabase.memory());
    depo = NotDeposu(db);
    servis = SahteKasaServisi();
    gizlilik = SahteGizlilik();
    kasa = KasaKontrol(servis: servis, gizlilik: gizlilik, depo: depo);
    await kasa.baslat();
  });
  tearDown(() => db.close());

  Future<int> kilitliNot(String metin) async {
    final id = await depo.ekle(metin);
    final n = (await depo.getir(id))!;
    expect(await kasa.kilitle(n, await depo.izle().first), isTrue);
    return id;
  }

  test('ekran kilidi yoksa kasa kullanılamaz', () async {
    servis.uygun = false;
    await kasa.baslat();
    expect(kasa.durum, KasaDurumu.kullanilamaz);
  });

  test(
    'ilk kilitleme anahtarı üretir, not şifrelenir, kasa açık kalır',
    () async {
      final id = await kilitliNot('gizli');
      final n = (await depo.getir(id))!;
      expect(n.icerik, isNull);
      expect(n.sifreli, isNotNull);
      expect(kasa.acik, isTrue);
      expect(kasa.cozulmus(id), 'gizli');
      expect(gizlilik.cagrilar.last, isTrue);
    },
  );

  test('kapatınca çözülmüş metin bellekten silinir, önizleme açılır', () async {
    final id = await kilitliNot('gizli');
    await kasa.kapat();
    expect(kasa.acik, isFalse);
    expect(kasa.cozulmus(id), isNull);
    expect(gizlilik.cagrilar.last, isFalse);
  });

  test(
    'ilk kurulum oturumunda açılış ayrıca parmak izi ister (K1 bulgusu)',
    () async {
      await kilitliNot('gizli');
      await kasa.kapat();
      await kasa.ac(await depo.izle().first);
      expect(servis.dogrulamaSayisi, 1);
      expect(kasa.acik, isTrue);
    },
  );

  test('yeni oturumda yalnız anahtar okunur ve notlar çözülür', () async {
    final id = await kilitliNot('gizli');
    await kasa.kapat();
    final yeni = KasaKontrol(servis: servis, gizlilik: gizlilik, depo: depo);
    await yeni.baslat();
    expect(await yeni.ac(await depo.izle().first), isTrue);
    expect(servis.dogrulamaSayisi, 0);
    expect(yeni.cozulmus(id), 'gizli');
  });

  test('parmak izi iptal edilirse kasa kapalı kalır', () async {
    await kilitliNot('gizli');
    await kasa.kapat();
    servis.iptalEt = true;
    expect(await kasa.ac(await depo.izle().first), isFalse);
    expect(kasa.durum, KasaDurumu.kapali);
  });

  test('geçersiz anahtar: bozuk durumu + uyarı, çökme yok', () async {
    await kilitliNot('gizli');
    await kasa.kapat();
    final yeni = KasaKontrol(
      servis: servis..gecersiz = true,
      gizlilik: gizlilik,
      depo: depo,
    );
    await yeni.baslat();
    expect(await yeni.ac(await depo.izle().first), isFalse);
    expect(yeni.durum, KasaDurumu.bozuk);
    expect(yeni.hata, contains('parmak izi'));
  });

  test('paused ve hidden kapatır, inactive kapatmaz', () async {
    await kilitliNot('gizli');
    await kasa.yasamDegisti(AppLifecycleState.inactive);
    expect(kasa.acik, isTrue);
    await kasa.yasamDegisti(AppLifecycleState.hidden);
    expect(kasa.acik, isFalse);
  });

  test('kapanmadan önce bekleyen kayıt anahtar silinmeden yazılır', () async {
    final id = await kilitliNot('ilk');
    kasa.kapanmadanOnceEkle(() => kasa.kilitliKaydet(id, 'son hali'));
    await kasa.yasamDegisti(AppLifecycleState.paused);
    final yeni = KasaKontrol(servis: servis, gizlilik: gizlilik, depo: depo);
    await yeni.baslat();
    await yeni.ac(await depo.izle().first);
    expect(yeni.cozulmus(id), 'son hali');
  });

  test('kasadan çıkar: düz metin geri gelir', () async {
    final id = await kilitliNot('gizli');
    await kasa.kilidiAc(id);
    final n = (await depo.getir(id))!;
    expect(n.kilitli, isFalse);
    expect(n.icerik, 'gizli');
    expect(await notlar(), hasLength(1));
  });
}
