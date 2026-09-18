import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/movie_details.dart';
import '../providers.dart';

/// Tek filmin künyesi.
///
/// `autoDispose`: kullanıcı detaydan çıkınca istek de veri de düşsün;
/// yüzlerce film gezilen bir uygulamada hepsini bellekte tutmanın anlamı yok.
/// `family`: her film id'si kendi sağlayıcısını alır.
final movieDetailsProvider =
    FutureProvider.autoDispose.family<MovieDetails, int>((ref, id) async {
  // Kullanıcı detay açıp hemen geri dönerse istek yarıda kesilir.
  final token = CancelToken();
  ref.onDispose(() => token.cancel('detay ekranı kapandı'));

  return ref.watch(movieRepositoryProvider).details(id, cancelToken: token);
});
