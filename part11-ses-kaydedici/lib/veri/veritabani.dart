import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'veritabani.g.dart';

/// Ses dosyası uygulamanın kendi klasöründe; burada yalnız bilgisi ve
/// dalgası (örnek başına 1 bayt) durur.
@DataClassName('KayitSatiri')
class Kayitlar extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ad => text()();
  TextColumn get dosyaYolu => text()();
  IntColumn get sureMs => integer()();
  IntColumn get boyutBayt => integer()();
  DateTimeColumn get olusturma => dateTime()();
  BlobColumn get dalga => blob()();
}

@DriftDatabase(tables: [Kayitlar])
class Veritabani extends _$Veritabani {
  Veritabani() : super(driftDatabase(name: 'ses_kaydedici'));
  Veritabani.test(super.e);

  @override
  int get schemaVersion => 1;
}
