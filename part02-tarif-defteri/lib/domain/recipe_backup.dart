/// Yedek / aktarım dosyasının biçimi.
///
/// Bu dosya iki işi birden görür:
///   1. Ayarlardan alınan yedek (annemin telefonundan çıkan dosya)
///   2. Tarifleri uygulamaya ilk kez yükleme (`assets/recipes.json`)
///
/// Anahtarlar Türkçe, çünkü bu dosyayı elle yazan insan var: tarifleri
/// defterden ben geçireceğim. `"ad"` yazmak `"name"` yazmaktan daha az hata
/// üretir.
///
/// Flutter'a bağımlı değildir; doğrudan test edilir.
library;

import 'dart:convert';

class CategoryData {
  const CategoryData({required this.name, this.sortOrder = 0});

  final String name;
  final int sortOrder;

  Map<String, dynamic> toJson() => {'ad': name, 'sira': sortOrder};

  static CategoryData fromJson(Map<String, dynamic> json) => CategoryData(
    name: (json['ad'] as String? ?? '').trim(),
    sortOrder: (json['sira'] as num?)?.toInt() ?? 0,
  );
}

class RecipeData {
  const RecipeData({
    required this.name,
    this.categoryName,
    this.ingredients = const [],
    this.steps = const [],
    this.note,
    this.isFavorite = false,
  });

  final String name;
  final String? categoryName;
  final List<String> ingredients;
  final List<String> steps;
  final String? note;
  final bool isFavorite;

  Map<String, dynamic> toJson() => {
    'ad': name,
    if (categoryName != null) 'kategori': categoryName,
    'malzemeler': ingredients,
    'adimlar': steps,
    if (note != null && note!.isNotEmpty) 'not': note,
    if (isFavorite) 'favori': true,
  };

  static RecipeData fromJson(Map<String, dynamic> json) {
    final name = (json['ad'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw const FormatException('Bir tarifin "ad" alanı boş.');
    }
    final category = (json['kategori'] as String?)?.trim();
    return RecipeData(
      name: name,
      categoryName: (category == null || category.isEmpty) ? null : category,
      ingredients: _toLines(json['malzemeler']),
      steps: _toLines(json['adimlar']),
      note: (json['not'] as String?)?.trim(),
      isFavorite: json['favori'] as bool? ?? false,
    );
  }
}

class BackupData {
  const BackupData({
    this.version = currentVersion,
    this.createdAt,
    this.categories = const [],
    this.recipes = const [],
  });

  /// Biçim numarası. İleride alan eklenirse eski dosyalar buradan ayırt edilir.
  static const int currentVersion = 1;

  final int version;
  final DateTime? createdAt;
  final List<CategoryData> categories;
  final List<RecipeData> recipes;

  Map<String, dynamic> toJson() => {
    'surum': version,
    if (createdAt != null) 'olusturma': createdAt!.toIso8601String(),
    'kategoriler': categories.map((c) => c.toJson()).toList(),
    'tarifler': recipes.map((r) => r.toJson()).toList(),
  };

  /// İnsanın okuyup düzeltebilmesi için girintili yazılır.
  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  static BackupData fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dosyanın en dışı bir JSON nesnesi olmalı.');
    }
    return fromJson(decoded);
  }

  static BackupData fromJson(Map<String, dynamic> json) {
    final rawRecipes = json['tarifler'] as List? ?? const [];
    final rawCategories = json['kategoriler'] as List? ?? const [];

    final recipes = <RecipeData>[];
    for (var i = 0; i < rawRecipes.length; i++) {
      final item = rawRecipes[i];
      if (item is! Map<String, dynamic>) {
        throw FormatException('${i + 1}. tarif bir JSON nesnesi değil.');
      }
      try {
        recipes.add(RecipeData.fromJson(item));
      } on FormatException catch (e) {
        // Hangi tarifin bozuk olduğunu söylemezsek 100 tarifin içinde aramak
        // gerekir.
        throw FormatException('${i + 1}. tarif okunamadı: ${e.message}');
      }
    }

    return BackupData(
      version: (json['surum'] as num?)?.toInt() ?? currentVersion,
      createdAt: DateTime.tryParse(json['olusturma'] as String? ?? ''),
      categories: rawCategories
          .whereType<Map<String, dynamic>>()
          .map(CategoryData.fromJson)
          .where((c) => c.name.isNotEmpty)
          .toList(),
      recipes: recipes,
    );
  }
}

/// Malzeme ve adım listelerini okur.
///
/// Elle yazarken her satırı ayrı bir dizi elemanı yapmak zahmetli. Bu yüzden
/// hem dizi hem de satır satır yazılmış tek metin kabul edilir:
///
/// ```json
/// "malzemeler": ["1 su bardağı bulgur", "2 kaşık salça"]
/// "malzemeler": "1 su bardağı bulgur\n2 kaşık salça"
/// ```
List<String> _toLines(Object? value) {
  if (value == null) return const [];
  if (value is String) {
    return value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
  return const [];
}
