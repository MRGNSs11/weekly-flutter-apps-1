import 'package:drift/drift.dart';

import '../alan/not.dart';
import 'veritabani.dart';

/// Notları okur ve yazar. Şifrelemeyi bilmez: kilitli not için hazır
/// şifreli baytları alır. Saat dışarıdan verilir (testte sabit saat).
class NotDeposu {
  NotDeposu(this._db, {DateTime Function()? saat})
    : _saat = saat ?? DateTime.now;

  final Veritabani _db;
  final DateTime Function() _saat;

  /// Sabitlenmişler üstte, sonra son güncellenen.
  Stream<List<Not>> izle() {
    final s = _db.select(_db.notlar)
      ..orderBy([
        (t) => OrderingTerm.desc(t.sabit),
        (t) => OrderingTerm.desc(t.guncelleme),
      ]);
    return s.watch().map((satirlar) => satirlar.map(_nota).toList());
  }

  Future<Not?> getir(int id) async {
    final satir = await (_db.select(
      _db.notlar,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return satir == null ? null : _nota(satir);
  }

  Future<int> ekle(String icerik) {
    final simdi = _saat();
    return _db
        .into(_db.notlar)
        .insert(
          NotlarCompanion.insert(
            icerik: Value(icerik),
            olusturma: simdi,
            guncelleme: simdi,
          ),
        );
  }

  Future<void> guncelle(int id, String icerik) => _yaz(
    id,
    NotlarCompanion(icerik: Value(icerik), guncelleme: Value(_saat())),
  );

  /// Kilitli notun yeni şifreli hâli (kasa açıkken düzenleme).
  Future<void> sifreliGuncelle(int id, Uint8List sifreli) => _yaz(
    id,
    NotlarCompanion(sifreli: Value(sifreli), guncelleme: Value(_saat())),
  );

  /// Düz metin silinir, yerine şifreli bayt yazılır.
  Future<void> kilitle(int id, Uint8List sifreli) => _yaz(
    id,
    NotlarCompanion(
      icerik: const Value(null),
      sifreli: Value(sifreli),
      kilitli: const Value(true),
    ),
  );

  Future<void> kilidiAc(int id, String icerik) => _yaz(
    id,
    NotlarCompanion(
      icerik: Value(icerik),
      sifreli: const Value(null),
      kilitli: const Value(false),
    ),
  );

  Future<void> sabitle(int id, bool sabit) =>
      _yaz(id, NotlarCompanion(sabit: Value(sabit)));

  Future<void> sil(int id) =>
      (_db.delete(_db.notlar)..where((t) => t.id.equals(id))).go();

  Future<void> _yaz(int id, NotlarCompanion degisim) =>
      (_db.update(_db.notlar)..where((t) => t.id.equals(id))).write(degisim);

  Not _nota(NotSatiri s) => Not(
    id: s.id,
    icerik: s.icerik,
    sifreli: s.sifreli,
    kilitli: s.kilitli,
    sabit: s.sabit,
    olusturma: s.olusturma,
    guncelleme: s.guncelleme,
  );
}
