// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veritabani.dart';

// ignore_for_file: type=lint
class $KayitlarTable extends Kayitlar
    with TableInfo<$KayitlarTable, KayitSatiri> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KayitlarTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _adMeta = const VerificationMeta('ad');
  @override
  late final GeneratedColumn<String> ad = GeneratedColumn<String>(
    'ad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosyaYoluMeta = const VerificationMeta(
    'dosyaYolu',
  );
  @override
  late final GeneratedColumn<String> dosyaYolu = GeneratedColumn<String>(
    'dosya_yolu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sureMsMeta = const VerificationMeta('sureMs');
  @override
  late final GeneratedColumn<int> sureMs = GeneratedColumn<int>(
    'sure_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boyutBaytMeta = const VerificationMeta(
    'boyutBayt',
  );
  @override
  late final GeneratedColumn<int> boyutBayt = GeneratedColumn<int>(
    'boyut_bayt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _dalgaMeta = const VerificationMeta('dalga');
  @override
  late final GeneratedColumn<Uint8List> dalga = GeneratedColumn<Uint8List>(
    'dalga',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ad,
    dosyaYolu,
    sureMs,
    boyutBayt,
    olusturma,
    dalga,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kayitlar';
  @override
  VerificationContext validateIntegrity(
    Insertable<KayitSatiri> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ad')) {
      context.handle(_adMeta, ad.isAcceptableOrUnknown(data['ad']!, _adMeta));
    } else if (isInserting) {
      context.missing(_adMeta);
    }
    if (data.containsKey('dosya_yolu')) {
      context.handle(
        _dosyaYoluMeta,
        dosyaYolu.isAcceptableOrUnknown(data['dosya_yolu']!, _dosyaYoluMeta),
      );
    } else if (isInserting) {
      context.missing(_dosyaYoluMeta);
    }
    if (data.containsKey('sure_ms')) {
      context.handle(
        _sureMsMeta,
        sureMs.isAcceptableOrUnknown(data['sure_ms']!, _sureMsMeta),
      );
    } else if (isInserting) {
      context.missing(_sureMsMeta);
    }
    if (data.containsKey('boyut_bayt')) {
      context.handle(
        _boyutBaytMeta,
        boyutBayt.isAcceptableOrUnknown(data['boyut_bayt']!, _boyutBaytMeta),
      );
    } else if (isInserting) {
      context.missing(_boyutBaytMeta);
    }
    if (data.containsKey('olusturma')) {
      context.handle(
        _olusturmaMeta,
        olusturma.isAcceptableOrUnknown(data['olusturma']!, _olusturmaMeta),
      );
    } else if (isInserting) {
      context.missing(_olusturmaMeta);
    }
    if (data.containsKey('dalga')) {
      context.handle(
        _dalgaMeta,
        dalga.isAcceptableOrUnknown(data['dalga']!, _dalgaMeta),
      );
    } else if (isInserting) {
      context.missing(_dalgaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KayitSatiri map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KayitSatiri(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ad'],
      )!,
      dosyaYolu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosya_yolu'],
      )!,
      sureMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sure_ms'],
      )!,
      boyutBayt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boyut_bayt'],
      )!,
      olusturma: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}olusturma'],
      )!,
      dalga: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}dalga'],
      )!,
    );
  }

  @override
  $KayitlarTable createAlias(String alias) {
    return $KayitlarTable(attachedDatabase, alias);
  }
}

class KayitSatiri extends DataClass implements Insertable<KayitSatiri> {
  final int id;
  final String ad;
  final String dosyaYolu;
  final int sureMs;
  final int boyutBayt;
  final DateTime olusturma;
  final Uint8List dalga;
  const KayitSatiri({
    required this.id,
    required this.ad,
    required this.dosyaYolu,
    required this.sureMs,
    required this.boyutBayt,
    required this.olusturma,
    required this.dalga,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ad'] = Variable<String>(ad);
    map['dosya_yolu'] = Variable<String>(dosyaYolu);
    map['sure_ms'] = Variable<int>(sureMs);
    map['boyut_bayt'] = Variable<int>(boyutBayt);
    map['olusturma'] = Variable<DateTime>(olusturma);
    map['dalga'] = Variable<Uint8List>(dalga);
    return map;
  }

  KayitlarCompanion toCompanion(bool nullToAbsent) {
    return KayitlarCompanion(
      id: Value(id),
      ad: Value(ad),
      dosyaYolu: Value(dosyaYolu),
      sureMs: Value(sureMs),
      boyutBayt: Value(boyutBayt),
      olusturma: Value(olusturma),
      dalga: Value(dalga),
    );
  }

  factory KayitSatiri.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KayitSatiri(
      id: serializer.fromJson<int>(json['id']),
      ad: serializer.fromJson<String>(json['ad']),
      dosyaYolu: serializer.fromJson<String>(json['dosyaYolu']),
      sureMs: serializer.fromJson<int>(json['sureMs']),
      boyutBayt: serializer.fromJson<int>(json['boyutBayt']),
      olusturma: serializer.fromJson<DateTime>(json['olusturma']),
      dalga: serializer.fromJson<Uint8List>(json['dalga']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ad': serializer.toJson<String>(ad),
      'dosyaYolu': serializer.toJson<String>(dosyaYolu),
      'sureMs': serializer.toJson<int>(sureMs),
      'boyutBayt': serializer.toJson<int>(boyutBayt),
      'olusturma': serializer.toJson<DateTime>(olusturma),
      'dalga': serializer.toJson<Uint8List>(dalga),
    };
  }

  KayitSatiri copyWith({
    int? id,
    String? ad,
    String? dosyaYolu,
    int? sureMs,
    int? boyutBayt,
    DateTime? olusturma,
    Uint8List? dalga,
  }) => KayitSatiri(
    id: id ?? this.id,
    ad: ad ?? this.ad,
    dosyaYolu: dosyaYolu ?? this.dosyaYolu,
    sureMs: sureMs ?? this.sureMs,
    boyutBayt: boyutBayt ?? this.boyutBayt,
    olusturma: olusturma ?? this.olusturma,
    dalga: dalga ?? this.dalga,
  );
  KayitSatiri copyWithCompanion(KayitlarCompanion data) {
    return KayitSatiri(
      id: data.id.present ? data.id.value : this.id,
      ad: data.ad.present ? data.ad.value : this.ad,
      dosyaYolu: data.dosyaYolu.present ? data.dosyaYolu.value : this.dosyaYolu,
      sureMs: data.sureMs.present ? data.sureMs.value : this.sureMs,
      boyutBayt: data.boyutBayt.present ? data.boyutBayt.value : this.boyutBayt,
      olusturma: data.olusturma.present ? data.olusturma.value : this.olusturma,
      dalga: data.dalga.present ? data.dalga.value : this.dalga,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KayitSatiri(')
          ..write('id: $id, ')
          ..write('ad: $ad, ')
          ..write('dosyaYolu: $dosyaYolu, ')
          ..write('sureMs: $sureMs, ')
          ..write('boyutBayt: $boyutBayt, ')
          ..write('olusturma: $olusturma, ')
          ..write('dalga: $dalga')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ad,
    dosyaYolu,
    sureMs,
    boyutBayt,
    olusturma,
    $driftBlobEquality.hash(dalga),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KayitSatiri &&
          other.id == this.id &&
          other.ad == this.ad &&
          other.dosyaYolu == this.dosyaYolu &&
          other.sureMs == this.sureMs &&
          other.boyutBayt == this.boyutBayt &&
          other.olusturma == this.olusturma &&
          $driftBlobEquality.equals(other.dalga, this.dalga));
}

class KayitlarCompanion extends UpdateCompanion<KayitSatiri> {
  final Value<int> id;
  final Value<String> ad;
  final Value<String> dosyaYolu;
  final Value<int> sureMs;
  final Value<int> boyutBayt;
  final Value<DateTime> olusturma;
  final Value<Uint8List> dalga;
  const KayitlarCompanion({
    this.id = const Value.absent(),
    this.ad = const Value.absent(),
    this.dosyaYolu = const Value.absent(),
    this.sureMs = const Value.absent(),
    this.boyutBayt = const Value.absent(),
    this.olusturma = const Value.absent(),
    this.dalga = const Value.absent(),
  });
  KayitlarCompanion.insert({
    this.id = const Value.absent(),
    required String ad,
    required String dosyaYolu,
    required int sureMs,
    required int boyutBayt,
    required DateTime olusturma,
    required Uint8List dalga,
  }) : ad = Value(ad),
       dosyaYolu = Value(dosyaYolu),
       sureMs = Value(sureMs),
       boyutBayt = Value(boyutBayt),
       olusturma = Value(olusturma),
       dalga = Value(dalga);
  static Insertable<KayitSatiri> custom({
    Expression<int>? id,
    Expression<String>? ad,
    Expression<String>? dosyaYolu,
    Expression<int>? sureMs,
    Expression<int>? boyutBayt,
    Expression<DateTime>? olusturma,
    Expression<Uint8List>? dalga,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ad != null) 'ad': ad,
      if (dosyaYolu != null) 'dosya_yolu': dosyaYolu,
      if (sureMs != null) 'sure_ms': sureMs,
      if (boyutBayt != null) 'boyut_bayt': boyutBayt,
      if (olusturma != null) 'olusturma': olusturma,
      if (dalga != null) 'dalga': dalga,
    });
  }

  KayitlarCompanion copyWith({
    Value<int>? id,
    Value<String>? ad,
    Value<String>? dosyaYolu,
    Value<int>? sureMs,
    Value<int>? boyutBayt,
    Value<DateTime>? olusturma,
    Value<Uint8List>? dalga,
  }) {
    return KayitlarCompanion(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      dosyaYolu: dosyaYolu ?? this.dosyaYolu,
      sureMs: sureMs ?? this.sureMs,
      boyutBayt: boyutBayt ?? this.boyutBayt,
      olusturma: olusturma ?? this.olusturma,
      dalga: dalga ?? this.dalga,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ad.present) {
      map['ad'] = Variable<String>(ad.value);
    }
    if (dosyaYolu.present) {
      map['dosya_yolu'] = Variable<String>(dosyaYolu.value);
    }
    if (sureMs.present) {
      map['sure_ms'] = Variable<int>(sureMs.value);
    }
    if (boyutBayt.present) {
      map['boyut_bayt'] = Variable<int>(boyutBayt.value);
    }
    if (olusturma.present) {
      map['olusturma'] = Variable<DateTime>(olusturma.value);
    }
    if (dalga.present) {
      map['dalga'] = Variable<Uint8List>(dalga.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KayitlarCompanion(')
          ..write('id: $id, ')
          ..write('ad: $ad, ')
          ..write('dosyaYolu: $dosyaYolu, ')
          ..write('sureMs: $sureMs, ')
          ..write('boyutBayt: $boyutBayt, ')
          ..write('olusturma: $olusturma, ')
          ..write('dalga: $dalga')
          ..write(')'))
        .toString();
  }
}

abstract class _$Veritabani extends GeneratedDatabase {
  _$Veritabani(QueryExecutor e) : super(e);
  $VeritabaniManager get managers => $VeritabaniManager(this);
  late final $KayitlarTable kayitlar = $KayitlarTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [kayitlar];
}

typedef $$KayitlarTableCreateCompanionBuilder =
    KayitlarCompanion Function({
      Value<int> id,
      required String ad,
      required String dosyaYolu,
      required int sureMs,
      required int boyutBayt,
      required DateTime olusturma,
      required Uint8List dalga,
    });
typedef $$KayitlarTableUpdateCompanionBuilder =
    KayitlarCompanion Function({
      Value<int> id,
      Value<String> ad,
      Value<String> dosyaYolu,
      Value<int> sureMs,
      Value<int> boyutBayt,
      Value<DateTime> olusturma,
      Value<Uint8List> dalga,
    });

class $$KayitlarTableFilterComposer
    extends Composer<_$Veritabani, $KayitlarTable> {
  $$KayitlarTableFilterComposer({
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

  ColumnFilters<String> get ad => $composableBuilder(
    column: $table.ad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosyaYolu => $composableBuilder(
    column: $table.dosyaYolu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sureMs => $composableBuilder(
    column: $table.sureMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boyutBayt => $composableBuilder(
    column: $table.boyutBayt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get olusturma => $composableBuilder(
    column: $table.olusturma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get dalga => $composableBuilder(
    column: $table.dalga,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KayitlarTableOrderingComposer
    extends Composer<_$Veritabani, $KayitlarTable> {
  $$KayitlarTableOrderingComposer({
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

  ColumnOrderings<String> get ad => $composableBuilder(
    column: $table.ad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosyaYolu => $composableBuilder(
    column: $table.dosyaYolu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sureMs => $composableBuilder(
    column: $table.sureMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boyutBayt => $composableBuilder(
    column: $table.boyutBayt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get olusturma => $composableBuilder(
    column: $table.olusturma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get dalga => $composableBuilder(
    column: $table.dalga,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KayitlarTableAnnotationComposer
    extends Composer<_$Veritabani, $KayitlarTable> {
  $$KayitlarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ad =>
      $composableBuilder(column: $table.ad, builder: (column) => column);

  GeneratedColumn<String> get dosyaYolu =>
      $composableBuilder(column: $table.dosyaYolu, builder: (column) => column);

  GeneratedColumn<int> get sureMs =>
      $composableBuilder(column: $table.sureMs, builder: (column) => column);

  GeneratedColumn<int> get boyutBayt =>
      $composableBuilder(column: $table.boyutBayt, builder: (column) => column);

  GeneratedColumn<DateTime> get olusturma =>
      $composableBuilder(column: $table.olusturma, builder: (column) => column);

  GeneratedColumn<Uint8List> get dalga =>
      $composableBuilder(column: $table.dalga, builder: (column) => column);
}

class $$KayitlarTableTableManager
    extends
        RootTableManager<
          _$Veritabani,
          $KayitlarTable,
          KayitSatiri,
          $$KayitlarTableFilterComposer,
          $$KayitlarTableOrderingComposer,
          $$KayitlarTableAnnotationComposer,
          $$KayitlarTableCreateCompanionBuilder,
          $$KayitlarTableUpdateCompanionBuilder,
          (
            KayitSatiri,
            BaseReferences<_$Veritabani, $KayitlarTable, KayitSatiri>,
          ),
          KayitSatiri,
          PrefetchHooks Function()
        > {
  $$KayitlarTableTableManager(_$Veritabani db, $KayitlarTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KayitlarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KayitlarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KayitlarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ad = const Value.absent(),
                Value<String> dosyaYolu = const Value.absent(),
                Value<int> sureMs = const Value.absent(),
                Value<int> boyutBayt = const Value.absent(),
                Value<DateTime> olusturma = const Value.absent(),
                Value<Uint8List> dalga = const Value.absent(),
              }) => KayitlarCompanion(
                id: id,
                ad: ad,
                dosyaYolu: dosyaYolu,
                sureMs: sureMs,
                boyutBayt: boyutBayt,
                olusturma: olusturma,
                dalga: dalga,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ad,
                required String dosyaYolu,
                required int sureMs,
                required int boyutBayt,
                required DateTime olusturma,
                required Uint8List dalga,
              }) => KayitlarCompanion.insert(
                id: id,
                ad: ad,
                dosyaYolu: dosyaYolu,
                sureMs: sureMs,
                boyutBayt: boyutBayt,
                olusturma: olusturma,
                dalga: dalga,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KayitlarTable, KayitSatiri>(table),
                  BaseReferences<_$Veritabani, $KayitlarTable, KayitSatiri>(
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

typedef $$KayitlarTableProcessedTableManager =
    ProcessedTableManager<
      _$Veritabani,
      $KayitlarTable,
      KayitSatiri,
      $$KayitlarTableFilterComposer,
      $$KayitlarTableOrderingComposer,
      $$KayitlarTableAnnotationComposer,
      $$KayitlarTableCreateCompanionBuilder,
      $$KayitlarTableUpdateCompanionBuilder,
      (KayitSatiri, BaseReferences<_$Veritabani, $KayitlarTable, KayitSatiri>),
      KayitSatiri,
      PrefetchHooks Function()
    >;

class $VeritabaniManager {
  final _$Veritabani _db;
  $VeritabaniManager(this._db);
  $$KayitlarTableTableManager get kayitlar =>
      $$KayitlarTableTableManager(_db, _db.kayitlar);
}
