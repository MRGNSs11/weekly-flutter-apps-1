/// Bugünün su sayımı.
///
/// Saf mantık: depoya, widget'a ve arayüze bağlı değil, bu yüzden testle
/// doğrudan sınanabiliyor. Her değişiklik yeni bir nesne döndürür.
class GunlukDurum {
  const GunlukDurum({
    required this.sayi,
    required this.hedef,
    required this.bardakMl,
    required this.tarih,
  });

  /// İlk açılışta kullanılan durum.
  factory GunlukDurum.ilk(DateTime simdi) => GunlukDurum(
    sayi: 0,
    hedef: varsayilanHedef,
    bardakMl: varsayilanBardakMl,
    tarih: gunAnahtari(simdi),
  );

  static const varsayilanHedef = 8;
  static const varsayilanBardakMl = 250;
  static const enAzHedef = 1;
  static const enFazlaHedef = 20;
  static const bardakSecenekleri = [200, 250, 330, 500];

  /// Bugün içilen bardak sayısı.
  final int sayi;

  /// Günlük hedef (bardak).
  final int hedef;

  /// Bir bardağın mililitresi.
  final int bardakMl;

  /// Sayının ait olduğu gün, `yyyy-MM-dd`. Widget (Kotlin) de aynı biçimi okur.
  final String tarih;

  /// `yyyy-MM-dd`. Kotlin tarafındaki `LocalDate.toString()` ile birebir aynı.
  static String gunAnahtari(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// Kayıt başka bir güne aitse sayı sıfırlanır; hedef ve bardak korunur.
  GunlukDurum bugunIcin(DateTime simdi) {
    final bugun = gunAnahtari(simdi);
    return bugun == tarih ? this : _kopya(sayi: 0, tarih: bugun);
  }

  GunlukDurum ekle() => _kopya(sayi: sayi + 1);

  /// Sıfırın altına inmez.
  GunlukDurum geriAl() => sayi == 0 ? this : _kopya(sayi: sayi - 1);

  GunlukDurum hedefiDegistir(int yeni) =>
      _kopya(hedef: yeni.clamp(enAzHedef, enFazlaHedef));

  GunlukDurum bardagiDegistir(int ml) =>
      bardakSecenekleri.contains(ml) ? _kopya(bardakMl: ml) : this;

  /// Hedefe oran, 0 ile 1 arasında (hedef aşılınca 1'de kalır).
  double get oran => (sayi / hedef).clamp(0.0, 1.0);

  int get toplamMl => sayi * bardakMl;

  bool get hedefeUlasti => sayi >= hedef;

  GunlukDurum _kopya({int? sayi, int? hedef, int? bardakMl, String? tarih}) =>
      GunlukDurum(
        sayi: sayi ?? this.sayi,
        hedef: hedef ?? this.hedef,
        bardakMl: bardakMl ?? this.bardakMl,
        tarih: tarih ?? this.tarih,
      );

  @override
  bool operator ==(Object other) =>
      other is GunlukDurum &&
      other.sayi == sayi &&
      other.hedef == hedef &&
      other.bardakMl == bardakMl &&
      other.tarih == tarih;

  @override
  int get hashCode => Object.hash(sayi, hedef, bardakMl, tarih);
}

/// 1250 → "1.250". Türkçede binlik ayırıcı nokta; tek iş için `intl` eklenmedi.
String binlikAyir(int sayi) {
  final yazi = sayi.abs().toString();
  final parca = StringBuffer();
  for (var i = 0; i < yazi.length; i++) {
    if (i > 0 && (yazi.length - i) % 3 == 0) parca.write('.');
    parca.write(yazi[i]);
  }
  return sayi < 0 ? '-$parca' : parca.toString();
}
