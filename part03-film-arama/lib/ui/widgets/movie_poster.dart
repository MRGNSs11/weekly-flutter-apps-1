import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/movie.dart';

/// Izgaradaki tek kart: poster + başlık + yıl + puan.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'poster-${movie.id}',
              child: MoviePoster(movie: movie),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (movie.year.isNotEmpty)
                Text(movie.year, style: theme.textTheme.bodySmall),
              if (movie.year.isNotEmpty && movie.hasVote)
                Text(' · ', style: theme.textTheme.bodySmall),
              if (movie.hasVote) ...[
                Icon(Icons.star_rounded,
                    size: 13, color: theme.colorScheme.primary),
                const SizedBox(width: 2),
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Poster görseli. Yükleme, hata ve "posteri yok" durumlarını kendi çözer.
class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie, this.radius = 12});

  final Movie movie;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = movie.posterUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: url == null
            ? _Placeholder(title: movie.title)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                // Görsel gelene kadar boş kutu değil, sakin bir zemin:
                // ızgara zıplamıyor.
                placeholder: (context, _) => const ColoredBox(
                  color: Color(0xFF1E2228),
                ),
                errorWidget: (context, _, _) => _Placeholder(
                  title: movie.title,
                ),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1E2228),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.movie_outlined, color: Colors.white24),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
