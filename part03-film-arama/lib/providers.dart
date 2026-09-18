import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/movie_repository.dart';
import 'data/tmdb_client.dart';

/// Uygulamanın tek Dio örneği. Bağlantı havuzu paylaşılsın diye tek.
final dioProvider = Provider<Dio>((ref) {
  final dio = createTmdbDio();
  ref.onDispose(dio.close);
  return dio;
});

/// Ekranlar veriye hep buradan ulaşır.
///
/// Testte `overrideWithValue` ile sahte depo verilebilir.
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository(ref.watch(dioProvider));
});
