import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/oyun_durumu.dart';
import 'package:oyun_2048/oyun/oyun_notifier.dart';
import 'package:oyun_2048/oyun/skor_deposu.dart';
import 'package:oyun_2048/ui/oyun_ekrani.dart';
import 'package:oyun_2048/ui/tema.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Telefon boyutunda, belirli bir tahtayla ekranı kurar.
Future<void> kur(
  WidgetTester tester,
  List<List<int>> izgara, {
  int skor = 0,
  bool bitti = false,
  bool azHareket = false,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  var durum = OyunDurumu.izgaradan(izgara, skor: skor);
  if (bitti) durum = durum.copyWith(bitti: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rastgeleProvider.overrideWithValue(Random(1)),
        skorDeposuProvider.overrideWithValue(SkorDeposu(prefs)),
        baslangicDurumuProvider.overrideWithValue(durum),
      ],
      child: MaterialApp(
        theme: temaKur(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: azHareket),
            child: const OyunEkrani(),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

String skorYazisi(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(OyunEkrani.skorAnahtari)).data!;

Future<void> kaydir(WidgetTester tester, Offset yon) async {
  await tester.fling(find.byKey(OyunEkrani.tahtaAnahtari), yon, 1000);
}

/// Tahtayı saran eğim dönüşümü (Transform) birim matris değilse eğik.
bool tahtaEgik(WidgetTester tester) {
  final donusumler = tester.widgetList<Transform>(
    find.ancestor(
      of: find.byKey(OyunEkrani.tahtaAnahtari),
      matching: find.byType(Transform),
    ),
  );
  return donusumler.any((t) => !t.transform.isIdentity());
}

const ikiIki = [
  [2, 2, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
];

void main() {
  testWidgets('sola kaydır → skor artar → Geri al → skor geri döner', (
    tester,
  ) async {
    await kur(tester, ikiIki);
    expect(skorYazisi(tester), '0');

    await kaydir(tester, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(skorYazisi(tester), '4');

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(skorYazisi(tester), '0');
  });

  testWidgets('hareket olmayan yönde tahta ve skor değişmez', (tester) async {
    await kur(tester, const [
      [2, 4, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(OyunEkrani)),
    );
    await kaydir(tester, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(c.read(oyunProvider).olaySayaci, 0);
    expect(c.read(oyunProvider).geriAlinabilir, isFalse);
  });

  testWidgets('kısa dokunuş hamle sayılmaz (24 px eşiği)', (tester) async {
    await kur(tester, ikiIki);
    await tester.drag(
      find.byKey(OyunEkrani.tahtaAnahtari),
      const Offset(-15, 0),
    );
    await tester.pumpAndSettle();
    expect(skorYazisi(tester), '0');
  });

  testWidgets('hamlede tahta eğilir, sonra düzelir', (tester) async {
    await kur(tester, ikiIki);
    await kaydir(tester, const Offset(-300, 0));
    await tester.pump(); // animasyon saati bu karede başlar (değer 0)
    await tester.pump(const Duration(milliseconds: 60));
    expect(tahtaEgik(tester), isTrue);
    await tester.pumpAndSettle();
    expect(tahtaEgik(tester), isFalse);
  });

  testWidgets('geri alınca tahta bir an grileşir', (tester) async {
    await kur(tester, ikiIki);
    await kaydir(tester, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsNothing);

    await tester.tap(find.text('Geri al'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('bitmiş tahtada "Hamle kalmadı" baştan görünür', (tester) async {
    await kur(
      tester,
      const [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 8],
      ],
      skor: 3120,
      bitti: true,
    );
    expect(find.text('Hamle kalmadı'), findsOneWidget);
    expect(find.text('Skor 3.120'), findsOneWidget);
  });

  testWidgets('2048 olunca sahne biter, katman açılır; Devam et kapatır', (
    tester,
  ) async {
    await kur(tester, const [
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await kaydir(tester, const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('2048!'), findsNothing, reason: 'sahne sürüyor');
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('2048!'), findsOneWidget);

    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text('2048!'), findsNothing);
  });

  testWidgets('"animasyonları kaldır" açıkken katman hemen gelir, eğim yok', (
    tester,
  ) async {
    await kur(tester, const [
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ], azHareket: true);
    await kaydir(tester, const Offset(-300, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tahtaEgik(tester), isFalse);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2048!'), findsOneWidget);
  });
}
