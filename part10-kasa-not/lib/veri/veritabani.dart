import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'veritabani.g.dart';

/// Açık notta `icerik` dolu, kilitli notta `sifreli` dolu; ikisi birlikte olmaz.
@DataClassName('NotSatiri')
class Notlar extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get icerik => text().nullable()();
  BlobColumn get sifreli => blob().nullable()();
  BoolColumn get kilitli => boolean().withDefault(const Constant(false))();
  BoolColumn get sabit => boolean().withDefault(const Constant(false))();
  DateTimeColumn get olusturma => dateTime()();
  DateTimeColumn get guncelleme => dateTime()();
}

@DriftDatabase(tables: [Notlar])
class Veritabani extends _$Veritabani {
  Veritabani() : super(driftDatabase(name: 'kasa_not'));
  Veritabani.test(super.e);

  @override
  int get schemaVersion => 1;
}
