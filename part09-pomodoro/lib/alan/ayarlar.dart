import 'faz.dart';

/// Kullanıcı ayarları (PLAN K5). Değişmez.
class Ayarlar {
  const Ayarlar({
    this.calismaDk = 25,
    this.kisaMolaDk = 5,
    this.uzunMolaDk = 15,
    this.ses = true,
  });

  static const calismaAralik = (1, 90);
  static const kisaMolaAralik = (1, 30);
  static const uzunMolaAralik = (1, 60);

  final int calismaDk;
  final int kisaMolaDk;
  final int uzunMolaDk;
  final bool ses;

  Duration sure(Faz faz) => Duration(
    minutes: switch (faz) {
      Faz.calisma => calismaDk,
      Faz.kisaMola => kisaMolaDk,
      Faz.uzunMola => uzunMolaDk,
    },
  );

  Ayarlar kopya({
    int? calismaDk,
    int? kisaMolaDk,
    int? uzunMolaDk,
    bool? ses,
  }) => Ayarlar(
    calismaDk: _sinirla(calismaDk ?? this.calismaDk, calismaAralik),
    kisaMolaDk: _sinirla(kisaMolaDk ?? this.kisaMolaDk, kisaMolaAralik),
    uzunMolaDk: _sinirla(uzunMolaDk ?? this.uzunMolaDk, uzunMolaAralik),
    ses: ses ?? this.ses,
  );

  Map<String, Object> toJson() => {
    'calismaDk': calismaDk,
    'kisaMolaDk': kisaMolaDk,
    'uzunMolaDk': uzunMolaDk,
    'ses': ses,
  };

  /// Bozuk ya da eksik veri varsayılana düşer, çökmez.
  factory Ayarlar.fromJson(Object? json) {
    if (json is! Map) return const Ayarlar();
    int sayi(String k, int v, (int, int) aralik) {
      final x = json[k];
      return x is int ? _sinirla(x, aralik) : v;
    }

    final ses = json['ses'];
    return Ayarlar(
      calismaDk: sayi('calismaDk', 25, calismaAralik),
      kisaMolaDk: sayi('kisaMolaDk', 5, kisaMolaAralik),
      uzunMolaDk: sayi('uzunMolaDk', 15, uzunMolaAralik),
      ses: ses is bool ? ses : true,
    );
  }

  static int _sinirla(int v, (int, int) aralik) =>
      v < aralik.$1 ? aralik.$1 : (v > aralik.$2 ? aralik.$2 : v);

  @override
  bool operator ==(Object other) =>
      other is Ayarlar &&
      other.calismaDk == calismaDk &&
      other.kisaMolaDk == kisaMolaDk &&
      other.uzunMolaDk == uzunMolaDk &&
      other.ses == ses;

  @override
  int get hashCode => Object.hash(calismaDk, kisaMolaDk, uzunMolaDk, ses);
}
