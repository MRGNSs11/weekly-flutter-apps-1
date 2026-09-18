import 'package:dio/dio.dart';
import 'package:film_arama/core/tmdb_exception.dart';
import 'package:film_arama/data/movie_repository.dart';
import 'package:film_arama/domain/movie.dart';
import 'package:film_arama/domain/movie_details.dart';
import 'package:film_arama/domain/movie_page.dart';

/// Testlerde gerçek TMDB yerine geçen sahte depo.
///
/// Ağ yok: hangi çağrının kaç kez yapıldığını sayar, istenirse gecikme ve
/// hata üretir. Debounce ve iptal davranışı ancak böyle ölçülebilir.
class FakeMovieRepository extends MovieRepository {
  FakeMovieRepository() : super(Dio());

  /// Yapılan çağrılar, sırasıyla: `popular:1`, `ara:batman:2` ...
  final List<String> calls = [];

  /// Depoya verilen iptal jetonları (iptal gerçekten oldu mu diye bakarız).
  final List<CancelToken?> tokens = [];

  /// Cevap gecikmesi — yarışan istekleri kurgulamak için.
  Duration delay = Duration.zero;

  /// Doluysa her çağrı bu hatayı fırlatır.
  TmdbException? error;

  int pageSize = 3;
  int totalPages = 3;

  @override
  Future<MoviePage> popular({int page = 1, CancelToken? cancelToken}) {
    calls.add('popular:$page');
    return _respond('Popüler', page, cancelToken);
  }

  @override
  Future<MoviePage> search(
    String query, {
    int page = 1,
    CancelToken? cancelToken,
  }) {
    final trimmed = query.trim();
    calls.add('ara:$trimmed:$page');
    if (trimmed.isEmpty) return Future.value(MoviePage.empty);
    return _respond(trimmed, page, cancelToken);
  }

  @override
  Future<MovieDetails> details(int id, {CancelToken? cancelToken}) async {
    calls.add('detay:$id');
    return MovieDetails(
      movie: _movie(id, 'Film $id'),
      genres: const ['Dram'],
      runtimeMinutes: 100,
      tagline: null,
      backdropPath: null,
    );
  }

  Future<MoviePage> _respond(
    String label,
    int page,
    CancelToken? cancelToken,
  ) async {
    tokens.add(cancelToken);

    if (delay > Duration.zero) await Future<void>.delayed(delay);

    // Gerçek Dio da iptal edilmiş istekte böyle davranır.
    if (cancelToken?.isCancelled ?? false) {
      throw const TmdbException(TmdbErrorKind.cancelled, 'İstek iptal edildi.');
    }
    if (error case final failure?) throw failure;

    return MoviePage(
      page: page,
      totalPages: totalPages,
      totalResults: totalPages * pageSize,
      movies: [
        for (var index = 0; index < pageSize; index++)
          _movie(page * 100 + index, '$label $page-$index'),
      ],
    );
  }

  Movie _movie(int id, String title) {
    return Movie(
      id: id,
      title: title,
      posterPath: '/p$id.jpg',
      overview: '',
      voteAverage: 7,
      releaseDate: '2024-01-01',
    );
  }
}
