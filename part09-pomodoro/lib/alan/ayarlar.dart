import 'faz.dart';

/// Kullanıcı ayarları (PLAN K5). Değişmez. Süreler saniye cinsindendir,
/// ayarlar ekranında dakika + saniye (5'er) seçilir.
class Ayarlar {
  const Ayarlar({
    this.calismaSn = 25 * 60,
    this.kisaMolaSn = 5 * 60,
    this.uzunMolaSn = 15 * 60,
    this.ses = true,
  });

  /// En kısa 5 sn; en uzun 90 / 30 / 60 dk.
  static const calismaAralik = (5, 90 * 60);
  static const kisaMolaAralik = (5, 30 * 60);
  static const uzunMolaAralik = (5, 60 * 60);

  final int calismaSn;
  final int kisaMolaSn;
  final int uzunMolaSn;
  final bool ses;

  Duration sure(Faz faz) => Duration(
    seconds: switch (faz) {
      Faz.calisma => calismaSn,
      Faz.kisaMola => kisaMolaSn,
      Faz.uzunMola => uzunMolaSn,
    },
  );

  Ayarlar kopya({
    int? calismaSn,
    int? kisaMolaSn,
    int? uzunMolaSn,
    bool? ses,
  }) => Ayarlar(
    calismaSn: _sinirla(calismaSn ?? this.calismaSn, calismaAralik),
    kisaMolaSn: _sinirla(kisaMolaSn ?? this.kisaMolaSn, kisaMolaAralik),
    uzunMolaSn: _sinirla(uzunMolaSn ?? this.uzunMolaSn, uzunMolaAralik),
    ses: ses ?? this.ses,
  );

  Map<String, Object> toJson() => {
    'calismaSn': calismaSn,
    'kisaMolaSn': kisaMolaSn,
    'uzunMolaSn': uzunMolaSn,
    'ses': ses,
  };

  /// Bozuk ya da eksik veri varsayılana düşer, çökmez. Eski sürümün
  /// dakika alanları (`calismaDk` …) saniyeye çevrilerek okunur.
  factory Ayarlar.fromJson(Object? json) {
    if (json is! Map) return const Ayarlar();
    int sure(String ad, int varsayilan, (int, int) aralik) {
      final sn = json['${ad}Sn'];
      if (sn is int) return _sinirla(sn, aralik);
      final dk = json['${ad}Dk'];
      if (dk is int) return _sinirla(dk * 60, aralik);
      return varsayilan;
    }

    final ses = json['ses'];
    return Ayarlar(
      calismaSn: sure('calisma', 25 * 60, calismaAralik),
      kisaMolaSn: sure('kisaMola', 5 * 60, kisaMolaAralik),
      uzunMolaSn: sure('uzunMola', 15 * 60, uzunMolaAralik),
      ses: ses is bool ? ses : true,
    );
  }

  static int _sinirla(int v, (int, int) aralik) =>
      v < aralik.$1 ? aralik.$1 : (v > aralik.$2 ? aralik.$2 : v);

  @override
  bool operator ==(Object other) =>
      other is Ayarlar &&
      other.calismaSn == calismaSn &&
      other.kisaMolaSn == kisaMolaSn &&
      other.uzunMolaSn == uzunMolaSn &&
      other.ses == ses;

  @override
  int get hashCode => Object.hash(calismaSn, kisaMolaSn, uzunMolaSn, ses);
}
