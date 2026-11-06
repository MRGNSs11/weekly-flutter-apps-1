/// Kayıt adları, dosya adları ve listedeki tarih yazısı.
library;

const _aylar = [
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

/// Kullanıcı ad vermezse: `6 Kas 14:32`.
String varsayilanAd(DateTime t) => '${_gunAy(t)} ${_saat(t)}';

/// Ses dosyası: `kayit_20261106_143205.ogg` (saniyeyle, çakışmasın diye).
String dosyaAdi(DateTime t) =>
    'kayit_${t.year}${_iki(t.month)}${_iki(t.day)}'
    '_${_iki(t.hour)}${_iki(t.minute)}${_iki(t.second)}.ogg';

/// Listedeki alt satır: `Bugün 10:05`, `Dün 18:20`, `5 Kas 18:20`.
/// Geçen yıldan kalanlarda yıl da yazılır: `5 Kas 2025`.
String tarihEtiketi(DateTime t, DateTime simdi) {
  final gun = DateTime(t.year, t.month, t.day);
  final bugun = DateTime(simdi.year, simdi.month, simdi.day);
  final fark = bugun.difference(gun).inDays;
  if (fark == 0) return 'Bugün ${_saat(t)}';
  if (fark == 1) return 'Dün ${_saat(t)}';
  if (t.year != simdi.year) return '${_gunAy(t)} ${t.year}';
  return '${_gunAy(t)} ${_saat(t)}';
}

/// Yeniden adlandırma. Boşluklar kırpılır; boş kalırsa eski ad durur.
/// En çok [enUzun] karakter.
String temizAd(String girdi, String eskiAd, {int enUzun = 60}) {
  final ad = girdi.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (ad.isEmpty) return eskiAd;
  return ad.length > enUzun ? ad.substring(0, enUzun).trimRight() : ad;
}

String _gunAy(DateTime t) => '${t.day} ${_aylar[t.month - 1]}';
String _saat(DateTime t) => '${_iki(t.hour)}:${_iki(t.minute)}';
String _iki(int n) => n.toString().padLeft(2, '0');
