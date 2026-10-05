/// Tek bir deprem kaydı (AFAD).
///
/// [zaman] her zaman UTC tutulur; ekrana yazarken yerel saate çevrilir.
class Deprem {
  const Deprem({
    required this.enlem,
    required this.boylam,
    required this.buyukluk,
    required this.derinlikKm,
    required this.zaman,
    required this.yer,
  });

  final double enlem;
  final double boylam;
  final double buyukluk;
  final double derinlikKm;
  final DateTime zaman;
  final String yer;

  int get ms => zaman.millisecondsSinceEpoch;

  /// AFAD'ın JSON kaydından okur. Bozuk kayıtta `null` döner (liste atlar).
  ///
  /// AFAD'ın üç tuhaflığı burada karşılanıyor:
  /// - sayılar metin olarak geliyor (`"magnitude": "2.7"`);
  /// - tarih UTC ama sonunda `Z` yok (`"2026-10-04T11:43:23"`), Dart onu
  ///   yerel saat sanardı;
  /// - `country` bazen boş geliyor (deniz depremleri) — kullanılmıyor.
  static Deprem? fromAfad(Map<String, dynamic> m) {
    final enlem = _sayi(m['latitude']);
    final boylam = _sayi(m['longitude']);
    final buyukluk = _sayi(m['magnitude']);
    final derinlik = _sayi(m['depth']);
    final tarih = m['date'];
    if (enlem == null || boylam == null || buyukluk == null) return null;
    if (enlem.abs() > 90 || boylam.abs() > 180) return null;
    if (tarih is! String) return null;
    final zaman = DateTime.tryParse(tarih.endsWith('Z') ? tarih : '${tarih}Z');
    if (zaman == null) return null;
    final yer = m['location'];
    return Deprem(
      enlem: enlem,
      boylam: boylam,
      buyukluk: buyukluk,
      derinlikKm: derinlik ?? 0,
      zaman: zaman,
      yer: yer is String && yer.trim().isNotEmpty
          ? yer.trim()
          : 'Bilinmeyen yer',
    );
  }

  static double? _sayi(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s.trim()),
    _ => null,
  };

  /// "Ege Denizi - [13.24 km] Dikili (İzmir)" → "Ege Denizi".
  /// Denizdeki depremlerde AFAD en yakın kıyıyı köşeli parantezle ekliyor;
  /// dar alanda yalnız ilk kısım okunuyor.
  String get kisaYer {
    final i = yer.indexOf('[');
    if (i <= 0) return yer;
    return yer.substring(0, i).replaceFirst(RegExp(r'\s*-\s*$'), '').trim();
  }
}
