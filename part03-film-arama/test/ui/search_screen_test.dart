import 'package:film_arama/core/tmdb_exception.dart';
import 'package:film_arama/providers.dart';
import 'package:film_arama/ui/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_movie_repository.dart';

/// Ekranın üç durumu da ayrı ayrı görünüyor mu?
/// (Poster indirmeyi gerektirmeyen durumlar seçildi: testte ağ yok.)
void main() {
  Future<void> pump(WidgetTester tester, FakeMovieRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [movieRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
  }

  testWidgets('yükleme sırasında halka görünür', (tester) async {
    final repository = FakeMovieRepository()
      ..delay = const Duration(milliseconds: 300);

    await pump(tester, repository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('hata durumunda mesaj ve tekrar dene düğmesi çıkar',
      (tester) async {
    final repository = FakeMovieRepository()
      ..error = const TmdbException(
        TmdbErrorKind.noConnection,
        'İnternet bağlantısı kurulamadı.',
      );

    await pump(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('İnternet bağlantısı kurulamadı.'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('sonuç yoksa aranan sorgu ekranda yazar', (tester) async {
    final repository = FakeMovieRepository()..pageSize = 0;

    await pump(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'olmayanfilm');
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('"olmayanfilm" için sonuç yok'), findsOneWidget);
  });
}
