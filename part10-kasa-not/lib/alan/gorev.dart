/// Önizlemede N. görev kutusuna dokununca kaynaktaki `- [ ]` / `- [x]` değişir.
///
/// Kod bloğunun (```) içindeki `- [ ]` satırları görev sayılmaz; önizleme
/// onları kutu olarak çizmez, sayaç da onları atlamalı.
library;

final _gorevSatiri = RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\])');

/// Kod bloğu dışındaki görev satırlarının indeksleri, sırayla.
List<int> gorevSatirlari(String metin) {
  final sonuc = <int>[];
  var kodIcinde = false;
  final satirlar = metin.split('\n');
  for (var i = 0; i < satirlar.length; i++) {
    final s = satirlar[i];
    if (s.trimLeft().startsWith('```')) {
      kodIcinde = !kodIcinde;
      continue;
    }
    if (!kodIcinde && _gorevSatiri.hasMatch(s)) sonuc.add(i);
  }
  return sonuc;
}

/// [n] sıfırdan başlar. Aralık dışındaysa metin değişmeden döner.
String gorevDegistir(String metin, int n) {
  final indeksler = gorevSatirlari(metin);
  if (n < 0 || n >= indeksler.length) return metin;
  final satirlar = metin.split('\n');
  final i = indeksler[n];
  satirlar[i] = satirlar[i].replaceFirstMapped(
    _gorevSatiri,
    (m) => '${m[1]}${m[2] == ' ' ? 'x' : ' '}${m[3]}',
  );
  return satirlar.join('\n');
}
