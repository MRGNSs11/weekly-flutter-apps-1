import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Bir alışkanlığın kendisi (adı, rengi, ne zaman oluşturulduğu).
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// ARGB int olarak saklanır (Color.value ile birebir uyumlu).
  IntColumn get colorValue => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Bir alışkanlığın işaretlendiği tek bir gün.
///
/// Tarih `DateTime` yerine `yyyymmdd` biçiminde int (`dayKey`) olarak
/// tutulur — saat dilimi ve yaz saati kaymalarını baştan keser
/// (bkz. PLAN.md § Veri).
class Completions extends Table {
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayKey => integer()();

  @override
  Set<Column> get primaryKey => {habitId, dayKey};
}

@DriftDatabase(tables: [Habits, Completions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'aliskanlik_takipcisi');
  }
}
