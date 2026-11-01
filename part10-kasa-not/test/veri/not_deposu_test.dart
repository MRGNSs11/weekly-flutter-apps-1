import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/veri/not_deposu.dart';
import 'package:kasa_not/veri/veritabani.dart';

void main() {
  late Veritabani db;
  late NotDeposu depo;
  var saat = DateTime(2026, 11, 1, 10);

  setUp(() {
    db = Veritabani.test(NativeDatabase.memory());
    depo = NotDeposu(db, saat: () => saat);
  });
  tearDown(() => db.close());

  test('ekle ve getir', () async {
    final id = await depo.ekle('# Market');
    final not = await depo.getir(id);
    expect(not!.icerik, '# Market');
    expect(not.kilitli, isFalse);
  });

  test('güncelle içeriği ve tarihi değiştirir', () async {
    final id = await depo.ekle('a');
    saat = DateTime(2026, 11, 1, 11);
    await depo.guncelle(id, 'b');
    final not = await depo.getir(id);
    expect(not!.icerik, 'b');
    expect(not.guncelleme, DateTime(2026, 11, 1, 11));
  });

  test('sil', () async {
    final id = await depo.ekle('a');
    await depo.sil(id);
    expect(await depo.getir(id), isNull);
  });

  test('kilitle: düz metin veritabanında kalmaz', () async {
    final id = await depo.ekle('gizli metin');
    await depo.kilitle(id, Uint8List.fromList([9, 9, 9]));
    final satir = await db
        .customSelect(
          'SELECT icerik, sifreli, kilitli FROM notlar WHERE id = ?',
          variables: [Variable.withInt(id)],
        )
        .getSingle();
    expect(satir.data['icerik'], isNull);
    expect(satir.data['sifreli'], isNotNull);
    expect(satir.data['kilitli'], 1);
  });

  test('kilidi aç: içerik geri gelir, şifreli silinir', () async {
    final id = await depo.ekle('x');
    await depo.kilitle(id, Uint8List.fromList([1]));
    await depo.kilidiAc(id, 'x');
    final not = await depo.getir(id);
    expect(not!.icerik, 'x');
    expect(not.sifreli, isNull);
    expect(not.kilitli, isFalse);
  });

  test('liste: sabit üstte, sonra en yeni', () async {
    saat = DateTime(2026, 11, 1, 1);
    final eski = await depo.ekle('eski');
    saat = DateTime(2026, 11, 1, 2);
    await depo.ekle('yeni');
    await depo.sabitle(eski, true);
    final liste = await depo.izle().first;
    expect(liste.map((n) => n.icerik), ['eski', 'yeni']);
  });
}
