/// Düzenleyicinin araç çubuğu ve Enter davranışı. Saf fonksiyonlar:
/// metin + imleç alır, yeni metin + imleç döndürür.
library;

typedef Duzen = ({String metin, int imlec});

final _listeOneki = RegExp(r'^(\s*)([-*+]\s+\[[ xX]\]\s|[-*+]\s|(\d+)\.\s)');

/// İmlecin bulunduğu satırın başı ve sonu.
(int, int) _satir(String metin, int imlec) {
  final bas = imlec == 0 ? 0 : metin.lastIndexOf('\n', imlec - 1) + 1;
  final son = metin.indexOf('\n', imlec);
  return (bas, son == -1 ? metin.length : son);
}

/// Kullanıcı satır sonunda Enter'a bastı (tek `\n` eklendi). Önceki satır
/// liste maddesiyse yeni satıra aynı önek gelir; madde boşsa liste biter.
/// Liste değilse `null` (dokunma).
Duzen? listeDevam(String eski, String yeni, int imlec) {
  if (yeni.length != eski.length + 1 || imlec < 1 || yeni[imlec - 1] != '\n') {
    return null;
  }
  final (bas, _) = _satir(yeni, imlec - 1);
  final onceki = yeni.substring(bas, imlec - 1);
  final m = _listeOneki.firstMatch(onceki);
  if (m == null) return null;

  if (onceki.substring(m.end).trim().isEmpty) {
    // Boş madde + Enter: öneki sil, yeni satır açma.
    final metin = yeni.substring(0, bas) + yeni.substring(imlec);
    return (metin: metin, imlec: bas);
  }
  final girinti = m[1]!;
  final sayi = m[3];
  final onek = sayi != null
      ? '${int.parse(sayi) + 1}. '
      : m[2]!.contains('[')
      ? '${m[2]!.trimLeft()[0]} [ ] '
      : m[2]!;
  final ek = '$girinti$onek';
  return (
    metin: yeni.substring(0, imlec) + ek + yeni.substring(imlec),
    imlec: imlec + ek.length,
  );
}

/// Satırın önekini aç/kapa: `- [ ] `, `- `, `# `. Satırda başka liste
/// öneki varsa onunla değiştirilir.
Duzen satirOneki(String metin, int imlec, String onek) {
  final (bas, son) = _satir(metin, imlec);
  final satir = metin.substring(bas, son);
  final baslik = RegExp(r'^#{1,6}\s');
  final mevcut = _listeOneki.firstMatch(satir) ?? baslik.firstMatch(satir);
  String yeniSatir;
  if (mevcut != null && mevcut[0]!.trimLeft() == onek) {
    yeniSatir = satir.substring(mevcut.end); // aynı önek: kaldır
  } else {
    yeniSatir = onek + (mevcut == null ? satir : satir.substring(mevcut.end));
  }
  final fark = yeniSatir.length - satir.length;
  return (
    metin: metin.substring(0, bas) + yeniSatir + metin.substring(son),
    imlec: (imlec + fark).clamp(bas, bas + yeniSatir.length),
  );
}

/// Seçili metni `**`, `*`, `` ` `` ile sarar; seçim yoksa çift işaret koyup
/// imleci ortaya alır.
Duzen sarmala(String metin, int bas, int son, String isaret) {
  final secili = metin.substring(bas, son);
  final yeni =
      metin.substring(0, bas) + isaret + secili + isaret + metin.substring(son);
  return (
    metin: yeni,
    imlec: secili.isEmpty ? bas + isaret.length : son + isaret.length * 2,
  );
}
