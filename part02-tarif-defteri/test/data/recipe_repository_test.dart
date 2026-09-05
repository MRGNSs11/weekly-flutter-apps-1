import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/data/database.dart';
import 'package:tarif_defteri/data/recipe_repository.dart';
import 'package:tarif_defteri/domain/recipe_backup.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db);
  });

  tearDown(() => db.close());

  test('arama Türkçe karakter yazılmadan da bulur', () async {
    await repo.insertRecipe(
      name: 'Mercimek Çorbası',
      ingredients: ['1 su bardağı kırmızı mercimek'],
    );
    await repo.insertRecipe(name: 'Baklava', ingredients: ['yufka']);

    final sonuc = await repo.watchSearch('corba').first;
    expect(sonuc.map((r) => r.name), ['Mercimek Çorbası']);
  });

  test('arama malzemede de geçer, yapılışta geçmez', () async {
    await repo.insertRecipe(
      name: 'Kısır',
      ingredients: ['2 kaşık salça'],
      steps: ['Üzerine limon sık.'],
    );

    expect((await repo.watchSearch('salca').first), hasLength(1));
    expect((await repo.watchSearch('limon').first), isEmpty);
  });

  test('boş sorgu sonuç döndürmez', () async {
    await repo.insertRecipe(name: 'Menemen');
    expect(await repo.watchSearch('  ').first, isEmpty);
  });

  test('tarif düzenlenince arama metni de güncellenir', () async {
    final id = await repo.insertRecipe(name: 'Menemen');
    expect(await repo.watchSearch('sucuk').first, isEmpty);

    await repo.updateRecipe(
      id: id,
      name: 'Menemen',
      ingredients: ['1 parça sucuk'],
    );
    expect(await repo.watchSearch('sucuk').first, hasLength(1));
  });

  test('silinen tarif aynı kimlikle geri konabilir', () async {
    final id = await repo.insertRecipe(name: 'Su Böreği');

    final silinen = await repo.deleteRecipe(id);
    expect(silinen, isNotNull);
    expect(await repo.recipeCount(), 0);

    await repo.restoreRecipe(silinen!);
    final geri = await repo.watchRecipe(id).first;
    expect(geri?.name, 'Su Böreği');
  });

  test('kategori silinince tarifleri silinmez, kategorisiz kalır', () async {
    final katId = await repo.addCategory('Çorbalar');
    await repo.insertRecipe(name: 'Tarhana', categoryId: katId);

    await repo.deleteCategory(katId);

    expect(await repo.recipeCount(), 1);
    expect(await repo.watchUncategorizedRecipes().first, hasLength(1));
  });

  group('seedIfEmpty', () {
    test('boş veritabanına tarifleri ve kategorileri yükler', () async {
      final yuklendi = await repo.seedIfEmpty(
        const BackupData(
          recipes: [
            RecipeData(name: 'Karnıyarık', categoryName: 'Ana Yemek'),
            RecipeData(name: 'İrmik Helvası', categoryName: 'Tatlılar'),
          ],
        ),
      );

      expect(yuklendi, isTrue);
      expect(await repo.recipeCount(), 2);

      final ozetler = await repo.watchCategorySummaries().first;
      final anaYemek = ozetler.firstWhere(
        (o) => o.category.name == 'Ana Yemek',
      );
      expect(anaYemek.recipeCount, 1);
    });

    test('dosyada olmayan kategori adı yeni kategori olarak açılır', () async {
      await repo.seedIfEmpty(
        const BackupData(
          recipes: [RecipeData(name: 'Lahmacun', categoryName: 'Fırın')],
        ),
      );

      final adlar = (await repo.watchCategories().first).map((c) => c.name);
      expect(adlar, contains('Fırın'));
      expect(adlar, contains('Çorbalar')); // varsayılanlar da açılır
    });

    test('veritabanı doluysa üzerine yazmaz', () async {
      await repo.insertRecipe(name: 'Annemin tarifi');

      final yuklendi = await repo.seedIfEmpty(
        const BackupData(recipes: [RecipeData(name: 'Demo tarif')]),
      );

      expect(yuklendi, isFalse);
      expect(await repo.recipeCount(), 1);
    });
  });

  test('yedek, kategori adlarıyla birlikte dışa aktarılır', () async {
    final katId = await repo.addCategory('Tatlılar');
    await repo.insertRecipe(
      name: 'Sütlaç',
      categoryId: katId,
      ingredients: ['1 litre süt'],
      steps: ['Pirinci haşla.'],
      isFavorite: true,
    );

    final yedek = await repo.exportBackup();
    final tarif = yedek.recipes.single;

    expect(tarif.name, 'Sütlaç');
    expect(tarif.categoryName, 'Tatlılar');
    expect(tarif.ingredients, ['1 litre süt']);
    expect(tarif.isFavorite, isTrue);
    expect(yedek.categories.single.name, 'Tatlılar');
  });

  test('favori işareti değişince favori listesine girer', () async {
    final id = await repo.insertRecipe(name: 'Kabak Tatlısı');
    expect(await repo.watchFavorites().first, isEmpty);

    await repo.setFavorite(id, true);
    expect(await repo.watchFavorites().first, hasLength(1));
  });

  test('tercihler yazılıp okunabilir', () async {
    await repo.setPreference('tema', 'koyu');
    await repo.setPreference('tema', 'acik'); // üzerine yazar
    await repo.setPreference('yaziBoyutu', '2');

    final tercihler = await repo.watchPreferences().first;
    expect(tercihler['tema'], 'acik');
    expect(tercihler['yaziBoyutu'], '2');
  });
}
