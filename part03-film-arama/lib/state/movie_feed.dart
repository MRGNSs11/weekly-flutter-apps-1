import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/tmdb_exception.dart';
import '../data/movie_repository.dart';
import '../domain/feed.dart';
import '../domain/movie_page.dart';
import '../providers.dart';

/// Kullanıcı yazmayı bıraktıktan sonra beklenen süre.
///
/// Neden 400 ms: her tuşa istek atmak hem TMDB kotasını yakar hem de
/// cevaplar sırasız döndüğü için ekranda eski sonuçların görünmesine yol
/// açar. 400 ms, "yazmayı bıraktı" hissini veren en kısa süre; 250 ms'de
/// hızlı yazanlarda hâlâ birkaç gereksiz istek çıkıyor, 600 ms'de arayüz
/// tembel hissettiriyor.
const Duration kSearchDebounce = Duration(milliseconds: 400);

final movieFeedProvider = AsyncNotifierProvider<MovieFeedNotifier, Feed>(
  MovieFeedNotifier.new,
);

/// Arama ekranının beyni: debounce, istek iptali, sayfalama.
class MovieFeedNotifier extends AsyncNotifier<Feed> {
  Timer? _debounce;
  CancelToken? _cancelToken;
  String _query = '';

  MovieRepository get _repository => ref.read(movieRepositoryProvider);

  @override
  Future<Feed> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel('ekran kapandı');
    });

    // Açılışta arama kutusu boş: popüler filmler.
    final page = await _fetch('', 1, _newToken());
    return Feed.firstPage('', page);
  }

  /// Her tuş vuruşunda çağrılır; isteği kendisi atmaz, sadece zamanlayıcıyı
  /// kurar.
  void onQueryChanged(String raw) {
    final query = raw.trim();
    _debounce?.cancel();

    // Aynı sorgu (örneğin boşluk eklenip silinmiş) yeniden istek doğurmaz.
    if (query == _query) return;

    _debounce = Timer(kSearchDebounce, () => search(query));
  }

  /// Debounce'u atlayarak hemen arar (klavyedeki "ara" tuşu, yeniden dene).
  Future<void> search(String raw) async {
    _debounce?.cancel();
    final query = raw.trim();
    _query = query;

    // Yoldaki istek artık eskidi: cevabı gelse bile işimize yaramaz,
    // bağlantıyı kapatıyoruz. Asıl kazanç, geç gelen eski cevabın yeni
    // sonuçların üstüne yazmasını engellemek.
    final token = _newToken();
    state = const AsyncValue.loading();

    try {
      final page = await _fetch(query, 1, token);
      if (token.isCancelled) return;
      state = AsyncValue.data(Feed.firstPage(query, page));
    } on TmdbException catch (error, stack) {
      // İptal bir hata değil: yeni arama zaten yolda, ekranı bozmayalım.
      if (error.isCancellation) return;
      state = AsyncValue.error(error, stack);
    }
  }

  /// Liste sonuna yaklaşınca çağrılır.
  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || feed.loadingMore || !feed.hasMore) return;

    state = AsyncValue.data(feed.copyWith(loadingMore: true));

    // Sayfa isteği aramadan ayrı bir jetonla gider; kullanıcı bu sırada
    // yazmaya başlarsa `search` onu da iptal eder.
    final token = _cancelToken ?? CancelToken();

    try {
      final next = await _fetch(feed.query, feed.page + 1, token);
      final current = state.value;
      // Bu sırada arama değiştiyse gelen sayfa başka listeye aittir.
      if (current == null || current.query != feed.query) return;
      state = AsyncValue.data(current.append(next));
    } on TmdbException catch (error) {
      if (error.isCancellation) return;
      final current = state.value;
      if (current == null) return;
      // Elimizdeki listeyi SİLMİYORUZ; sadece altta uyarı gösteriyoruz.
      state = AsyncValue.data(
        current.copyWith(loadingMore: false, loadMoreError: error.message),
      );
    }
  }

  /// Hata ekranındaki "tekrar dene".
  Future<void> retry() => search(_query);

  Future<MoviePage> _fetch(String query, int page, CancelToken token) {
    if (query.isEmpty) {
      return _repository.popular(page: page, cancelToken: token);
    }
    return _repository.search(query, page: page, cancelToken: token);
  }

  CancelToken _newToken() {
    _cancelToken?.cancel('yeni arama başladı');
    final token = CancelToken();
    _cancelToken = token;
    return token;
  }
}
