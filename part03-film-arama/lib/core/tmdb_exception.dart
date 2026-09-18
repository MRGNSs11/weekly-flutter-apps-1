import 'package:dio/dio.dart';

/// Kullanıcıya ne söyleneceğini belirleyen hata türleri.
///
/// Amaç: ekranda "DioException [bad response]" gibi bir şey ASLA görünmesin.
/// Her tür, kullanıcının anlayacağı tek bir cümleye karşılık gelir.
enum TmdbErrorKind {
  /// `--dart-define=TMDB_KEY=...` verilmeden çalıştırılmış.
  missingKey,

  /// İnternet yok ya da sunucuya ulaşılamıyor.
  noConnection,

  /// Bağlantı var ama sunucu zamanında cevap vermedi.
  timeout,

  /// Anahtar yanlış ya da iptal edilmiş (HTTP 401 / 403).
  unauthorized,

  /// Çok fazla istek (HTTP 429).
  rateLimited,

  /// Aranan kayıt yok (HTTP 404).
  notFound,

  /// TMDB tarafında sorun (HTTP 5xx).
  server,

  /// Yeni arama başladığı için önceki istek iptal edildi. Hata SAYILMAZ,
  /// arayüzde gösterilmez.
  cancelled,

  unknown,
}

class TmdbException implements Exception {
  const TmdbException(this.kind, this.message);

  final TmdbErrorKind kind;

  /// Doğrudan ekranda gösterilebilecek Türkçe metin.
  final String message;

  static const TmdbException missingKey = TmdbException(
    TmdbErrorKind.missingKey,
    'TMDB anahtarı verilmedi. Uygulamayı şöyle çalıştır:\n'
    'flutter run --dart-define=TMDB_KEY=anahtarin',
  );

  /// Dio'nun teknik hatasını kullanıcı diline çevirir.
  factory TmdbException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return const TmdbException(
          TmdbErrorKind.cancelled,
          'İstek iptal edildi.',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TmdbException(
          TmdbErrorKind.timeout,
          'Sunucu zamanında cevap vermedi. Tekrar dener misin?',
        );
      case DioExceptionType.connectionError:
        return const TmdbException(
          TmdbErrorKind.noConnection,
          'İnternet bağlantısı kurulamadı.',
        );
      case DioExceptionType.badCertificate:
        return const TmdbException(
          TmdbErrorKind.noConnection,
          'Güvenli bağlantı doğrulanamadı.',
        );
      case DioExceptionType.badResponse:
        return TmdbException._fromStatus(error.response?.statusCode);
      case DioExceptionType.unknown:
        return const TmdbException(
          TmdbErrorKind.unknown,
          'Beklenmeyen bir sorun çıktı.',
        );
    }
  }

  factory TmdbException._fromStatus(int? status) {
    switch (status) {
      case 401:
      case 403:
        return const TmdbException(
          TmdbErrorKind.unauthorized,
          'TMDB anahtarı kabul edilmedi. Anahtarı kontrol et.',
        );
      case 404:
        return const TmdbException(
          TmdbErrorKind.notFound,
          'Aradığın kayıt bulunamadı.',
        );
      case 429:
        return const TmdbException(
          TmdbErrorKind.rateLimited,
          'Çok fazla istek gönderildi. Birkaç saniye bekle.',
        );
      default:
        if (status != null && status >= 500) {
          return const TmdbException(
            TmdbErrorKind.server,
            'TMDB şu an cevap veremiyor. Sonra tekrar dene.',
          );
        }
        return const TmdbException(
          TmdbErrorKind.unknown,
          'Beklenmeyen bir sorun çıktı.',
        );
    }
  }

  /// Yeni arama başladığı için iptal edilen istekler kullanıcıya
  /// hata olarak gösterilmez.
  bool get isCancellation => kind == TmdbErrorKind.cancelled;

  @override
  String toString() => 'TmdbException(${kind.name}): $message';
}
