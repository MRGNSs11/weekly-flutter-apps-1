import 'package:drift/drift.dart';

import 'database.dart';

class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Stream<List<Habit>> watchHabits() {
    return (_db.select(
      _db.habits,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  /// Tek bir alışkanlığı canlı izler. Detay ekranı düzenleme sonrası güncel
  /// kalsın, alışkanlık silinirse de `null` yayınlanıp geri dönüş
  /// tetiklenebilsin diye eklendi.
  Stream<Habit?> watchHabit(int habitId) {
    return (_db.select(
      _db.habits,
    )..where((t) => t.id.equals(habitId))).watchSingleOrNull();
  }

  Future<int> addHabit({required String name, required int colorValue}) {
    return _db
        .into(_db.habits)
        .insert(HabitsCompanion.insert(name: name, colorValue: colorValue));
  }

  Future<void> updateHabit({
    required int habitId,
    String? name,
    int? colorValue,
  }) {
    return (_db.update(_db.habits)..where((t) => t.id.equals(habitId))).write(
      HabitsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        colorValue: colorValue != null
            ? Value(colorValue)
            : const Value.absent(),
      ),
    );
  }

  Future<void> deleteHabit(int habitId) {
    return (_db.delete(_db.habits)..where((t) => t.id.equals(habitId))).go();
  }

  /// Bir alışkanlığın işaretlediği tüm günleri canlı olarak yayınlar.
  /// Streak ve ısı haritası hesapları bu setten (saf domain fonksiyonlarıyla)
  /// türetilir — repository sadece veri sağlar, hesap yapmaz.
  Stream<Set<int>> watchCompletedDayKeys(int habitId) {
    return (_db.select(_db.completions)
          ..where((t) => t.habitId.equals(habitId)))
        .watch()
        .map((rows) => rows.map((r) => r.dayKey).toSet());
  }

  Future<void> setDayDone(int habitId, int dayKey, {required bool done}) {
    if (done) {
      return _db
          .into(_db.completions)
          .insert(
            CompletionsCompanion.insert(habitId: habitId, dayKey: dayKey),
            mode: InsertMode.insertOrIgnore,
          );
    }
    return (_db.delete(
      _db.completions,
    )..where((t) => t.habitId.equals(habitId) & t.dayKey.equals(dayKey))).go();
  }
}
