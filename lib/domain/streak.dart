import 'day_key.dart';

class StreakResult {
  const StreakResult({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  bool operator ==(Object other) =>
      other is StreakResult &&
      other.current == current &&
      other.longest == longest;

  @override
  int get hashCode => Object.hash(current, longest);

  @override
  String toString() => 'StreakResult(current: $current, longest: $longest)';
}

/// Mevcut seri ve en uzun seriyi hesaplar.
///
/// "Mevcut seri" kuralı: bugün işaretliyse bugünden geriye sayılır. Bugün
/// henüz işaretlenmediyse ama dün işaretliyse (gün henüz bitmedi, kullanıcı
/// seriyi bozmadı) dünden geriye sayılır. İkisi de yoksa mevcut seri sıfırdır.
StreakResult calculateStreak(Set<int> completedDayKeys, int todayKey) {
  if (completedDayKeys.isEmpty) {
    return const StreakResult(current: 0, longest: 0);
  }

  final sortedEpochDays = completedDayKeys.map(epochDayOf).toSet().toList()
    ..sort();

  var longest = 1;
  var run = 1;
  for (var i = 1; i < sortedEpochDays.length; i++) {
    run = sortedEpochDays[i] == sortedEpochDays[i - 1] + 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  final epochSet = sortedEpochDays.toSet();
  final todayEpoch = epochDayOf(todayKey);

  final int anchor;
  if (epochSet.contains(todayEpoch)) {
    anchor = todayEpoch;
  } else if (epochSet.contains(todayEpoch - 1)) {
    anchor = todayEpoch - 1;
  } else {
    return StreakResult(current: 0, longest: longest);
  }

  var current = 1;
  var cursor = anchor - 1;
  while (epochSet.contains(cursor)) {
    current++;
    cursor--;
  }

  return StreakResult(current: current, longest: longest);
}
