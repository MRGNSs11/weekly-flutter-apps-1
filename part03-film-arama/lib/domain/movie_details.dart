import '../core/tmdb_config.dart';
import 'movie.dart';

/// Detay ekranının künyesi. Liste verisinin üstüne tür, süre ve slogan ekler.
class MovieDetails {
  const MovieDetails({
    required this.movie,
    required this.genres,
    required this.runtimeMinutes,
    required this.tagline,
    required this.backdropPath,
  });

  final Movie movie;
  final List<String> genres;
  final int? runtimeMinutes;
  final String? tagline;
  final String? backdropPath;

  String? get backdropUrl => TmdbConfig.backdropUrl(backdropPath);

  /// `142` → `2 sa 22 dk`. Süre yoksa boş dize.
  String get runtimeLabel {
    final minutes = runtimeMinutes;
    if (minutes == null || minutes <= 0) return '';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest dk';
    if (rest == 0) return '$hours sa';
    return '$hours sa $rest dk';
  }

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    final tagline = json['tagline'] as String?;

    return MovieDetails(
      movie: Movie.fromJson(json),
      genres: genres,
      runtimeMinutes: (json['runtime'] as num?)?.toInt(),
      tagline: (tagline == null || tagline.isEmpty) ? null : tagline,
      backdropPath: json['backdrop_path'] as String?,
    );
  }
}
