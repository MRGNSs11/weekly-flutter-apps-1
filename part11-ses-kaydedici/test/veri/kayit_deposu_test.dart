import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/veri/kayit_deposu.dart';
import 'package:ses_kaydedici/veri/veritabani.dart';

void main() {
  late Veritabani db;
  late KayitDeposu depo;
  var saat = DateTime(2026, 11, 6, 10);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = Veritabani.test(NativeDatabase.memory());
    depo = KayitDeposu(db, saat: () => saat);
  });
  tearDown(() => db.close());

  Future<int> ekle(String ad, {List<double> dalga = const [.1, .5, 1]}) =>
      depo.ekle(
        ad: ad,
        dosyaYolu: '/kayitlar/$ad.ogg',
        sure: const Duration(minutes: 4, seconds: 48),
        boyutBayt: 1258291,
        dalga: dalga,
      );

  test('ekle ve getir: tüm alanlar geri gelir', () async {
    final id = await ekle('Fizik dersi');
    final k = await depo.getir(id);
    expect(k!.ad, 'Fizik dersi');
    expect(k.dosyaYolu, '/kayitlar/Fizik dersi.ogg');
    expect(k.sure, const Duration(minutes: 4, seconds: 48));
    expect(k.boyutBayt, 1258291);
    expect(k.olusturma, DateTime(2026, 11, 6, 10));
    expect(k.dalga, hasLength(3));
    expect(k.dalga[1], closeTo(.5, 1 / 255));
  });

  test('uzun dalga saklanır (1 saat = 72 000 örnek)', () async {
    final id = await ekle('uzun', dalga: List.filled(72000, .3));
    expect((await depo.getir(id))!.dalga, hasLength(72000));
  });

  test('liste: yeni kayıt üstte', () async {
    await ekle('ilk');
    saat = DateTime(2026, 11, 6, 11);
    await ekle('ikinci');
    final liste = await depo.izle().first;
    expect(liste.map((k) => k.ad), ['ikinci', 'ilk']);
  });

  test('aynı saniyede iki kayıt: sonraki üstte', () async {
    await ekle('a');
    await ekle('b');
    expect((await depo.izle().first).map((k) => k.ad), ['b', 'a']);
  });

  test('ad değiştir', () async {
    final id = await ekle('6 Kas 10:00');
    await depo.adDegistir(id, 'Fizik dersi — hafta 6');
    expect((await depo.getir(id))!.ad, 'Fizik dersi — hafta 6');
  });

  test('sil silineni döndürür, geri al aynı kimlikle geri getirir', () async {
    final id = await ekle('Market listesi');
    await ekle('Toplantı');
    final silinen = await depo.sil(id);
    expect(silinen!.ad, 'Market listesi');
    expect(await depo.getir(id), isNull);
    expect((await depo.izle().first).map((k) => k.ad), ['Toplantı']);

    await depo.geriEkle(silinen);
    final geri = await depo.getir(id);
    expect(geri!.ad, 'Market listesi');
    expect(geri.olusturma, silinen.olusturma);
    expect(geri.dalga, hasLength(3));
  });

  test('olmayan kaydı silmek null', () async {
    expect(await depo.sil(999), isNull);
  });

  test('liste akışı değişiklikte yeniden yayınlar', () async {
    final gorulen = <int>[];
    final abone = depo.izle().listen((l) => gorulen.add(l.length));
    Future<void> bekle() => Future.delayed(const Duration(milliseconds: 50));
    await bekle();
    final id = await ekle('a');
    await bekle();
    await depo.sil(id);
    await bekle();
    await abone.cancel();
    expect(gorulen, [0, 1, 0]);
  });
}
