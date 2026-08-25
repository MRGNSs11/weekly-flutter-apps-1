import 'day_key.dart';

/// Taslakta 6 ay (26 hafta) gösteriliyordu; kaydırılabilir harita bu
/// pencereyi ["Son 6 ay", "Son 1 yıl"] arasında değiştirir (bkz. PLAN.md § B2.4.2).
const int heatmapWindowSixMonths = 26;
const int heatmapWindowOneYear = 53;

class HeatmapCell {
  const HeatmapCell({required this.dayKey, required this.level});

  final int dayKey;

  /// 0 = işaretlenmemiş, 1-4 = işaretlenmiş, o günü içeren serinin o anki
  /// uzunluğuna göre koyulaşır (1-2 gün / 3-6 / 7-13 / 14+). Tek bir
  /// alışkanlık günlük olarak zaten ikili (yapıldı/yapılmadı) olduğundan,
  /// GitHub tarzı ısı haritasına anlam katmak için yoğunluğu seri uzunluğuna
  /// bağladık: harita ne kadar koyuysa, o gün canlı olan seri o kadar uzun.
  final int level;

  @override
  bool operator ==(Object other) =>
      other is HeatmapCell && other.dayKey == dayKey && other.level == level;

  @override
  int get hashCode => Object.hash(dayKey, level);
}

class HeatmapWeek {
  const HeatmapWeek(this.cells);

  /// Pazartesi'den Pazar'a 7 hücre. `null` = pencerenin henüz gelmemiş
  /// (bugünden sonraki) günü — boş kutu olarak değil, hiç çizilmeyerek gösterilir.
  final List<HeatmapCell?> cells;
}

class HeatmapMonthLabel {
  const HeatmapMonthLabel({required this.weekIndex, required this.label});

  final int weekIndex;
  final String label;
}

class HeatmapGrid {
  const HeatmapGrid({required this.weeks, required this.monthLabels});

  final List<HeatmapWeek> weeks;
  final List<HeatmapMonthLabel> monthLabels;
}

const _turkishMonthShort = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

int _startOfWeekEpoch(int epochDay) {
  final date = dateOfDayKey(dayKeyOfEpoch(epochDay));
  return epochDay - (date.weekday - DateTime.monday);
}

Map<int, int> _runLengthEndingAtEpoch(List<int> sortedEpochDays) {
  final result = <int, int>{};
  int? previous;
  var run = 0;
  for (final epoch in sortedEpochDays) {
    run = (previous != null && epoch == previous + 1) ? run + 1 : 1;
    result[epoch] = run;
    previous = epoch;
  }
  return result;
}

int _levelForRunLength(int run) {
  if (run <= 0) return 0;
  if (run <= 2) return 1;
  if (run <= 6) return 2;
  if (run <= 13) return 3;
  return 4;
}

/// Isı haritası için hafta×gün ızgarasını üretir.
///
/// [windowWeeks] kadar hafta geriye gider, en son hafta bugünü içerir.
/// Bugünden sonraki günler (bu haftanın henüz yaşanmamış kısmı) `null` olur.
/// Ay etiketleri, o ayın ilk gününün düştüğü hafta sütununa hizalanır —
/// taslaktaki eşit-aralıklı etiketlerden kasıtlı sapma (bkz. PLAN.md § B2.4.3).
HeatmapGrid buildHeatmapGrid({
  required Set<int> completedDayKeys,
  required int todayKey,
  required int windowWeeks,
}) {
  final todayEpoch = epochDayOf(todayKey);
  final sortedEpochDays = completedDayKeys.map(epochDayOf).toSet().toList()
    ..sort();
  final epochSet = sortedEpochDays.toSet();
  final runLengths = _runLengthEndingAtEpoch(sortedEpochDays);

  final currentWeekStart = _startOfWeekEpoch(todayEpoch);
  final firstWeekStart = currentWeekStart - (windowWeeks - 1) * 7;

  final weeks = <HeatmapWeek>[];
  final monthLabels = <HeatmapMonthLabel>[];
  int? lastMonth;

  for (var w = 0; w < windowWeeks; w++) {
    final weekStart = firstWeekStart + w * 7;
    final cells = <HeatmapCell?>[];

    for (var d = 0; d < 7; d++) {
      final epoch = weekStart + d;

      if (epoch > todayEpoch) {
        cells.add(null);
        continue;
      }

      final dayKey = dayKeyOfEpoch(epoch);
      final date = dateOfDayKey(dayKey);
      if (lastMonth != date.month) {
        lastMonth = date.month;
        monthLabels.add(
          HeatmapMonthLabel(
            weekIndex: w,
            label: _turkishMonthShort[date.month - 1],
          ),
        );
      }

      final level = epochSet.contains(epoch)
          ? _levelForRunLength(runLengths[epoch] ?? 1)
          : 0;
      cells.add(HeatmapCell(dayKey: dayKey, level: level));
    }

    weeks.add(HeatmapWeek(cells));
  }

  return HeatmapGrid(weeks: weeks, monthLabels: monthLabels);
}
