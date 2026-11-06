import 'package:drift/drift.dart';

import '../alan/dalga.dart';
import '../alan/kayit.dart';
import 'veritabani.dart';

/// Kayıtları okur ve yazar. Ses dosyasına dokunmaz: dosyanın silinmesi
/// "Geri al" süresi bitince yukarıdaki katmanın işi.
/// Saat dışarıdan verilir (testte sabit saat).
class KayitDeposu {
  KayitDeposu(this._db, {DateTime Function()? saat})
    : _saat = saat ?? DateTime.now;

  final Veritabani _db;
  final DateTime Function() _saat;

  /// Yeni kayıt üstte.
  Stream<List<Kayit>> izle() {
    final s = _db.select(_db.kayitlar)
      ..orderBy([
        (t) => OrderingTerm.desc(t.olusturma),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return s.watch().map((satirlar) => satirlar.map(_kayda).toList());
  }

  Future<Kayit?> getir(int id) async {
    final satir = await (_db.select(
      _db.kayitlar,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return satir == null ? null : _kayda(satir);
  }

  /// Kayıt bitince çağrılır. [olusturma] verilmezse şimdiki an.
  Future<int> ekle({
    required String ad,
    required String dosyaYolu,
    required Duration sure,
    required int boyutBayt,
    required List<double> dalga,
    DateTime? olusturma,
  }) => _db
      .into(_db.kayitlar)
      .insert(
        KayitlarCompanion.insert(
          ad: ad,
          dosyaYolu: dosyaYolu,
          sureMs: sure.inMilliseconds,
          boyutBayt: boyutBayt,
          olusturma: olusturma ?? _saat(),
          dalga: kodla(dalga),
        ),
      );

  Future<void> adDegistir(int id, String ad) => (_db.update(
    _db.kayitlar,
  )..where((t) => t.id.equals(id))).write(KayitlarCompanion(ad: Value(ad)));

  /// Satırı siler ve silineni döndürür ("Geri al" için). Yoksa `null`.
  Future<Kayit?> sil(int id) => _db.transaction(() async {
    final kayit = await getir(id);
    if (kayit != null) {
      await (_db.delete(_db.kayitlar)..where((t) => t.id.equals(id))).go();
    }
    return kayit;
  });

  /// "Geri al": silinen kayıt aynı kimlikle geri gelir.
  Future<void> geriEkle(Kayit k) => _db
      .into(_db.kayitlar)
      .insert(
        KayitlarCompanion.insert(
          id: Value(k.id),
          ad: k.ad,
          dosyaYolu: k.dosyaYolu,
          sureMs: k.sure.inMilliseconds,
          boyutBayt: k.boyutBayt,
          olusturma: k.olusturma,
          dalga: kodla(k.dalga),
        ),
      );

  Kayit _kayda(KayitSatiri s) => Kayit(
    id: s.id,
    ad: s.ad,
    dosyaYolu: s.dosyaYolu,
    sure: Duration(milliseconds: s.sureMs),
    boyutBayt: s.boyutBayt,
    olusturma: s.olusturma,
    dalga: coz(s.dalga),
  );
}
