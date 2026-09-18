import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/movie.dart';

/// Favoriler cihazda kalır; hiçbir sunucuya gönderilmez.
///
/// Veritabanı kurmuyoruz: saklanan şey bir avuç filmden ibaret, üstelik
/// Part 01 ve Part 02 zaten veritabanı gösterdi.
const String _storageKey = 'favorites_v1';

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Movie>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const [];

    return stored
        .map(_decode)
        .whereType<Movie>()
        .toList(growable: false);
  }

  bool isFavorite(int id) {
    return state.value?.any((movie) => movie.id == id) ?? false;
  }

  /// Favorideyse çıkarır, değilse ekler. Yeni eklenen en üste gelir.
  Future<void> toggle(Movie movie) async {
    final current = state.value ?? const <Movie>[];
    final exists = current.any((item) => item.id == movie.id);

    final updated = exists
        ? current.where((item) => item.id != movie.id).toList()
        : [movie, ...current];

    state = AsyncValue.data(updated);
    await _save(updated);
  }

  Future<void> _save(List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      movies.map((movie) => jsonEncode(movie.toJson())).toList(),
    );
  }

  /// Bozuk kayıt tüm listeyi çökertmesin: okunamayan satır atlanır.
  static Movie? _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return Movie.fromJson(json);
    } on FormatException {
      return null;
    }
  }
}
