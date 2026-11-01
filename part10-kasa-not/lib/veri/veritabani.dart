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

/// Küçük tercihler (tema). Ayrı paket yerine aynı veritabanı.
@DataClassName('Ayar')
class Ayarlar extends Table {
  TextColumn get anahtar => text()();
  TextColumn get deger => text()();

  @override
  Set<Column> get primaryKey => {anahtar};
}

@DriftDatabase(tables: [Notlar, Ayarlar])
class Veritabani extends _$Veritabani {
  Veritabani() : _ornekler = true, super(driftDatabase(name: 'kasa_not'));
  Veritabani.test(super.e) : _ornekler = false;

  final bool _ornekler;

  @override
  int get schemaVersion => 2;

  /// İlk kurulumda (veritabanı yeni oluşunca) örnek notlar eklenir; kullanıcı
  /// hepsini silerse geri gelmez.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, eski, yeni) async {
      if (eski < 2) await m.createTable(ayarlar);
    },
    onCreate: (m) async {
      await m.createAll();
      if (!_ornekler) return;
      final simdi = DateTime.now();
      for (final (i, metin) in ornekNotlar.indexed) {
        final t = simdi.subtract(Duration(minutes: i));
        await into(notlar).insert(
          NotlarCompanion.insert(
            icerik: Value(metin),
            olusturma: t,
            guncelleme: t,
          ),
        );
      }
    },
  );
}

const ornekNotlar = [
  "# Kasa Not'a hoş geldin\n\nBir notu **basılı tut** → **Kilitle**. "
      'Kilitli notlar camın arkasına geçer, parmak izinle açılır.\n\n'
      'Uygulamadan çıkınca kasa kendiliğinden kapanır.',
  '# Market listesi\n- [x] Süt\n- [ ] Ekmek\n- [ ] Domates **(2 kg)**\n\n'
      'Pazardan *taze* olanı al.',
  '# Markdown kopya kâğıdı\n**kalın** · *eğik* · `kod`\n- madde\n- [ ] görev\n'
      '```\nkod bloğu\n```',
];

extension AyarIslemleri on Veritabani {
  Future<String?> ayarOku(String anahtar) async => (await (select(
    ayarlar,
  )..where((t) => t.anahtar.equals(anahtar))).getSingleOrNull())?.deger;

  Future<void> ayarYaz(String anahtar, String deger) =>
      into(ayarlar).insertOnConflictUpdate(
        AyarlarCompanion.insert(anahtar: anahtar, deger: deger),
      );
}
