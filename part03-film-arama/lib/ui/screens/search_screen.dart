import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tmdb_exception.dart';
import '../../domain/feed.dart';
import '../../domain/movie.dart';
import '../../state/favorites.dart';
import '../../state/movie_feed.dart';
import '../widgets/movie_poster.dart';
import '../widgets/state_views.dart';
import 'favorites_screen.dart';
import 'movie_detail_screen.dart';

/// Ana ekran: arama kutusu + poster ızgarası.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Liste sonuna iki ekran kala sonraki sayfayı iste: kullanıcı dibe
  /// varmadan yeni posterler hazır olsun.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(movieFeedProvider.notifier).loadMore();
    }
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(movieFeedProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              onChanged: ref.read(movieFeedProvider.notifier).onQueryChanged,
              onSubmitted: ref.read(movieFeedProvider.notifier).search,
              onClear: () {
                _controller.clear();
                ref.read(movieFeedProvider.notifier).search('');
              },
              onFavorites: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const FavoritesScreen(),
                ),
              ),
            ),
            Expanded(
              child: feedState.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: error is TmdbException
                      ? error.message
                      : 'Beklenmeyen bir sorun çıktı.',
                  onRetry: ref.read(movieFeedProvider.notifier).retry,
                ),
                data: (feed) => _FeedBody(
                  feed: feed,
                  scrollController: _scrollController,
                  onMovieTap: _openMovie,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFavorites,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Film ara',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                      tooltip: 'Temizle',
                    );
                  },
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onFavorites,
            icon: const Icon(Icons.favorite_rounded),
            tooltip: 'Favoriler',
          ),
        ],
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({
    required this.feed,
    required this.scrollController,
    required this.onMovieTap,
  });

  final Feed feed;
  final ScrollController scrollController;
  final ValueChanged<Movie> onMovieTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (feed.isEmpty) {
      return feed.isSearching
          ? EmptyView(
              title: '"${feed.query}" için sonuç yok',
              subtitle: 'Yazımı kontrol et ya da özgün adıyla ara.',
            )
          : const EmptyView(
              title: 'Liste boş',
              icon: Icons.movie_outlined,
            );
    }

    return CustomScrollView(
      controller: scrollController,
      // Kaydırırken klavye kapansın, ızgara tam görünsün.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              feed.isSearching
                  ? '${feed.movies.length} sonuç gösteriliyor'
                  : 'Popüler filmler',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              // Poster 2:3 + altındaki iki satır yazı.
              childAspectRatio: 0.48,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final movie = feed.movies[index];
                return MovieCard(
                  key: ValueKey(movie.id),
                  movie: movie,
                  onTap: () => onMovieTap(movie),
                );
              },
              childCount: feed.movies.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _FooterStatus(
            feed: feed,
            onRetry: () => ref.read(movieFeedProvider.notifier).loadMore(),
          ),
        ),
      ],
    );
  }
}

/// Listenin altı: yükleniyor halkası, sayfa hatası ya da "hepsi bu kadar".
class _FooterStatus extends StatelessWidget {
  const _FooterStatus({required this.feed, required this.onRetry});

  final Feed feed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (feed.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              feed.loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }

    if (feed.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!feed.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Listenin sonu', style: theme.textTheme.bodySmall),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

/// Favori düğmesi hem ızgarada hem detayda kullanılıyor.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    final isFavorite = favorites.any((item) => item.id == movie.id);

    return IconButton(
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(movie),
      tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}
