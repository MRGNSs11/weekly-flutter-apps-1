/// TMDB erişim ayarları.
///
/// ANAHTAR KURALI: API anahtarı bu depoda HİÇBİR dosyada yazılı değildir.
/// Derleme zamanında dışarıdan verilir:
///
///   flutter run --dart-define=TMDB_KEY=buraya_anahtar
///
/// `flutter_dotenv` bilerek kullanılmadı: `.env` dosyası yanlışlıkla
/// commit'lenebilen bir dosyadır ve APK'nın içine varlık (asset) olarak
/// gömülür. `--dart-define` hiç dosya oluşturmaz.
///
/// Dürüst sınır: bu yöntem anahtarı DEPODAN gizler, derlenmiş APK'dan
/// gizlemez — sabit metin ikilinin içinde durur. Gerçek bir üründe anahtar
/// kendi sunucunun arkasında dururdu. Bu uygulama APK olarak dağıtılmıyor.
class TmdbConfig {
  const TmdbConfig._();

  /// Anahtar verilmediyse boş dizedir (derleme hatası vermez).
  static const String apiKey = String.fromEnvironment('TMDB_KEY');

  static bool get hasKey => apiKey.isNotEmpty;

  /// Sadece HTTPS. Bkz. [HttpsGuardInterceptor].
  static const String apiBaseUrl = 'https://api.themoviedb.org/3/';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';

  static const String language = 'tr-TR';

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 8);

  /// Poster adresi. Yol yoksa `null` döner — çağıran yer yer tutucu gösterir.
  static String? posterUrl(String? path, {String size = 'w342'}) {
    if (path == null || path.isEmpty) return null;
    return '$imageBaseUrl$size$path';
  }

  /// Detay ekranının arka planı için geniş görsel.
  static String? backdropUrl(String? path, {String size = 'w780'}) {
    if (path == null || path.isEmpty) return null;
    return '$imageBaseUrl$size$path';
  }
}
