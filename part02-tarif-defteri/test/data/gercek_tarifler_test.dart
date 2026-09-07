import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/domain/recipe_backup.dart';

/// `assets/recipes.json` sağlam mı?
///
/// Bu dosya `tool/tarif_donustur.dart` tarafından üretilir ve `.gitignore`
/// içindedir — depoyu klonlayan kimsede yoktur. O yüzden test, dosya yoksa
/// kendini atlar; benim derlememde ise gerçekten çalışır.
///
/// Amaç: 136 tarifi telefonda tek tek açmadan, bozuk bir kayıt varsa burada
/// yakalamak.
void main() {
  final dosya = File('assets/recipes.json');

  test('gerçek tarif dosyası okunabiliyor ve tutarlı', () {
    if (!dosya.existsSync()) {
      markTestSkipped('assets/recipes.json yok — depo klonunda beklenen durum.');
      return;
    }

    final veri = BackupData.fromJsonString(dosya.readAsStringSync());

    expect(veri.recipes, isNotEmpty);
    expect(veri.categories, isNotEmpty);

    final kategoriAdlari = veri.categories.map((c) => c.name).toSet();
    final gorulenAdlar = <String>{};

    for (final tarif in veri.recipes) {
      expect(tarif.name.trim(), isNotEmpty, reason: 'adı boş tarif var');

      // Aynı ad iki kez geçerse ana ekranda ayırt edilemez. Metinde bilerek
      // ayrılmış olanlar "(Varyasyon 1)" gibi eklerle geliyor.
      expect(
        gorulenAdlar.add(tarif.name),
        isTrue,
        reason: 'aynı adla iki tarif: ${tarif.name}',
      );

      expect(
        tarif.ingredients,
        isNotEmpty,
        reason: '${tarif.name} — malzemesiz',
      );

      expect(
        kategoriAdlari,
        contains(tarif.categoryName),
        reason: '${tarif.name} — kategori listesinde olmayan '
            '"${tarif.categoryName}" kategorisine bağlı',
      );
    }
  });
}
