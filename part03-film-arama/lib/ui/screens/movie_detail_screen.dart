import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tmdb_exception.dart';
import '../../domain/movie.dart';
import '../../domain/movie_details.dart';
import '../../state/details_provider.dart';
import '../widgets/movie_poster.dart';

import 'search_screen.dart' show FavoriteButton;

/// Film künyesi.
///
/// Listeden gelen [movie] sayesinde ekran ANINDA doluyor (poster, başlık,
/// puan, özet). Ağdan gelen detay sadece tür ve süreyi ekliyor. Böylece
/// kullanıcı boş ekrana bakmıyor.
class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsState = ref.watch(movieDetailsProvider(movie.id));
    final details = detailsState.value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [FavoriteButton(movie: movie)],
            flexibleSpace: FlexibleSpaceBar(
              background: _Backdrop(details: details),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                _Header(movie: movie, details: details),
                const SizedBox(height: 20),
                if (details?.tagline case final tagline?) ...[
                  Text(
                    tagline,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  movie.overview.isEmpty
                      ? 'Bu film için Türkçe özet girilmemiş.'
                      : movie.overview,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 24),
                // Künye ağdan gelirken sadece bu bölüm bekliyor; ekranın
                // geri kalanı çoktan dolu.
                detailsState.when(
                  data: (_) => const SizedBox.shrink(),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, _) => _DetailsError(
                    message: error is TmdbException
                        ? error.message
                        : 'Künye bilgisi alınamadı.',
                    onRetry: () =>
                        ref.invalidate(movieDetailsProvider(movie.id)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.details});

  final MovieDetails? details;

  @override
  Widget build(BuildContext context) {
    final url = details?.backdropUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
        else
          const ColoredBox(color: Color(0xFF1E2228)),
        // Başlık çubuğundaki yazılar açık posterlerde kaybolmasın.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Color(0xFF0E1013)],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.movie, required this.details});

  final Movie movie;
  final MovieDetails? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final facts = <String>[
      if (movie.year.isNotEmpty) movie.year,
      if (details?.runtimeLabel.isNotEmpty ?? false) details!.runtimeLabel,
      if (details?.genres.isNotEmpty ?? false) details!.genres.join(', '),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Hero(
            tag: 'poster-${movie.id}',
            child: MoviePoster(movie: movie),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movie.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              if (facts.isNotEmpty)
                Text(
                  facts.join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              if (movie.hasVote) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(' / 10', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Künyeyi yenile')),
      ],
    );
  }
}
