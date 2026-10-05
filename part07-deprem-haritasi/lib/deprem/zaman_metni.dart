/// Tarih ve "ne kadar önce" metinleri.
///
/// `intl` paketi kullanılmıyor (dördüncü paket olurdu); Türkçe ay
/// kısaltmaları elle yazılı. Fonksiyonlar verilen saati olduğu gibi
/// biçimler — yerel saate çevirmek çağıranın işi.
abstract final class ZamanMetni {
  static const aylar = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  static String _iki(int n) => n.toString().padLeft(2, '0');

  /// "09:29"
  static String saat(DateTime z) => '${_iki(z.hour)}:${_iki(z.minute)}';

  /// "5 Eki 09:29"
  static String tarihSaat(DateTime z) =>
      '${z.day} ${aylar[z.month - 1]} ${saat(z)}';

  /// "az önce", "45 dk önce", "3 saat önce", "2 gün önce".
  /// 48 saate kadar saat yazılır; "1 gün önce" ile "dün"ü karıştırmamak için.
  static String once(DateTime z, DateTime simdi) {
    final dk = simdi.difference(z).inMinutes;
    if (dk < 1) return 'az önce';
    if (dk < 60) return '$dk dk önce';
    final sa = (dk / 60).round();
    if (sa < 48) return '$sa saat önce';
    return '${(sa / 24).round()} gün önce';
  }
}
