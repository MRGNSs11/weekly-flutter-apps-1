import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/recipe_backup.dart';

/// İlk açılışta yüklenecek tarifleri okur.
///
/// Sırayla iki dosyaya bakar:
///   1. `assets/recipes.json` — annemin gerçek tarifleri. Bu dosya
///      `.gitignore`'dadır, depoda yoktur, yalnızca benim derlememde bulunur.
///   2. `assets/demo_recipes.json` — uydurma demo tarifler. Depoda olan tek
///      tarif dosyası budur; kaynak koddan derleyen herkes bunu görür.
///
/// Kod iki dosyayı da aynı şekilde okur; gizlilik kod akışıyla değil, hangi
/// dosyanın depoya girdiğiyle sağlanır.
Future<BackupData> loadSeedData() async {
  const candidates = ['assets/recipes.json', 'assets/demo_recipes.json'];

  for (final path in candidates) {
    try {
      final raw = await rootBundle.loadString(path);
      return BackupData.fromJsonString(raw);
    } on FlutterError {
      // Dosya pakette yok — sıradakine bak.
      continue;
    }
  }

  // Hiçbiri yoksa uygulama boş açılır; annem tarifleri kendi ekleyebilir.
  return const BackupData();
}
