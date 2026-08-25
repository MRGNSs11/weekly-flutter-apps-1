import 'package:aliskanlik_takipcisi/domain/day_key.dart';
import 'package:aliskanlik_takipcisi/domain/heatmap_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = 20260825;
  final todayIndex = DateTime.utc(2026, 8, 25).weekday - DateTime.monday;
  int daysAgo(int n) => dayKeyOfEpoch(epochDayOf(today) - n);

  group('buildHeatmapGrid — yapı', () {
    test('hafta sayısı istenen pencereyle birebir eşleşir', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: heatmapWindowSixMonths,
      );
      expect(grid.weeks.length, heatmapWindowSixMonths);
    });

    test('her hafta 7 hücre içerir', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: 4,
      );
      for (final week in grid.weeks) {
        expect(week.cells.length, 7);
      }
    });

    test('haftalar Pazartesi ile başlar (bugünün hücresi doğru indekste)', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {today},
        todayKey: today,
        windowWeeks: 4,
      );
      expect(grid.weeks.last.cells[todayIndex]?.dayKey, today);
    });

    test('bugünden sonraki günler null olur', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: 4,
      );
      final lastWeek = grid.weeks.last;
      for (var i = todayIndex + 1; i < 7; i++) {
        expect(lastWeek.cells[i], isNull);
      }
    });

    test('bugünün kendisi null değildir', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: 4,
      );
      expect(grid.weeks.last.cells[todayIndex], isNotNull);
    });
  });

  group('buildHeatmapGrid — seviye rengi (koyuluk = seri uzunluğu)', () {
    test('işaretlenmemiş gün level 0', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: 4,
      );
      expect(_findCell(grid, today)!.level, 0);
    });

    test('tek başına işaretli gün level 1', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {today},
        todayKey: today,
        windowWeeks: 4,
      );
      expect(_findCell(grid, today)!.level, 1);
    });

    test('4 günlük seri sonundaki gün level 2', () {
      final days = {for (var i = 0; i < 4; i++) daysAgo(i)};
      final grid = buildHeatmapGrid(
        completedDayKeys: days,
        todayKey: today,
        windowWeeks: 4,
      );
      expect(_findCell(grid, today)!.level, 2);
    });

    test('14 günlük seri sonundaki gün level 4', () {
      final days = {for (var i = 0; i < 14; i++) daysAgo(i)};
      final grid = buildHeatmapGrid(
        completedDayKeys: days,
        todayKey: today,
        windowWeeks: 4,
      );
      expect(_findCell(grid, today)!.level, 4);
    });
  });

  group('buildHeatmapGrid — ay etiketleri', () {
    test('ay sınırını içeren pencerede yeni ay etiketlenir', () {
      const boundaryToday = 20260215; // 15 Şubat 2026
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: boundaryToday,
        windowWeeks: 6,
      );
      expect(grid.monthLabels.map((l) => l.label), contains('Şub'));
    });

    test('ardışık iki ay etiketi asla aynı olamaz', () {
      final grid = buildHeatmapGrid(
        completedDayKeys: {},
        todayKey: today,
        windowWeeks: heatmapWindowOneYear,
      );
      for (var i = 1; i < grid.monthLabels.length; i++) {
        expect(grid.monthLabels[i].label, isNot(grid.monthLabels[i - 1].label));
      }
    });
  });
}

HeatmapCell? _findCell(HeatmapGrid grid, int dayKey) {
  for (final week in grid.weeks) {
    for (final cell in week.cells) {
      if (cell?.dayKey == dayKey) return cell;
    }
  }
  return null;
}
