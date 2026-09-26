/// Listedeki tek bir ürün. Firestore'a bağlı değil — veri katmanı
/// belgeyi düz bir Map'e çevirip buraya verir, böylece test edilebilir.
class Urun {
  const Urun({
    required this.id,
    required this.ad,
    required this.alindi,
    required this.ekleyen,
    required this.olusturma,
  });

  /// Güvenlik kuralıyla aynı sınır (`firestore.rules`).
  static const azamiUzunluk = 60;

  final String id;
  final String ad;
  final bool alindi;
  final String ekleyen;
  final DateTime olusturma;

  /// Bozuk ya da eksik alan uygulamayı çökertmesin: makul varsayılana düşer.
  /// `olusturma` henüz sunucudan dönmemişse (yeni eklenen ürün) şimdiki zaman.
  factory Urun.fromMap(String id, Map<String, Object?> veri) => Urun(
    id: id,
    ad: veri['ad'] is String ? veri['ad']! as String : '',
    alindi: veri['alindi'] == true,
    ekleyen: veri['ekleyen'] is String ? veri['ekleyen']! as String : '',
    olusturma: veri['olusturma'] is DateTime
        ? veri['olusturma']! as DateTime
        : DateTime.now(),
  );

  Map<String, Object?> toMap() => {
    'ad': ad,
    'alindi': alindi,
    'ekleyen': ekleyen,
    'olusturma': olusturma,
  };

  /// Kullanıcının yazdığı adı temizler: baştaki/sondaki boşluk atılır,
  /// aradaki çoklu boşluk teke iner. Boşsa ya da sınırı aşıyorsa null.
  static String? adiDuzelt(String ham) {
    final temiz = ham.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (temiz.isEmpty || temiz.length > azamiUzunluk) return null;
    return temiz;
  }

  /// Alınmayanlar üstte, alınanlar altta; her grubun içinde yeni olan önce.
  static List<Urun> sirala(Iterable<Urun> urunler) {
    final liste = urunler.toList();
    liste.sort((a, b) {
      if (a.alindi != b.alindi) return a.alindi ? 1 : -1;
      return b.olusturma.compareTo(a.olusturma);
    });
    return liste;
  }
}
