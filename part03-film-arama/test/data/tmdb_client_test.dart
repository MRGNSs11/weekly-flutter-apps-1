import 'package:dio/dio.dart';
import 'package:film_arama/core/tmdb_exception.dart';
import 'package:film_arama/data/movie_repository.dart';
import 'package:film_arama/data/tmdb_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpsGuardInterceptor', () {
    test('http isteği ağa çıkmadan reddedilir', () async {
      final dio = Dio()..interceptors.add(HttpsGuardInterceptor());

      await expectLater(
        dio.get<dynamic>('http://api.themoviedb.org/3/movie/popular'),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.badCertificate,
          ),
        ),
      );
    });
  });

  group('RedactingLogInterceptor.redact', () {
    test('anahtar günlüğe yazılmaz', () {
      final uri = Uri.parse(
        'https://api.themoviedb.org/3/movie/popular'
        '?api_key=0123456789abcdef0123456789abcdef&page=1',
      );

      final redacted = RedactingLogInterceptor.redact(uri);

      expect(redacted, contains('api_key=gizli'));
      expect(redacted, isNot(contains('0123456789abcdef')));
      expect(redacted, contains('page=1'), reason: 'diğer alanlar kalmalı');
    });

    test('anahtarsız adres olduğu gibi kalır', () {
      final uri = Uri.parse('https://image.tmdb.org/t/p/w342/poster.jpg');

      expect(RedactingLogInterceptor.redact(uri), uri.toString());
    });
  });

  group('MovieRepository', () {
    test('boş sorgu isteğe dönüşmez', () async {
      // Dio'ya hiç dokunulmadığının kanıtı: ağ kapalı olsa da çalışır.
      final page = await MovieRepository(Dio()).search('   ');

      expect(page.movies, isEmpty);
    });

    test('anahtar verilmeden çalıştırılırsa ne yapılacağını söyler', () async {
      // Testler --dart-define olmadan koşar, yani TMDB_KEY boştur.
      await expectLater(
        MovieRepository(Dio()).popular(),
        throwsA(
          isA<TmdbException>().having(
            (error) => error.kind,
            'kind',
            TmdbErrorKind.missingKey,
          ),
        ),
      );
    });
  });
}
