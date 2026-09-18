import 'package:dio/dio.dart';

import '../core/tmdb_config.dart';
import '../core/tmdb_exception.dart';
import '../domain/movie_details.dart';
import '../domain/movie_page.dart';

/// TMDB uçlarının tek giriş kapısı.
///
/// Arayüz katmanı Dio'yu hiç görmez; buradan ya veri ya [TmdbException] çıkar.
class MovieRepository {
  MovieRepository(this._dio);

  final Dio _dio;

  /// Arama kutusu boşken gösterilen liste.
  Future<MoviePage> popular({int page = 1, CancelToken? cancelToken}) {
    return _getPage(
      'movie/popular',
      {'page': page},
      cancelToken: cancelToken,
    );
  }

  /// Arama. Boş sorgu isteğe dönüşmez — boşuna kota harcamayalım.
  Future<MoviePage> search(
    String query, {
    int page = 1,
    CancelToken? cancelToken,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(MoviePage.empty);

    return _getPage(
      'search/movie',
      {
        'query': trimmed,
        'page': page,
        'include_adult': false,
      },
      cancelToken: cancelToken,
    );
  }

  Future<MovieDetails> details(int id, {CancelToken? cancelToken}) async {
    final json = await _get('movie/$id', const {}, cancelToken: cancelToken);
    return MovieDetails.fromJson(json);
  }

  Future<MoviePage> _getPage(
    String path,
    Map<String, Object?> query, {
    CancelToken? cancelToken,
  }) async {
    final json = await _get(path, query, cancelToken: cancelToken);
    return MoviePage.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, Object?> query, {
    CancelToken? cancelToken,
  }) async {
    // Anahtar yoksa isteği hiç kurmuyoruz: 401 beklemek yerine
    // kullanıcıya ne yapacağını söyleyen net hata veriyoruz.
    if (!TmdbConfig.hasKey) throw TmdbException.missingKey;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null) {
        throw const TmdbException(
          TmdbErrorKind.unknown,
          'Sunucudan boş cevap geldi.',
        );
      }
      return data;
    } on DioException catch (error) {
      throw TmdbException.fromDio(error);
    }
  }
}
