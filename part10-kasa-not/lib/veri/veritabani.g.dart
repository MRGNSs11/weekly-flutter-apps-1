// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veritabani.dart';

// ignore_for_file: type=lint
class $NotlarTable extends Notlar with TableInfo<$NotlarTable, NotSatiri> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotlarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _icerikMeta = const VerificationMeta('icerik');
  @override
  late final GeneratedColumn<String> icerik = GeneratedColumn<String>(
    'icerik',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sifreliMeta = const VerificationMeta(
    'sifreli',
  );
  @override
  late final GeneratedColumn<Uint8List> sifreli = GeneratedColumn<Uint8List>(
    'sifreli',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kilitliMeta = const VerificationMeta(
    'kilitli',
  );
  @override
  late final GeneratedColumn<bool> kilitli = GeneratedColumn<bool>(
    'kilitli',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kilitli" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sabitMeta = const VerificationMeta('sabit');
  @override
  late final GeneratedColumn<bool> sabit = GeneratedColumn<bool>(
    'sabit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sabit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _olusturmaMeta = const VerificationMeta(
    'olusturma',
  );
  @override
  late final GeneratedColumn<DateTime> olusturma = GeneratedColumn<DateTime>(
    'olusturma',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guncellemeMeta = const VerificationMeta(
    'guncelleme',
  );
  @override
  late final GeneratedColumn<DateTime> guncelleme = GeneratedColumn<DateTime>(
    'guncelleme',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    icerik,
    sifreli,
    kilitli,
    sabit,
    olusturma,
    guncelleme,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notlar';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotSatiri> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('icerik')) {
      context.handle(
        _icerikMeta,
        icerik.isAcceptableOrUnknown(data['icerik']!, _icerikMeta),
      );
    }
    if (data.containsKey('sifreli')) {
      context.handle(
        _sifreliMeta,
        sifreli.isAcceptableOrUnknown(data['sifreli']!, _sifreliMeta),
      );
    }
    if (data.containsKey('kilitli')) {
      context.handle(
        _kilitliMeta,
        kilitli.isAcceptableOrUnknown(data['kilitli']!, _kilitliMeta),
      );
    }
    if (data.containsKey('sabit')) {
      context.handle(
        _sabitMeta,
        sabit.isAcceptableOrUnknown(data['sabit']!, _sabitMeta),
      );
    }
    if (data.containsKey('olusturma')) {
      context.handle(
        _olusturmaMeta,
        olusturma.isAcceptableOrUnknown(data['olusturma']!, _olusturmaMeta),
      );
    } else if (isInserting) {
      context.missing(_olusturmaMeta);
    }
    if (data.containsKey('guncelleme')) {
      context.handle(
        _guncellemeMeta,
        guncelleme.isAcceptableOrUnknown(data['guncelleme']!, _guncellemeMeta),
      );
    } else if (isInserting) {
      context.missing(_guncellemeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotSatiri map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotSatiri(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      icerik: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icerik'],
      ),
      sifreli: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sifreli'],
      ),
      kilitli: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kilitli'],
      )!,
      sabit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sabit'],
      )!,
      olusturma: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}olusturma'],
      )!,
      guncelleme: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}guncelleme'],
      )!,
    );
  }

  @override
  $NotlarTable createAlias(String alias) {
    return $NotlarTable(attachedDatabase, alias);
  }
}

class NotSatiri extends DataClass implements Insertable<NotSatiri> {
  final int id;
  final String? icerik;
  final Uint8List? sifreli;
  final bool kilitli;
  final bool sabit;
  final DateTime olusturma;
  final DateTime guncelleme;
  const NotSatiri({
    required this.id,
    this.icerik,
    this.sifreli,
    required this.kilitli,
    required this.sabit,
    required this.olusturma,
    required this.guncelleme,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || icerik != null) {
      map['icerik'] = Variable<String>(icerik);
    }
    if (!nullToAbsent || sifreli != null) {
      map['sifreli'] = Variable<Uint8List>(sifreli);
    }
    map['kilitli'] = Variable<bool>(kilitli);
    map['sabit'] = Variable<bool>(sabit);
    map['olusturma'] = Variable<DateTime>(olusturma);
    map['guncelleme'] = Variable<DateTime>(guncelleme);
    return map;
  }

  NotlarCompanion toCompanion(bool nullToAbsent) {
    return NotlarCompanion(
      id: Value(id),
      icerik: icerik == null && nullToAbsent
          ? const Value.absent()
          : Value(icerik),
      sifreli: sifreli == null && nullToAbsent
          ? const Value.absent()
          : Value(sifreli),
      kilitli: Value(kilitli),
      sabit: Value(sabit),
      olusturma: Value(olusturma),
      guncelleme: Value(guncelleme),
    );
  }

  factory NotSatiri.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotSatiri(
      id: serializer.fromJson<int>(json['id']),
      icerik: serializer.fromJson<String?>(json['icerik']),
      sifreli: serializer.fromJson<Uint8List?>(json['sifreli']),
      kilitli: serializer.fromJson<bool>(json['kilitli']),
      sabit: serializer.fromJson<bool>(json['sabit']),
      olusturma: serializer.fromJson<DateTime>(json['olusturma']),
      guncelleme: serializer.fromJson<DateTime>(json['guncelleme']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'icerik': serializer.toJson<String?>(icerik),
      'sifreli': serializer.toJson<Uint8List?>(sifreli),
      'kilitli': serializer.toJson<bool>(kilitli),
      'sabit': serializer.toJson<bool>(sabit),
      'olusturma': serializer.toJson<DateTime>(olusturma),
      'guncelleme': serializer.toJson<DateTime>(guncelleme),
    };
  }

  NotSatiri copyWith({
    int? id,
    Value<String?> icerik = const Value.absent(),
    Value<Uint8List?> sifreli = const Value.absent(),
    bool? kilitli,
    bool? sabit,
    DateTime? olusturma,
    DateTime? guncelleme,
  }) => NotSatiri(
    id: id ?? this.id,
    icerik: icerik.present ? icerik.value : this.icerik,
    sifreli: sifreli.present ? sifreli.value : this.sifreli,
    kilitli: kilitli ?? this.kilitli,
    sabit: sabit ?? this.sabit,
    olusturma: olusturma ?? this.olusturma,
    guncelleme: guncelleme ?? this.guncelleme,
  );
  NotSatiri copyWithCompanion(NotlarCompanion data) {
    return NotSatiri(
      id: data.id.present ? data.id.value : this.id,
      icerik: data.icerik.present ? data.icerik.value : this.icerik,
      sifreli: data.sifreli.present ? data.sifreli.value : this.sifreli,
      kilitli: data.kilitli.present ? data.kilitli.value : this.kilitli,
      sabit: data.sabit.present ? data.sabit.value : this.sabit,
      olusturma: data.olusturma.present ? data.olusturma.value : this.olusturma,
      guncelleme: data.guncelleme.present
          ? data.guncelleme.value
          : this.guncelleme,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotSatiri(')
          ..write('id: $id, ')
          ..write('icerik: $icerik, ')
          ..write('sifreli: $sifreli, ')
          ..write('kilitli: $kilitli, ')
          ..write('sabit: $sabit, ')
          ..write('olusturma: $olusturma, ')
          ..write('guncelleme: $guncelleme')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    icerik,
    $driftBlobEquality.hash(sifreli),
    kilitli,
    sabit,
    olusturma,
    guncelleme,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotSatiri &&
          other.id == this.id &&
          other.icerik == this.icerik &&
          $driftBlobEquality.equals(other.sifreli, this.sifreli) &&
          other.kilitli == this.kilitli &&
          other.sabit == this.sabit &&
          other.olusturma == this.olusturma &&
          other.guncelleme == this.guncelleme);
}

class NotlarCompanion extends UpdateCompanion<NotSatiri> {
  final Value<int> id;
  final Value<String?> icerik;
  final Value<Uint8List?> sifreli;
  final Value<bool> kilitli;
  final Value<bool> sabit;
  final Value<DateTime> olusturma;
  final Value<DateTime> guncelleme;
  const NotlarCompanion({
    this.id = const Value.absent(),
    this.icerik = const Value.absent(),
    this.sifreli = const Value.absent(),
    this.kilitli = const Value.absent(),
    this.sabit = const Value.absent(),
    this.olusturma = const Value.absent(),
    this.guncelleme = const Value.absent(),
  });
  NotlarCompanion.insert({
    this.id = const Value.absent(),
    this.icerik = const Value.absent(),
    this.sifreli = const Value.absent(),
    this.kilitli = const Value.absent(),
    this.sabit = const Value.absent(),
    required DateTime olusturma,
    required DateTime guncelleme,
  }) : olusturma = Value(olusturma),
       guncelleme = Value(guncelleme);
  static Insertable<NotSatiri> custom({
    Expression<int>? id,
    Expression<String>? icerik,
    Expression<Uint8List>? sifreli,
    Expression<bool>? kilitli,
    Expression<bool>? sabit,
    Expression<DateTime>? olusturma,
    Expression<DateTime>? guncelleme,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (icerik != null) 'icerik': icerik,
      if (sifreli != null) 'sifreli': sifreli,
      if (kilitli != null) 'kilitli': kilitli,
      if (sabit != null) 'sabit': sabit,
      if (olusturma != null) 'olusturma': olusturma,
      if (guncelleme != null) 'guncelleme': guncelleme,
    });
  }

  NotlarCompanion copyWith({
    Value<int>? id,
    Value<String?>? icerik,
    Value<Uint8List?>? sifreli,
    Value<bool>? kilitli,
    Value<bool>? sabit,
    Value<DateTime>? olusturma,
    Value<DateTime>? guncelleme,
  }) {
    return NotlarCompanion(
      id: id ?? this.id,
      icerik: icerik ?? this.icerik,
      sifreli: sifreli ?? this.sifreli,
      kilitli: kilitli ?? this.kilitli,
      sabit: sabit ?? this.sabit,
      olusturma: olusturma ?? this.olusturma,
      guncelleme: guncelleme ?? this.guncelleme,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (icerik.present) {
      map['icerik'] = Variable<String>(icerik.value);
    }
    if (sifreli.present) {
      map['sifreli'] = Variable<Uint8List>(sifreli.value);
    }
    if (kilitli.present) {
      map['kilitli'] = Variable<bool>(kilitli.value);
    }
    if (sabit.present) {
      map['sabit'] = Variable<bool>(sabit.value);
    }
    if (olusturma.present) {
      map['olusturma'] = Variable<DateTime>(olusturma.value);
    }
    if (guncelleme.present) {
      map['guncelleme'] = Variable<DateTime>(guncelleme.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotlarCompanion(')
          ..write('id: $id, ')
          ..write('icerik: $icerik, ')
          ..write('sifreli: $sifreli, ')
          ..write('kilitli: $kilitli, ')
          ..write('sabit: $sabit, ')
          ..write('olusturma: $olusturma, ')
          ..write('guncelleme: $guncelleme')
          ..write(')'))
        .toString();
  }
}

class $AyarlarTable extends Ayarlar with TableInfo<$AyarlarTable, Ayar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyarlarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _anahtarMeta = const VerificationMeta(
    'anahtar',
  );
  @override
  late final GeneratedColumn<String> anahtar = GeneratedColumn<String>(
    'anahtar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _degerMeta = const VerificationMeta('deger');
  @override
  late final GeneratedColumn<String> deger = GeneratedColumn<String>(
    'deger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [anahtar, deger];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayarlar';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anahtar')) {
      context.handle(
        _anahtarMeta,
        anahtar.isAcceptableOrUnknown(data['anahtar']!, _anahtarMeta),
      );
    } else if (isInserting) {
      context.missing(_anahtarMeta);
    }
    if (data.containsKey('deger')) {
      context.handle(
        _degerMeta,
        deger.isAcceptableOrUnknown(data['deger']!, _degerMeta),
      );
    } else if (isInserting) {
      context.missing(_degerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {anahtar};
  @override
  Ayar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayar(
      anahtar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anahtar'],
      )!,
      deger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deger'],
      )!,
    );
  }

  @override
  $AyarlarTable createAlias(String alias) {
    return $AyarlarTable(attachedDatabase, alias);
  }
}

class Ayar extends DataClass implements Insertable<Ayar> {
  final String anahtar;
  final String deger;
  const Ayar({required this.anahtar, required this.deger});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anahtar'] = Variable<String>(anahtar);
    map['deger'] = Variable<String>(deger);
    return map;
  }

  AyarlarCompanion toCompanion(bool nullToAbsent) {
    return AyarlarCompanion(anahtar: Value(anahtar), deger: Value(deger));
  }

  factory Ayar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayar(
      anahtar: serializer.fromJson<String>(json['anahtar']),
      deger: serializer.fromJson<String>(json['deger']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'anahtar': serializer.toJson<String>(anahtar),
      'deger': serializer.toJson<String>(deger),
    };
  }

  Ayar copyWith({String? anahtar, String? deger}) =>
      Ayar(anahtar: anahtar ?? this.anahtar, deger: deger ?? this.deger);
  Ayar copyWithCompanion(AyarlarCompanion data) {
    return Ayar(
      anahtar: data.anahtar.present ? data.anahtar.value : this.anahtar,
      deger: data.deger.present ? data.deger.value : this.deger,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayar(')
          ..write('anahtar: $anahtar, ')
          ..write('deger: $deger')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(anahtar, deger);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayar &&
          other.anahtar == this.anahtar &&
          other.deger == this.deger);
}

class AyarlarCompanion extends UpdateCompanion<Ayar> {
  final Value<String> anahtar;
  final Value<String> deger;
  final Value<int> rowid;
  const AyarlarCompanion({
    this.anahtar = const Value.absent(),
    this.deger = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AyarlarCompanion.insert({
    required String anahtar,
    required String deger,
    this.rowid = const Value.absent(),
  }) : anahtar = Value(anahtar),
       deger = Value(deger);
  static Insertable<Ayar> custom({
    Expression<String>? anahtar,
    Expression<String>? deger,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (anahtar != null) 'anahtar': anahtar,
      if (deger != null) 'deger': deger,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AyarlarCompanion copyWith({
    Value<String>? anahtar,
    Value<String>? deger,
    Value<int>? rowid,
  }) {
    return AyarlarCompanion(
      anahtar: anahtar ?? this.anahtar,
      deger: deger ?? this.deger,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (anahtar.present) {
      map['anahtar'] = Variable<String>(anahtar.value);
    }
    if (deger.present) {
      map['deger'] = Variable<String>(deger.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyarlarCompanion(')
          ..write('anahtar: $anahtar, ')
          ..write('deger: $deger, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Veritabani extends GeneratedDatabase {
  _$Veritabani(QueryExecutor e) : super(e);
  $VeritabaniManager get managers => $VeritabaniManager(this);
  late final $NotlarTable notlar = $NotlarTable(this);
  late final $AyarlarTable ayarlar = $AyarlarTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notlar, ayarlar];
}

typedef $$NotlarTableCreateCompanionBuilder =
    NotlarCompanion Function({
      Value<int> id,
      Value<String?> icerik,
      Value<Uint8List?> sifreli,
      Value<bool> kilitli,
      Value<bool> sabit,
      required DateTime olusturma,
      required DateTime guncelleme,
    });
typedef $$NotlarTableUpdateCompanionBuilder =
    NotlarCompanion Function({
      Value<int> id,
      Value<String?> icerik,
      Value<Uint8List?> sifreli,
      Value<bool> kilitli,
      Value<bool> sabit,
      Value<DateTime> olusturma,
      Value<DateTime> guncelleme,
    });

class $$NotlarTableFilterComposer extends Composer<_$Veritabani, $NotlarTable> {
  $$NotlarTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icerik => $composableBuilder(
    column: $table.icerik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sifreli => $composableBuilder(
    column: $table.sifreli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kilitli => $composableBuilder(
    column: $table.kilitli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sabit => $composableBuilder(
    column: $table.sabit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get olusturma => $composableBuilder(
    column: $table.olusturma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get guncelleme => $composableBuilder(
    column: $table.guncelleme,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotlarTableOrderingComposer
    extends Composer<_$Veritabani, $NotlarTable> {
  $$NotlarTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icerik => $composableBuilder(
    column: $table.icerik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sifreli => $composableBuilder(
    column: $table.sifreli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kilitli => $composableBuilder(
    column: $table.kilitli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sabit => $composableBuilder(
    column: $table.sabit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get olusturma => $composableBuilder(
    column: $table.olusturma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get guncelleme => $composableBuilder(
    column: $table.guncelleme,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotlarTableAnnotationComposer
    extends Composer<_$Veritabani, $NotlarTable> {
  $$NotlarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get icerik =>
      $composableBuilder(column: $table.icerik, builder: (column) => column);

  GeneratedColumn<Uint8List> get sifreli =>
      $composableBuilder(column: $table.sifreli, builder: (column) => column);

  GeneratedColumn<bool> get kilitli =>
      $composableBuilder(column: $table.kilitli, builder: (column) => column);

  GeneratedColumn<bool> get sabit =>
      $composableBuilder(column: $table.sabit, builder: (column) => column);

  GeneratedColumn<DateTime> get olusturma =>
      $composableBuilder(column: $table.olusturma, builder: (column) => column);

  GeneratedColumn<DateTime> get guncelleme => $composableBuilder(
    column: $table.guncelleme,
    builder: (column) => column,
  );
}

class $$NotlarTableTableManager
    extends
        RootTableManager<
          _$Veritabani,
          $NotlarTable,
          NotSatiri,
          $$NotlarTableFilterComposer,
          $$NotlarTableOrderingComposer,
          $$NotlarTableAnnotationComposer,
          $$NotlarTableCreateCompanionBuilder,
          $$NotlarTableUpdateCompanionBuilder,
          (NotSatiri, BaseReferences<_$Veritabani, $NotlarTable, NotSatiri>),
          NotSatiri,
          PrefetchHooks Function()
        > {
  $$NotlarTableTableManager(_$Veritabani db, $NotlarTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotlarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotlarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotlarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> icerik = const Value.absent(),
                Value<Uint8List?> sifreli = const Value.absent(),
                Value<bool> kilitli = const Value.absent(),
                Value<bool> sabit = const Value.absent(),
                Value<DateTime> olusturma = const Value.absent(),
                Value<DateTime> guncelleme = const Value.absent(),
              }) => NotlarCompanion(
                id: id,
                icerik: icerik,
                sifreli: sifreli,
                kilitli: kilitli,
                sabit: sabit,
                olusturma: olusturma,
                guncelleme: guncelleme,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> icerik = const Value.absent(),
                Value<Uint8List?> sifreli = const Value.absent(),
                Value<bool> kilitli = const Value.absent(),
                Value<bool> sabit = const Value.absent(),
                required DateTime olusturma,
                required DateTime guncelleme,
              }) => NotlarCompanion.insert(
                id: id,
                icerik: icerik,
                sifreli: sifreli,
                kilitli: kilitli,
                sabit: sabit,
                olusturma: olusturma,
                guncelleme: guncelleme,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotlarTable, NotSatiri>(table),
                  BaseReferences<_$Veritabani, $NotlarTable, NotSatiri>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotlarTableProcessedTableManager =
    ProcessedTableManager<
      _$Veritabani,
      $NotlarTable,
      NotSatiri,
      $$NotlarTableFilterComposer,
      $$NotlarTableOrderingComposer,
      $$NotlarTableAnnotationComposer,
      $$NotlarTableCreateCompanionBuilder,
      $$NotlarTableUpdateCompanionBuilder,
      (NotSatiri, BaseReferences<_$Veritabani, $NotlarTable, NotSatiri>),
      NotSatiri,
      PrefetchHooks Function()
    >;
typedef $$AyarlarTableCreateCompanionBuilder =
    AyarlarCompanion Function({
      required String anahtar,
      required String deger,
      Value<int> rowid,
    });
typedef $$AyarlarTableUpdateCompanionBuilder =
    AyarlarCompanion Function({
      Value<String> anahtar,
      Value<String> deger,
      Value<int> rowid,
    });

class $$AyarlarTableFilterComposer
    extends Composer<_$Veritabani, $AyarlarTable> {
  $$AyarlarTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get anahtar => $composableBuilder(
    column: $table.anahtar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deger => $composableBuilder(
    column: $table.deger,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyarlarTableOrderingComposer
    extends Composer<_$Veritabani, $AyarlarTable> {
  $$AyarlarTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get anahtar => $composableBuilder(
    column: $table.anahtar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deger => $composableBuilder(
    column: $table.deger,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyarlarTableAnnotationComposer
    extends Composer<_$Veritabani, $AyarlarTable> {
  $$AyarlarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get anahtar =>
      $composableBuilder(column: $table.anahtar, builder: (column) => column);

  GeneratedColumn<String> get deger =>
      $composableBuilder(column: $table.deger, builder: (column) => column);
}

class $$AyarlarTableTableManager
    extends
        RootTableManager<
          _$Veritabani,
          $AyarlarTable,
          Ayar,
          $$AyarlarTableFilterComposer,
          $$AyarlarTableOrderingComposer,
          $$AyarlarTableAnnotationComposer,
          $$AyarlarTableCreateCompanionBuilder,
          $$AyarlarTableUpdateCompanionBuilder,
          (Ayar, BaseReferences<_$Veritabani, $AyarlarTable, Ayar>),
          Ayar,
          PrefetchHooks Function()
        > {
  $$AyarlarTableTableManager(_$Veritabani db, $AyarlarTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyarlarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyarlarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyarlarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> anahtar = const Value.absent(),
                Value<String> deger = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyarlarCompanion(
                anahtar: anahtar,
                deger: deger,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String anahtar,
                required String deger,
                Value<int> rowid = const Value.absent(),
              }) => AyarlarCompanion.insert(
                anahtar: anahtar,
                deger: deger,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyarlarTable, Ayar>(table),
                  BaseReferences<_$Veritabani, $AyarlarTable, Ayar>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyarlarTableProcessedTableManager =
    ProcessedTableManager<
      _$Veritabani,
      $AyarlarTable,
      Ayar,
      $$AyarlarTableFilterComposer,
      $$AyarlarTableOrderingComposer,
      $$AyarlarTableAnnotationComposer,
      $$AyarlarTableCreateCompanionBuilder,
      $$AyarlarTableUpdateCompanionBuilder,
      (Ayar, BaseReferences<_$Veritabani, $AyarlarTable, Ayar>),
      Ayar,
      PrefetchHooks Function()
    >;

class $VeritabaniManager {
  final _$Veritabani _db;
  $VeritabaniManager(this._db);
  $$NotlarTableTableManager get notlar =>
      $$NotlarTableTableManager(_db, _db.notlar);
  $$AyarlarTableTableManager get ayarlar =>
      $$AyarlarTableTableManager(_db, _db.ayarlar);
}
