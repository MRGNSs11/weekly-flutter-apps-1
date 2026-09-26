import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'kod.dart';
import 'urun.dart';

/// Bir ortak liste: kimin üye olduğu ve katılma kodu.
class Liste {
  const Liste({required this.id, required this.kod, required this.uyeler});

  final String id;
  final String kod;
  final List<String> uyeler;
}

/// Katılma ya da oluşturma sırasında kullanıcıya gösterilecek hata.
class ListeHatasi implements Exception {
  const ListeHatasi(this.mesaj);
  final String mesaj;
  @override
  String toString() => mesaj;
}

/// Firebase'e dokunan TEK yer. Ekranlar Firestore'u doğrudan görmez.
///
/// Her yazma `firestore.rules`'taki bir kurala karşılık geliyor; alan adı ya da
/// yazma biçimi değişirse kural testleri (kural-testi/) kırılır.
class ListeDeposu {
  ListeDeposu({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String get uid => _auth.currentUser!.uid;

  /// Hesap yok: ilk açılışta sessizce anonim kimlik alınır, sonraki
  /// açılışlarda aynı kimlik kullanılır (Firebase cihazda saklıyor).
  Future<void> oturumAc() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  CollectionReference<Map<String, dynamic>> get _listeler =>
      _db.collection('listeler');

  /// Üyesi olduğum liste; yoksa null. Telefonda "hangi listedeyim" kaydı
  /// tutulmuyor, soru her açılışta Firestore'a soruluyor.
  Stream<Liste?> listemAkisi() => _listeler
      .where('uyeler', arrayContains: uid)
      .limit(1)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final d = s.docs.first;
        return Liste(
          id: d.id,
          kod: d.data()['kod'] as String? ?? '',
          uyeler: List<String>.from(d.data()['uyeler'] as List? ?? const []),
        );
      });

  /// Yeni liste + kodu tek toplu yazmada. Kod başka listede kullanılıyorsa
  /// kural yazmayı reddeder (bkz. firestore.rules → kodlar); yeni kodla
  /// en fazla 5 kez denenir.
  Future<void> olustur() async {
    for (var deneme = 0; deneme < 5; deneme++) {
      final kod = Kod.uret();
      final liste = _listeler.doc();
      final toplu = _db.batch()
        ..set(liste, {
          'uyeler': [uid],
          'kod': kod,
          'olusturan': uid,
          'olusturma': FieldValue.serverTimestamp(),
        })
        ..set(_db.collection('kodlar').doc(kod), {'listeId': liste.id});
      try {
        await toplu.commit();
        return;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') throw _agHatasi(e);
      }
    }
    throw const ListeHatasi('Liste açılamadı. Birazdan tekrar dene.');
  }

  /// Kodla katılma: kendini üyelere ekle + "kodu biliyorum" kanıtını yaz.
  /// İkisi aynı toplu yazmada gitmezse kural reddeder.
  Future<void> katil(String hamKod) async {
    final kod = Kod.normalize(hamKod);
    if (!Kod.gecerliMi(kod)) {
      throw const ListeHatasi('Kod 6 haneli olmalı.');
    }
    final DocumentSnapshot<Map<String, dynamic>> kodBelgesi;
    try {
      kodBelgesi = await _db
          .collection('kodlar')
          .doc(kod)
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      throw _agHatasi(e);
    }
    final listeId = kodBelgesi.data()?['listeId'];
    if (listeId is! String) {
      throw const ListeHatasi('Bu kodla bir liste yok.');
    }
    final liste = _listeler.doc(listeId);
    final toplu = _db.batch()
      ..update(liste, {
        'uyeler': FieldValue.arrayUnion([uid]),
      })
      ..set(liste.collection('katilimlar').doc(uid), {'kod': kod});
    try {
      await toplu.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ListeHatasi(
          'Katılamadın. Liste dolu olabilir (en fazla 10 kişi).',
        );
      }
      throw _agHatasi(e);
    }
  }

  /// Listeden çık. Liste ve ürünler öbür üyeler için durmaya devam eder.
  Future<void> ayril(Liste liste) => _listeler.doc(liste.id).update({
    'uyeler': FieldValue.arrayRemove([uid]),
  });

  CollectionReference<Map<String, dynamic>> _urunler(String listeId) =>
      _listeler.doc(listeId).collection('urunler');

  /// Ürünler (sırasız; sıralama ekranda). Yeni eklenen ürünün zamanı
  /// sunucudan dönene kadar null gelir, Urun.fromMap onu "şimdi" sayar —
  /// böylece yeni ürün hemen en üstte görünür.
  Stream<List<Urun>> urunAkisi(String listeId) =>
      _urunler(listeId).snapshots().map(
        (s) => s.docs.map((d) {
          final veri = d.data();
          final zaman = veri['olusturma'];
          return Urun.fromMap(d.id, {
            ...veri,
            'olusturma': zaman is Timestamp ? zaman.toDate() : null,
          });
        }).toList(),
      );

  // Ürün yazmaları beklenmiyor (await yok): internet yokken de ekran
  // hemen güncellenir, Firestore bağlantı gelince gönderir.

  void ekle(String listeId, String ad) {
    _urunler(listeId).add({
      'ad': ad,
      'alindi': false,
      'ekleyen': uid,
      'olusturma': FieldValue.serverTimestamp(),
    });
  }

  void isaretle(String listeId, Urun urun) {
    _urunler(listeId).doc(urun.id).update({'alindi': !urun.alindi});
  }

  void sil(String listeId, Urun urun) {
    _urunler(listeId).doc(urun.id).delete();
  }

  ListeHatasi _agHatasi(FirebaseException e) => switch (e.code) {
    'unavailable' => const ListeHatasi(
      'İnternet yok gibi. Bağlanınca tekrar dene.',
    ),
    _ => ListeHatasi('Bir sorun çıktı (${e.code}).'),
  };
}
