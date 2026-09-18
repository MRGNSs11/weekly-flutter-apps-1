import 'dart:async';

import 'package:film_arama/core/tmdb_exception.dart';
import 'package:film_arama/domain/feed.dart';
import 'package:film_arama/providers.dart';
import 'package:film_arama/state/movie_feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMovieRepository();
    container = ProviderContainer(
      overrides: [movieRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  MovieFeedNotifier notifier() => container.read(movieFeedProvider.notifier);
  Feed? feed() => container.read(movieFeedProvider).value;

  /// Debounce süresinin dolmasını bekler.
  Future<void> waitDebounce() =>
      Future<void>.delayed(kSearchDebounce + const Duration(milliseconds: 80));

  test('açılışta popüler filmler yüklenir', () async {
    await container.read(movieFeedProvider.future);

    expect(repository.calls, ['popular:1']);
    expect(feed()!.isSearching, isFalse);
    expect(feed()!.movies, hasLength(3));
  });

  group('debounce', () {
    test('hızlı yazılan harfler tek isteğe düşer', () async {
      await container.read(movieFeedProvider.future);
      repository.calls.clear();

      // Kullanıcı "bat", "batm", "batman" yazıyor — aralarda 400 ms yok.
      notifier().onQueryChanged('bat');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      notifier().onQueryChanged('batm');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      notifier().onQueryChanged('batman');

      await waitDebounce();

      expect(repository.calls, ['ara:batman:1'],
          reason: 'sadece son sorgu ağa çıkmalı');
    });

    test('yazmayı bırakınca istek gerçekten atılır', () async {
      await container.read(movieFeedProvider.future);
      repository.calls.clear();

      notifier().onQueryChanged('dune');
      expect(repository.calls, isEmpty, reason: 'daha bekleme süresi dolmadı');

      await waitDebounce();

      expect(repository.calls, ['ara:dune:1']);
      expect(feed()!.query, 'dune');
    });

    test('aynı sorgu ikinci kez istek doğurmaz', () async {
      await container.read(movieFeedProvider.future);
      await waitDebounce();
      notifier().onQueryChanged('dune');
      await waitDebounce();
      repository.calls.clear();

      notifier().onQueryChanged('  dune  ');
      await waitDebounce();

      expect(repository.calls, isEmpty);
    });
  });

  group('istek iptali', () {
    test('yeni arama başlayınca önceki istek iptal edilir', () async {
      await container.read(movieFeedProvider.future);
      repository.calls.clear();
      repository.tokens.clear();
      repository.delay = const Duration(milliseconds: 200);

      unawaited(notifier().search('ilk'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      unawaited(notifier().search('ikinci'));

      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.tokens.first!.isCancelled, isTrue);
      expect(feed()!.query, 'ikinci',
          reason: 'geç gelen eski cevap yeni sonuçların üstüne yazmamalı');
      expect(feed()!.movies.first.title, startsWith('ikinci'));
    });
  });

  group('sayfalama', () {
    test('loadMore sonraki sayfayı listeye ekler', () async {
      await container.read(movieFeedProvider.future);

      await notifier().loadMore();

      expect(repository.calls, ['popular:1', 'popular:2']);
      expect(feed()!.movies, hasLength(6));
      expect(feed()!.page, 2);
      expect(feed()!.loadingMore, isFalse);
    });

    test('son sayfadan sonra istek atılmaz', () async {
      repository.totalPages = 2;
      await container.read(movieFeedProvider.future);

      await notifier().loadMore();
      repository.calls.clear();
      await notifier().loadMore();

      expect(feed()!.hasMore, isFalse);
      expect(repository.calls, isEmpty);
    });

    test('sayfa hatası listeyi silmez, uyarı gösterir', () async {
      await container.read(movieFeedProvider.future);
      final before = feed()!.movies.length;

      repository.error = const TmdbException(
        TmdbErrorKind.noConnection,
        'İnternet bağlantısı kurulamadı.',
      );
      await notifier().loadMore();

      expect(feed()!.movies, hasLength(before), reason: 'liste korunmalı');
      expect(feed()!.loadMoreError, 'İnternet bağlantısı kurulamadı.');
      expect(feed()!.loadingMore, isFalse);
    });
  });

  group('hata', () {
    test('arama hatası kullanıcı mesajıyla durur', () async {
      await container.read(movieFeedProvider.future);
      repository.error = const TmdbException(
        TmdbErrorKind.server,
        'TMDB şu an cevap veremiyor. Sonra tekrar dene.',
      );

      await notifier().search('hata');

      final state = container.read(movieFeedProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error! as TmdbException).message,
        'TMDB şu an cevap veremiyor. Sonra tekrar dene.',
      );
    });

    test('hatadan sonra tekrar dene aynı sorguyu yeniden çalıştırır', () async {
      await container.read(movieFeedProvider.future);
      repository.error = const TmdbException(
        TmdbErrorKind.timeout,
        'Sunucu zamanında cevap vermedi. Tekrar dener misin?',
      );
      await notifier().search('dune');

      repository.error = null;
      repository.calls.clear();
      await notifier().retry();

      expect(repository.calls, ['ara:dune:1']);
      expect(feed()!.query, 'dune');
    });
  });

  test('arama kutusu temizlenince popüler listeye dönülür', () async {
    await container.read(movieFeedProvider.future);
    await notifier().search('dune');
    repository.calls.clear();

    await notifier().search('');

    expect(repository.calls, ['popular:1']);
    expect(feed()!.isSearching, isFalse);
  });
}
