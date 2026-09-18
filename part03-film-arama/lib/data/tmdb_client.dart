import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/tmdb_config.dart';

/// TMDB için hazırlanmış Dio örneği.
///
/// Üç araya girici (interceptor) var; üçü de güvenlik ya da tekrar
/// yazmama amaçlı:
///   1. [_QueryInterceptor]   — anahtar ve dil her isteğe tek yerden eklenir.
///   2. [HttpsGuardInterceptor] — http:// isteği baştan reddedilir.
///   3. [RedactingLogInterceptor] — sadece geliştirme sırasında, anahtar
///      gizlenmiş hâlde günlük basar.
Dio createTmdbDio({Dio? inner}) {
  final dio = inner ?? Dio();
  dio.options = dio.options.copyWith(
    baseUrl: TmdbConfig.apiBaseUrl,
    connectTimeout: TmdbConfig.connectTimeout,
    receiveTimeout: TmdbConfig.receiveTimeout,
    responseType: ResponseType.json,
  );

  dio.interceptors.addAll([
    HttpsGuardInterceptor(),
    _QueryInterceptor(),
    if (kDebugMode) RedactingLogInterceptor(),
  ]);

  return dio;
}

/// Anahtarı ve dili tek yerden ekler.
///
/// Anahtar hiçbir çağrı yerinde tekrarlanmaz; böylece yanlışlıkla bir
/// dosyaya sabit yazılma ihtimali de kalmaz.
class _QueryInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.queryParameters = {
      'api_key': TmdbConfig.apiKey,
      'language': TmdbConfig.language,
      ...options.queryParameters,
    };
    handler.next(options);
  }
}

/// Şifresiz bağlantıyı engeller.
///
/// TMDB zaten HTTPS veriyor, ama bir gün yanlışlıkla `http://` yazılırsa
/// anahtar ağda açık gider. Bu araya girici o isteği yola çıkmadan keser.
class HttpsGuardInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (options.uri.scheme != 'https') {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
          message: 'Şifresiz (http) istek engellendi: ${options.uri}',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }
}

/// Günlüğe basarken anahtarı yıldızlar.
///
/// Dio'nun hazır `LogInterceptor`'ı tam adresi basıyor; adreste `api_key`
/// var. Ekran görüntüsü alınan bir konsol ya da paylaşılan bir hata kaydı
/// anahtarı sızdırabilir.
class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor({void Function(String message)? log})
      : log = log ?? _printLine;

  final void Function(String message) log;

  static void _printLine(String message) => debugPrint(message);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    log('→ ${options.method} ${redact(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    log('← ${response.statusCode} ${redact(response.requestOptions.uri)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('✗ ${err.type.name} ${redact(err.requestOptions.uri)}');
    handler.next(err);
  }

  /// `api_key=abc123` → `api_key=gizli`
  ///
  /// Yıldız değil düz sözcük: `Uri` yıldızı `%2A` diye kodluyor, günlük
  /// okunmaz hâle geliyordu.
  static const String _mask = 'gizli';

  static String redact(Uri uri) {
    if (!uri.queryParameters.containsKey('api_key')) return uri.toString();
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'api_key': _mask},
    ).toString();
  }
}
