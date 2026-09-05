import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/domain/recipe_backup.dart';

void main() {
  group('BackupData', () {
    test('yazıp geri okuduğunda aynı veriyi verir', () {
      final original = BackupData(
        createdAt: DateTime(2026, 9, 5, 10, 30),
        categories: const [CategoryData(name: 'Çorbalar', sortOrder: 1)],
        recipes: const [
          RecipeData(
            name: 'Mercimek Çorbası',
            categoryName: 'Çorbalar',
            ingredients: ['1 su bardağı mercimek', '1 soğan'],
            steps: ['Soğanı kavur.', 'Mercimeği ekle.'],
            note: 'Nane çok olsun.',
            isFavorite: true,
          ),
        ],
      );

      final restored = BackupData.fromJsonString(original.toJsonString());

      expect(restored.version, BackupData.currentVersion);
      expect(restored.createdAt, DateTime(2026, 9, 5, 10, 30));
      expect(restored.categories.single.name, 'Çorbalar');
      expect(restored.categories.single.sortOrder, 1);

      final recipe = restored.recipes.single;
      expect(recipe.name, 'Mercimek Çorbası');
      expect(recipe.categoryName, 'Çorbalar');
      expect(recipe.ingredients, ['1 su bardağı mercimek', '1 soğan']);
      expect(recipe.steps, ['Soğanı kavur.', 'Mercimeği ekle.']);
      expect(recipe.note, 'Nane çok olsun.');
      expect(recipe.isFavorite, isTrue);
    });

    test('malzemeler tek metin olarak da yazılabilir', () {
      // Tarifleri elle geçirirken her satırı ayrı dizi elemanı yapmak zahmetli.
      const source = '''
      {
        "tarifler": [
          {
            "ad": "Kısır",
            "malzemeler": "1 su bardağı bulgur\\n2 kaşık salça\\n\\n",
            "adimlar": "Bulguru ısla.\\nSalçayı ekle."
          }
        ]
      }
      ''';

      final recipe = BackupData.fromJsonString(source).recipes.single;
      expect(recipe.ingredients, ['1 su bardağı bulgur', '2 kaşık salça']);
      expect(recipe.steps, ['Bulguru ısla.', 'Salçayı ekle.']);
    });

    test('eksik alanlar makul varsayılana düşer', () {
      const source = '{"tarifler":[{"ad":"Menemen"}]}';
      final data = BackupData.fromJsonString(source);

      expect(data.version, BackupData.currentVersion);
      expect(data.categories, isEmpty);

      final recipe = data.recipes.single;
      expect(recipe.categoryName, isNull);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
      expect(recipe.note, isNull);
      expect(recipe.isFavorite, isFalse);
    });

    test('adsız tarifte kaçıncı tarifin bozuk olduğunu söyler', () {
      const source = '{"tarifler":[{"ad":"Menemen"},{"malzemeler":["tuz"]}]}';

      expect(
        () => BackupData.fromJsonString(source),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mesaj',
            contains('2. tarif'),
          ),
        ),
      );
    });

    test('bozuk JSON okunmaz', () {
      expect(
        () => BackupData.fromJsonString('[1,2,3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('boş dosya boş yedek olarak okunur', () {
      final data = BackupData.fromJsonString('{}');
      expect(data.recipes, isEmpty);
      expect(data.categories, isEmpty);
    });
  });
}
