// Gerçek cihazda/emülatörde çalışır (CI'da değil):
//   flutter test integration_test
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oyun_2048/main.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';
import 'package:oyun_2048/oyun/oyun_notifier.dart';
import 'package:oyun_2048/oyun/kayit_deposu.dart';
import 'package:oyun_2048/ui/oyun_ekrani.dart';
import 'package:oyun_2048/ui/parcalar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamayı gerçek SharedPreferences ile açar. [kapatAc] için her çağrı
/// yeni bir ProviderScope kurar: uygulamanın kapanıp açılması gibi.
Future<void> ac(WidgetTester tester, {OyunDurumu? baslangic}) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(const SizedBox()); // önceki oturumu kapat
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kayitDeposuProvider.overrideWithValue(KayitDeposu(prefs)),
        rastgeleProvider.overrideWithValue(Random(1)),
        if (baslangic != null)
          baslangicDurumuProvider.overrideWithValue(baslangic),
      ],
      child: const Uygulama(),
    ),
  );
  await tester.pumpAndSettle();
}

String metin(WidgetTester tester, Key k) =>
    tester.widget<Text>(find.byKey(k)).data!;

Future<void> kaydir(WidgetTester tester, Offset yon) async {
  await tester.fling(find.byKey(OyunEkrani.tahtaAnahtari), yon, 1200);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('kaydır, geri al, kapat-aç, yeni oyun; kayıtlar yerinde', (
    tester,
  ) async {
    await ac(
      tester,
      baslangic: OyunDurumu.izgaradan([
        [64, 64, 8, 8],
        [2, 0, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], skor: 1000),
    );
    expect(metin(tester, OyunEkrani.skorAnahtari), '1.000');

    // Sola: 64+64 → 128, 8+8 → 16, 2+2 → 4 = +148
    await kaydir(tester, const Offset(-300, 0));
    expect(metin(tester, OyunEkrani.skorAnahtari), '1.148');
    expect(find.text('128'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(metin(tester, OyunEkrani.skorAnahtari), '1.000');
    expect(find.text('64'), findsNWidgets(2));

    // Birkaç gerçek hamle daha: her yön.
    for (final y in const [
      Offset(-300, 0),
      Offset(0, 300),
      Offset(300, 0),
      Offset(0, -300),
    ]) {
      await kaydir(tester, y);
    }

    // Uygulamayı kapatıp aç: yarım oyun olduğu gibi geri gelir.
    final skorKapanirken = metin(tester, OyunEkrani.skorAnahtari);
    await ac(tester);
    expect(metin(tester, OyunEkrani.skorAnahtari), skorKapanirken);

    final prefs = await SharedPreferences.getInstance();
    final kayitli = prefs.getInt(KayitDeposu.enIyiAnahtari)!;
    expect(kayitli, greaterThanOrEqualTo(1148));

    await tester.tap(find.text('Yeni oyun'));
    await tester.pumpAndSettle();
    expect(metin(tester, OyunEkrani.skorAnahtari), '0');

    // Yeni oyundan sonra kapatıp aç: yarım oyun silinmiş, en iyi skor duruyor.
    await ac(tester);
    expect(find.text(binlik(kayitli)), findsOneWidget);
    expect(metin(tester, OyunEkrani.skorAnahtari), '0');
  });
}
