import '../core/tmdb_config.dart';

/// Listede gösterilen film. TMDB'nin liste uçları bu alanları döner.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;

  String? get posterUrl => TmdbConfig.posterUrl(posterPath);

  /// `2024-03-15` → `2024`. Tarih yoksa boş dize.
  String get year {
    final date = releaseDate;
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  /// Puanı hiç yoksa TMDB 0 döner; "0.0" göstermek yanıltıcı olur.
  bool get hasVote => voteAverage > 0;

  /// Favorilerin cihazda saklanması için. TMDB'nin alan adlarıyla aynı
  /// yazılır ki [Movie.fromJson] ikisini de okuyabilsin.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'vote_average': voteAverage,
      'release_date': releaseDate,
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      // TMDB bazı kayıtlarda Türkçe başlık vermez, boş dize döner.
      title: _nonEmpty(json['title']) ??
          _nonEmpty(json['original_title']) ??
          'Adsız film',
      posterPath: json['poster_path'] as String?,
      overview: (json['overview'] as String?) ?? '',
      voteAverage: _toDouble(json['vote_average']),
      releaseDate: _nonEmpty(json['release_date']),
    );
  }
}

String? _nonEmpty(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}

/// TMDB puanı bazen `7` (int), bazen `7.3` (double) döner.
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return 0;
}
