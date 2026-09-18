import 'package:film_arama/domain/movie.dart';
import 'package:film_arama/state/favorites.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movie _movie(int id) => Movie(
      id: id,
      title: 'Film $id',
      posterPath: '/p$id.jpg',
      overview: 'özet',
      voteAverage: 7.5,
      releaseDate: '2023-05-01',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('başlangıçta favori listesi boş', () async {
    final container = makeContainer();

    expect(await container.read(favoritesProvider.future), isEmpty);
  });

  test('eklenen film listeye girer ve en üstte durur', () async {
    final container = makeContainer();
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    await notifier.toggle(_movie(1));
    await notifier.toggle(_movie(2));

    final favorites = container.read(favoritesProvider).value!;
    expect(favorites.map((movie) => movie.id), [2, 1]);
    expect(notifier.isFavorite(1), isTrue);
  });

  test('ikinci dokunuş favoriden çıkarır', () async {
    final container = makeContainer();
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    await notifier.toggle(_movie(1));
    await notifier.toggle(_movie(1));

    expect(container.read(favoritesProvider).value, isEmpty);
    expect(notifier.isFavorite(1), isFalse);
  });

  test('favoriler uygulama yeniden açılınca geri gelir', () async {
    final first = makeContainer();
    await first.read(favoritesProvider.future);
    await first.read(favoritesProvider.notifier).toggle(_movie(42));

    // Yeni kap = uygulamanın sıfırdan açılması.
    final second = makeContainer();
    final restored = await second.read(favoritesProvider.future);

    expect(restored, hasLength(1));
    expect(restored.single.id, 42);
    expect(restored.single.title, 'Film 42');
    expect(restored.single.posterUrl, isNotNull);
  });

  test('bozuk kayıt tüm listeyi çökertmez', () async {
    SharedPreferences.setMockInitialValues({
      'favorites_v1': ['bu json değil', '{"id":7,"title":"Sağlam"}'],
    });

    final container = makeContainer();
    final favorites = await container.read(favoritesProvider.future);

    expect(favorites, hasLength(1));
    expect(favorites.single.id, 7);
  });
}
