import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/favorites.dart';
import '../widgets/movie_poster.dart';
import '../widgets/state_views.dart';
import 'movie_detail_screen.dart';

/// Kaydedilen filmler. Tamamen cihazda, ağ isteği yok.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: favorites.when(
        loading: () => const LoadingView(),
        error: (error, _) => const ErrorView(
          message: 'Kayıtlı filmler okunamadı.',
        ),
        data: (movies) {
          if (movies.isEmpty) {
            return const EmptyView(
              title: 'Henüz favori yok',
              subtitle: 'Bir filmin künyesindeki kalbe dokun.',
              icon: Icons.favorite_border_rounded,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.48,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                key: ValueKey(movie.id),
                movie: movie,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => MovieDetailScreen(movie: movie),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
