import 'movie.dart';

/// Sayfalanmış liste cevabı. Sonsuz kaydırma buna bakar.
class MoviePage {
  const MoviePage({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.movies,
  });

  final int page;
  final int totalPages;
  final int totalResults;
  final List<Movie> movies;

  bool get hasMore => page < totalPages;

  static const MoviePage empty = MoviePage(
    page: 1,
    totalPages: 1,
    totalResults: 0,
    movies: [],
  );

  factory MoviePage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromJson)
        .toList(growable: false);

    return MoviePage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      // TMDB sayfalamayı 500. sayfada durduruyor; daha ötesini istersek
      // 422 dönüyor. Bu yüzden üst sınırı burada kırpıyoruz.
      totalPages: ((json['total_pages'] as num?)?.toInt() ?? 1).clamp(1, 500),
      totalResults: (json['total_results'] as num?)?.toInt() ?? results.length,
      movies: results,
    );
  }
}
