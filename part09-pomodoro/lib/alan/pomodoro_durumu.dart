import 'faz.dart';

/// Sayacın tüm durumu (PLAN K2). Değişmez; her eylem yenisini üretir.
///
/// Gerçek kaynak bitiş anıdır: sayaç geri sayılarak tutulmaz, bu yüzden uyku
/// ya da uygulamanın öldürülmesi onu kaydırmaz.
class PomodoroDurumu {
  const PomodoroDurumu({
    this.faz = Faz.calisma,
    this.durum = Durum.bosta,
    this.bitis,
    this.kalan,
    this.toplam,
    this.donguSayaci = 0,
    this.bugunSayisi = 0,
    this.gun,
  });

  final Faz faz;
  final Durum durum;

  /// `calisiyor` iken bitiş anı (UTC).
  final DateTime? bitis;

  /// `duraklatildi` iken kalan süre.
  final Duration? kalan;

  /// Fazın toplam süresi (+1 dk ile büyür). İlerleme oranı için.
  final Duration? toplam;

  /// Bu döngüde tamamlanan çalışma sayısı (0–4).
  final int donguSayaci;

  /// [gun] tarihinde tamamlanan çalışma sayısı.
  final int bugunSayisi;

  /// [bugunSayisi]'nın ait olduğu yerel tarih, `YYYY-AA-GG`.
  final String? gun;

  PomodoroDurumu kopya({
    Faz? faz,
    Durum? durum,
    DateTime? Function()? bitis,
    Duration? Function()? kalan,
    Duration? Function()? toplam,
    int? donguSayaci,
    int? bugunSayisi,
    String? Function()? gun,
  }) => PomodoroDurumu(
    faz: faz ?? this.faz,
    durum: durum ?? this.durum,
    bitis: bitis != null ? bitis() : this.bitis,
    kalan: kalan != null ? kalan() : this.kalan,
    toplam: toplam != null ? toplam() : this.toplam,
    donguSayaci: donguSayaci ?? this.donguSayaci,
    bugunSayisi: bugunSayisi ?? this.bugunSayisi,
    gun: gun != null ? gun() : this.gun,
  );

  Map<String, Object?> toJson() => {
    'faz': faz.name,
    'durum': durum.name,
    'bitis': bitis?.toUtc().millisecondsSinceEpoch,
    'kalan': kalan?.inMilliseconds,
    'toplam': toplam?.inMilliseconds,
    'donguSayaci': donguSayaci,
    'bugunSayisi': bugunSayisi,
    'gun': gun,
  };

  /// Bozuk ya da eksik veri varsayılan duruma düşer, çökmez.
  factory PomodoroDurumu.fromJson(Object? json) {
    if (json is! Map) return const PomodoroDurumu();
    T? ad<T extends Enum>(List<T> degerler, Object? x) {
      for (final d in degerler) {
        if (d.name == x) return d;
      }
      return null;
    }

    int? sayi(String k) => json[k] is int ? json[k] as int : null;
    final faz = ad(Faz.values, json['faz']);
    final durum = ad(Durum.values, json['durum']);
    if (faz == null || durum == null) return const PomodoroDurumu();
    final bitisMs = sayi('bitis');
    final kalanMs = sayi('kalan');
    final toplamMs = sayi('toplam');
    // Tutarsız kayıt (örn. çalışıyor ama bitiş yok) güvenli tarafa düşer.
    if (durum == Durum.calisiyor && (bitisMs == null || toplamMs == null)) {
      return PomodoroDurumu(faz: faz);
    }
    if (durum == Durum.duraklatildi && (kalanMs == null || toplamMs == null)) {
      return PomodoroDurumu(faz: faz);
    }
    final gun = json['gun'];
    return PomodoroDurumu(
      faz: faz,
      durum: durum,
      bitis: bitisMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(bitisMs, isUtc: true),
      kalan: kalanMs == null ? null : Duration(milliseconds: kalanMs),
      toplam: toplamMs == null ? null : Duration(milliseconds: toplamMs),
      donguSayaci: (sayi('donguSayaci') ?? 0).clamp(0, 4),
      bugunSayisi: (sayi('bugunSayisi') ?? 0).clamp(0, 9999),
      gun: gun is String ? gun : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PomodoroDurumu &&
      other.faz == faz &&
      other.durum == durum &&
      other.bitis == bitis &&
      other.kalan == kalan &&
      other.toplam == toplam &&
      other.donguSayaci == donguSayaci &&
      other.bugunSayisi == bugunSayisi &&
      other.gun == gun;

  @override
  int get hashCode => Object.hash(
    faz,
    durum,
    bitis,
    kalan,
    toplam,
    donguSayaci,
    bugunSayisi,
    gun,
  );

  @override
  String toString() => 'PomodoroDurumu(${toJson()})';
}
