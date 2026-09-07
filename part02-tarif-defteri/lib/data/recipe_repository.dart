import 'package:drift/drift.dart';

import '../domain/recipe_backup.dart';
import '../domain/turkish_text.dart';
import 'database.dart';

/// Bir kategori ve içindeki tarif sayısı — ana ekrandaki kartlar için.
class CategorySummary {
  const CategorySummary({required this.category, required this.recipeCount});

  final Category category;
  final int recipeCount;
}

/// Uygulamanın veriyle konuştuğu tek yer.
///
/// Ekranlar Drift'i doğrudan görmez; böylece sorgular tek dosyada toplanır ve
/// arama metninin güncellenmesi unutulamaz.
class RecipeRepository {
  RecipeRepository(this._db);

  final AppDatabase _db;

  /// İlk kurulumda kullanılan kategoriler. Annem bunları ayarlardan
  /// değiştirebilir; kodda sabit değildir, yalnızca başlangıç değeridir.
  static const defaultCategories = <String>[
    'Çorbalar',
    'Ana Yemek',
    'Hamur İşi',
    'Tatlılar',
    'Salatalar',
    'Zeytinyağlı',
    'Kahvaltılık',
    'Turşu & Reçel',
  ];

  // ── Kategoriler ────────────────────────────────────────────────────────

  Stream<List<Category>> watchCategories() {
    return (_db.select(_db.categories)..orderBy([
          (c) => OrderingTerm(expression: c.sortOrder),
          (c) => OrderingTerm(expression: c.name),
        ]))
        .watch();
  }

  /// Ana ekran kartları: kategori + içindeki tarif sayısı, tek sorguda.
  Stream<List<CategorySummary>> watchCategorySummaries() {
    final count = _db.recipes.id.count();
    final query = _db.select(_db.categories).join([
      leftOuterJoin(
        _db.recipes,
        _db.recipes.categoryId.equalsExp(_db.categories.id),
      ),
    ]);
    query
      ..addColumns([count])
      ..groupBy([_db.categories.id])
      ..orderBy([
        OrderingTerm(expression: _db.categories.sortOrder),
        OrderingTerm(expression: _db.categories.name),
      ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CategorySummary(
              category: row.readTable(_db.categories),
              recipeCount: row.read(count) ?? 0,
            ),
          )
          .toList(),
    );
  }

  Future<int> addCategory(String name) {
    return _db
        .into(_db.categories)
        .insert(CategoriesCompanion.insert(name: name.trim()));
  }

  Future<void> renameCategory(int id, String name) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(name: Value(name.trim())),
    );
  }

  /// Kategoriyi siler. İçindeki tarifler SİLİNMEZ, kategorisiz kalır ve ana
  /// ekranda "Kategorisiz" başlığı altında görünmeye devam eder.
  Future<void> deleteCategory(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  Future<void> reorderCategories(List<int> idsInOrder) async {
    await _db.batch((batch) {
      for (var i = 0; i < idsInOrder.length; i++) {
        batch.update(
          _db.categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (c) => c.id.equals(idsInOrder[i]),
        );
      }
    });
  }

  // ── Tarifler ───────────────────────────────────────────────────────────

  Stream<List<Recipe>> watchRecipesInCategory(int categoryId) {
    return (_db.select(_db.recipes)
          ..where((r) => r.categoryId.equals(categoryId))
          ..orderBy([(r) => OrderingTerm(expression: r.name)]))
        .watch();
  }

  Stream<List<Recipe>> watchUncategorizedRecipes() {
    return (_db.select(_db.recipes)
          ..where((r) => r.categoryId.isNull())
          ..orderBy([(r) => OrderingTerm(expression: r.name)]))
        .watch();
  }

  Stream<List<Recipe>> watchFavorites({int limit = 6}) {
    return (_db.select(_db.recipes)
          ..where((r) => r.isFavorite.equals(true))
          ..orderBy([(r) => OrderingTerm(expression: r.name)])
          ..limit(limit))
        .watch();
  }

  Stream<Recipe?> watchRecipe(int id) {
    return (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(id))).watchSingleOrNull();
  }

  /// Arama.
  ///
  /// Sorgu, kayıtlı `searchText` sütunuyla aynı kurallardan geçirilir
  /// ([normalizeTurkish]); böylece "corba" yazınca "Çorba" bulunur.
  /// Boş sorguda hiçbir şey döndürmez — arama kutusu boşken sonuç listesi
  /// değil, normal ana ekran gösterilir.
  Stream<List<Recipe>> watchSearch(String query) {
    final needle = normalizeTurkish(query);
    if (needle.isEmpty) return Stream.value(const []);

    return (_db.select(_db.recipes)
          ..where((r) => r.searchText.contains(needle))
          ..orderBy([(r) => OrderingTerm(expression: r.name)]))
        .watch();
  }

  Future<int> insertRecipe({
    required String name,
    int? categoryId,
    List<String> ingredients = const [],
    List<String> steps = const [],
    String? note,
    bool isFavorite = false,
  }) {
    return _db
        .into(_db.recipes)
        .insert(
          RecipesCompanion.insert(
            name: name.trim(),
            categoryId: Value(categoryId),
            ingredients: Value(ingredients),
            steps: Value(steps),
            note: Value(note),
            isFavorite: Value(isFavorite),
            searchText: Value(buildSearchText(name, ingredients)),
          ),
        );
  }

  Future<void> updateRecipe({
    required int id,
    required String name,
    int? categoryId,
    List<String> ingredients = const [],
    List<String> steps = const [],
    String? note,
  }) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        name: Value(name.trim()),
        categoryId: Value(categoryId),
        ingredients: Value(ingredients),
        steps: Value(steps),
        note: Value(note),
        searchText: Value(buildSearchText(name, ingredients)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setFavorite(int id, bool value) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(isFavorite: Value(value)),
    );
  }

  /// Tarifi siler ve silinen satırı geri döndürür.
  ///
  /// Geri döndürmesinin sebebi "geri al": annem yanlışlıkla sildiğinde
  /// tarifi aynı kimlikle geri koyabilmemiz gerekiyor.
  Future<Recipe?> deleteRecipe(int id) async {
    final recipe = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (recipe == null) return null;

    await (_db.delete(_db.recipes)..where((r) => r.id.equals(id))).go();
    return recipe;
  }

  /// Silinen tarifi kimliğiyle birlikte geri koyar.
  Future<void> restoreRecipe(Recipe recipe) {
    return _db.into(_db.recipes).insert(recipe, mode: InsertMode.insert);
  }

  // ── Tercihler ──────────────────────────────────────────────────────────

  Stream<Map<String, String>> watchPreferences() {
    return _db
        .select(_db.preferences)
        .watch()
        .map((rows) => {for (final row in rows) row.key: row.value});
  }

  Future<void> setPreference(String key, String value) {
    return _db
        .into(_db.preferences)
        .insertOnConflictUpdate(Preference(key: key, value: value));
  }

  // ── Yedek ve ilk yükleme ───────────────────────────────────────────────

  /// Veritabanı boşsa verilen tarifleri yükler.
  ///
  /// Uygulama açılışında bir kez çalışır. Doluysa hiçbir şey yapmaz — yani
  /// annem tarif eklemişken uygulamayı güncellesek bile üzerine yazılmaz.
  Future<bool> seedIfEmpty(BackupData data) async {
    final existing = await _db.select(_db.recipes).get();
    if (existing.isNotEmpty) return false;

    // Varsayılanlar yalnızca yükleme dosyası kendi kategorilerini vermediğinde
    // devreye girer. İkisi birden eklenirse annem ana ekranda hiç tarifi
    // olmayan kategoriler görür — tarifler defterden geldiğinde kategori
    // listesi de defterden gelmeli.
    final categoryNames = <String>[
      ...data.categories.map((c) => c.name),
      if (data.categories.isEmpty) ...defaultCategories,
      ...data.recipes.map((r) => r.categoryName).whereType<String>(),
    ];

    final categoryIds = <String, int>{};
    var order = 0;
    for (final name in categoryNames) {
      final key = normalizeTurkish(name);
      if (key.isEmpty || categoryIds.containsKey(key)) continue;
      categoryIds[key] = await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(name: name, sortOrder: Value(order++)),
          );
    }

    for (final recipe in data.recipes) {
      await insertRecipe(
        name: recipe.name,
        categoryId: recipe.categoryName == null
            ? null
            : categoryIds[normalizeTurkish(recipe.categoryName!)],
        ingredients: recipe.ingredients,
        steps: recipe.steps,
        note: recipe.note,
        isFavorite: recipe.isFavorite,
      );
    }

    return true;
  }

  /// Bütün tarifleri yedek biçimine çevirir.
  Future<BackupData> exportBackup() async {
    final categories = await _db.select(_db.categories).get();
    final recipes = await _db.select(_db.recipes).get();
    final nameById = {for (final c in categories) c.id: c.name};

    return BackupData(
      createdAt: DateTime.now(),
      categories: categories
          .map((c) => CategoryData(name: c.name, sortOrder: c.sortOrder))
          .toList(),
      recipes: recipes
          .map(
            (r) => RecipeData(
              name: r.name,
              categoryName: r.categoryId == null
                  ? null
                  : nameById[r.categoryId],
              ingredients: r.ingredients,
              steps: r.steps,
              note: r.note,
              isFavorite: r.isFavorite,
            ),
          )
          .toList(),
    );
  }

  Future<int> recipeCount() async {
    final rows = await _db.select(_db.recipes).get();
    return rows.length;
  }
}
