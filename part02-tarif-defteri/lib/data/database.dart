import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/turkish_text.dart';

part 'database.g.dart';

/// Malzeme ve adım listeleri tek bir metin sütununda, satır satır saklanır.
///
/// Ayrı tablo açmadım: malzemeler yalnızca kendi tarifiyle birlikte okunur,
/// tek başına sorgulanmaz ve sıralı bir listedir. Ayrı tablo, her tarif
/// açılışında bir birleştirme (join) ve sıra sütunu getirirdi; karşılığında
/// hiçbir şey kazandırmazdı.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return fromDb.split('\n');
  }

  @override
  String toSql(List<String> value) => value.join('\n');
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Ana ekrandaki sıra. Annem en çok kullandığını yukarı taşıyabilsin diye
  /// alfabetik değil, elle sıralanır.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('Recipe')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Kategori silinirse tarif silinmez, kategorisiz kalır.
  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get ingredients =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get steps =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();

  TextColumn get note => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Ad + malzemeler, Türkçe harfleri sadeleştirilmiş halde.
  /// Arama bu sütunda yapılır; bkz. [buildSearchText].
  TextColumn get searchText => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tema ve yazı boyutu gibi tercihler.
///
/// `shared_preferences` eklemedim: zaten bir veritabanı var, ikinci bir
/// saklama yeri ikinci bir yedekleme sorunu demek.
@DataClassName('Preference')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Categories, Recipes, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'tarif_defteri'));

  /// Testlerde bellek içi veritabanı vermek için.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Kategori silindiğinde tariflerin kategorisiz kalması buna bağlı.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
