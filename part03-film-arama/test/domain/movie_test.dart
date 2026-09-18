import 'package:film_arama/domain/movie.dart';
import 'package:film_arama/domain/movie_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Movie.fromJson', () {
    test('tam kayıt okunur', () {
      final movie = Movie.fromJson(const {
        'id': 27205,
        'title': 'Başlangıç',
        'original_title': 'Inception',
        'poster_path': '/poster.jpg',
        'overview': 'Rüya içinde rüya.',
        'vote_average': 8.4,
        'release_date': '2010-07-15',
      });

      expect(movie.id, 27205);
      expect(movie.title, 'Başlangıç');
      expect(movie.year, '2010');
      expect(movie.hasVote, isTrue);
      expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w342/poster.jpg');
    });

    test('Türkçe başlık boşsa özgün başlığa düşer', () {
      final movie = Movie.fromJson(const {
        'id': 1,
        'title': '',
        'original_title': 'Dune',
        'vote_average': 0,
        'overview': '',
      });

      expect(movie.title, 'Dune');
    });

    test('poster ve tarih yoksa çökmez', () {
      final movie = Movie.fromJson(const {
        'id': 2,
        'title': 'Gizemli Film',
        'poster_path': null,
        'release_date': '',
        'vote_average': 0,
        'overview': '',
      });

      expect(movie.posterUrl, isNull);
      expect(movie.year, '');
      expect(movie.hasVote, isFalse, reason: 'puansız filmde 0.0 gösterilmez');
    });

    test('puan tam sayı geldiğinde de okunur', () {
      final movie = Movie.fromJson(const {
        'id': 3,
        'title': 'Film',
        'vote_average': 7,
        'overview': '',
      });

      expect(movie.voteAverage, 7.0);
    });
  });

  group('MoviePage.fromJson', () {
    test('sayfa bilgisi ve sonuçlar okunur', () {
      final page = MoviePage.fromJson(const {
        'page': 2,
        'total_pages': 13,
        'total_results': 250,
        'results': [
          {'id': 1, 'title': 'Bir', 'vote_average': 5, 'overview': ''},
          {'id': 2, 'title': 'İki', 'vote_average': 6, 'overview': ''},
        ],
      });

      expect(page.movies, hasLength(2));
      expect(page.hasMore, isTrue);
    });

    test('son sayfada hasMore kapanır', () {
      final page = MoviePage.fromJson(const {
        'page': 4,
        'total_pages': 4,
        'total_results': 70,
        'results': <Map<String, dynamic>>[],
      });

      expect(page.hasMore, isFalse);
    });

    test('TMDB 500 sayfadan ötesini vermediği için üst sınır kırpılır', () {
      final page = MoviePage.fromJson(const {
        'page': 1,
        'total_pages': 40000,
        'total_results': 800000,
        'results': <Map<String, dynamic>>[],
      });

      expect(page.totalPages, 500);
    });
  });
}
