/// Kasa anahtarının telefondaki güvenli bölgeyle konuşan kısmı.
///
/// Soyut: testte sahtesi kullanılır, gerçeği [YerelKasaServisi].
abstract class KasaServisi {
  /// Telefonda ekran kilidi / parmak izi var mı? Yoksa kasa kullanılamaz.
  Future<bool> cihazUygun();

  /// Anahtar daha önce oluşturulmuş mu? Parmak izi istemez.
  Future<bool> anahtarVar();

  /// Yeni anahtar üretir ve parmak izine bağlı olarak saklar.
  Future<List<int>> anahtarOlustur();

  /// Parmak izi ister, anahtarı döndürür. İptalde [KasaIptal] fırlatır.
  Future<List<int>> anahtariOku();

  /// Yalnız parmak izi doğrulaması (anahtar okumadan).
  Future<bool> dogrula();
}

/// Kullanıcı parmak izi penceresini kapattı.
class KasaIptal implements Exception {
  const KasaIptal();
}

/// Anahtar artık açılamıyor (ör. telefona yeni parmak izi eklendi).
class AnahtarGecersiz implements Exception {
  const AnahtarGecersiz(this.ayrinti);
  final String ayrinti;
}

/// Son uygulamalar ekranındaki önizlemeyi gizler/gösterir.
abstract class Gizlilik {
  Future<void> onizlemeyiGizle(bool gizle);
}
