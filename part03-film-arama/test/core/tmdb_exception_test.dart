import 'package:dio/dio.dart';
import 'package:film_arama/core/tmdb_exception.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int status) {
  final options = RequestOptions(path: 'movie/popular');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

DioException _ofType(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(path: 'movie/popular'),
    type: type,
  );
}

void main() {
  group('TmdbException.fromDio', () {
    test('401 → anahtar hatası', () {
      expect(
        TmdbException.fromDio(_badResponse(401)).kind,
        TmdbErrorKind.unauthorized,
      );
    });

    test('429 → kota hatası', () {
      expect(
        TmdbException.fromDio(_badResponse(429)).kind,
        TmdbErrorKind.rateLimited,
      );
    });

    test('503 → sunucu hatası', () {
      expect(
        TmdbException.fromDio(_badResponse(503)).kind,
        TmdbErrorKind.server,
      );
    });

    test('iptal edilen istek hata olarak gösterilmez', () {
      final error = TmdbException.fromDio(_ofType(DioExceptionType.cancel));

      expect(error.kind, TmdbErrorKind.cancelled);
      expect(error.isCancellation, isTrue);
    });

    test('zaman aşımı ayrı bir tür', () {
      expect(
        TmdbException.fromDio(_ofType(DioExceptionType.receiveTimeout)).kind,
        TmdbErrorKind.timeout,
      );
    });

    test('mesajlar kullanıcıya gösterilecek kadar sade', () {
      for (final error in [
        TmdbException.fromDio(_badResponse(401)),
        TmdbException.fromDio(_badResponse(500)),
        TmdbException.fromDio(_ofType(DioExceptionType.connectionError)),
      ]) {
        expect(error.message, isNotEmpty);
        expect(
          error.message.toLowerCase(),
          isNot(contains('dio')),
          reason: 'teknik terim sızmamalı',
        );
      }
    });
  });
}
