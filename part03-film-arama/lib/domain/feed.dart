import 'movie.dart';
import 'movie_page.dart';

/// Arama ekranının tuttuğu bütün durum.
///
/// Tek bir sınıf, çünkü "hangi sorgu", "kaçıncı sayfa" ve "elimizdeki
/// filmler" birbirinden ayrı düşünülemez; ayrı tutulursa listeyle sayfa
/// numarası birbirini tutmaz hâle gelir.
class Feed {
  const Feed({
    required this.query,
    required this.movies,
    required this.page,
    required this.totalPages,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// Boş dize = arama yapılmadı, popüler filmler gösteriliyor.
  final String query;

  final List<Movie> movies;
  final int page;
  final int totalPages;

  /// Alt sayfa yükleniyor (ilk yükleme değil — liste zaten ekranda).
  final bool loadingMore;

  /// Alt sayfa yüklenirken çıkan hata. Listeyi silmeyiz, altta uyarı gösteririz.
  final String? loadMoreError;

  bool get isSearching => query.isNotEmpty;
  bool get hasMore => page < totalPages;
  bool get isEmpty => movies.isEmpty;

  static const Feed initial = Feed(
    query: '',
    movies: [],
    page: 1,
    totalPages: 1,
  );

  factory Feed.firstPage(String query, MoviePage page) {
    return Feed(
      query: query,
      movies: page.movies,
      page: page.page,
      totalPages: page.totalPages,
    );
  }

  /// Sonraki sayfayı ekler.
  ///
  /// TMDB aynı filmi iki sayfada birden döndürebiliyor (liste sunucuda
  /// sürekli değişiyor); aynı id iki kez eklenirse Flutter'ın liste
  /// anahtarları çakışır. Bu yüzden id'ye göre eliyoruz.
  Feed append(MoviePage next) {
    final seen = {for (final movie in movies) movie.id};
    final merged = [
      ...movies,
      ...next.movies.where((movie) => seen.add(movie.id)),
    ];

    return Feed(
      query: query,
      movies: merged,
      page: next.page,
      totalPages: next.totalPages,
    );
  }

  Feed copyWith({bool? loadingMore, String? loadMoreError}) {
    return Feed(
      query: query,
      movies: movies,
      page: page,
      totalPages: totalPages,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
    );
  }
}
