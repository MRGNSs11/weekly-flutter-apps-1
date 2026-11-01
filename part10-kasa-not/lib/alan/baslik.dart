/// Notun başlığı ayrı saklanmaz: içeriğin ilk dolu satırıdır.
///
/// Böylece kilitli notta başlık da şifreli içerikle birlikte gizlenir.
library;

const adsizNot = 'Adsız not';

final _baslikIsareti = RegExp(r'^#{1,6}\s*');

/// İlk dolu satır, baştaki `#` işaretleri atılmış hâlde.
String baslikCikar(String icerik) {
  for (final satir in icerik.split('\n')) {
    final temiz = satir.trim().replaceFirst(_baslikIsareti, '').trim();
    if (temiz.isNotEmpty) return temiz;
  }
  return adsizNot;
}

/// Başlıktan sonraki dolu satırlar, kart önizlemesi için.
List<String> ozetSatirlari(String icerik, {int enFazla = 4}) {
  final dolu = icerik
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s != '```')
      .toList();
  if (dolu.isEmpty) return const [];
  return dolu.skip(1).take(enFazla).toList();
}
