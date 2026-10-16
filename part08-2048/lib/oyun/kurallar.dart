import 'dart:math';

import 'kare.dart';
import 'oyun_durumu.dart';

/// 2048'in kuralları. Flutter'a dokunmaz; telefonsuz, saniyeler içinde test
/// edilir. Rastgelelik dışarıdan verilir: testte sabit tohum, oyunda normal.

const int tahtaBoyu = 4;
const int hedefDeger = 2048;

enum Yon { sol, sag, yukari, asagi }

/// Bir hamlenin sonucu: yeni durum + ekranın animasyon için bilmesi gerekenler.
class HamleSonucu {
  const HamleSonucu({
    required this.durum,
    required this.yon,
    required this.olenler,
    required this.birlesenler,
    required this.yeniKareId,
  });

  final OyunDurumu durum;
  final Yon yon;

  /// Birleşip yok olan kareler, kayacakları son konumlarıyla.
  final List<Kare> olenler;

  /// Birleşmede kalan (değeri ikiye katlanan) karelerin kimlikleri.
  final Set<int> birlesenler;

  /// Hamleden sonra eklenen yeni kare. Tahta doluysa null.
  final int? yeniKareId;
}

/// Boş tahtaya iki kare.
OyunDurumu yeniOyun(Random r) {
  final ilk = kareEkle(const [], r, 1)!;
  final ikinci = kareEkle([ilk], r, 2)!;
  return OyunDurumu(kareler: [ilk, ikinci], sonrakiId: 3);
}

/// Rastgele bir boş hücreye %90 ihtimalle 2, %10 ihtimalle 4 koyar.
/// Boş hücre yoksa null.
Kare? kareEkle(List<Kare> kareler, Random r, int id) {
  final dolu = {for (final k in kareler) k.satir * tahtaBoyu + k.sutun};
  final bos = [
    for (var i = 0; i < tahtaBoyu * tahtaBoyu; i++)
      if (!dolu.contains(i)) i,
  ];
  if (bos.isEmpty) return null;
  final i = bos[r.nextInt(bos.length)];
  return Kare(
    id: id,
    satir: i ~/ tahtaBoyu,
    sutun: i % tahtaBoyu,
    deger: r.nextDouble() < 0.9 ? 2 : 4,
  );
}

/// Boş hücre ya da yan yana (yatay/dikey) eşit iki kare varsa hamle vardır.
bool hamleVar(List<Kare> kareler) {
  if (kareler.length < tahtaBoyu * tahtaBoyu) return true;
  final g = List.generate(tahtaBoyu, (_) => List.filled(tahtaBoyu, 0));
  for (final k in kareler) {
    g[k.satir][k.sutun] = k.deger;
  }
  for (var r = 0; r < tahtaBoyu; r++) {
    for (var c = 0; c < tahtaBoyu; c++) {
      if (c + 1 < tahtaBoyu && g[r][c] == g[r][c + 1]) return true;
      if (r + 1 < tahtaBoyu && g[r][c] == g[r + 1][c]) return true;
    }
  }
  return false;
}

/// Bir hattın [j]. hücresi; j = 0 kareler hangi kenara kayıyorsa o kenar.
(int, int) _hucre(Yon yon, int hat, int j) => switch (yon) {
  Yon.sol => (hat, j),
  Yon.sag => (hat, tahtaBoyu - 1 - j),
  Yon.yukari => (j, hat),
  Yon.asagi => (tahtaBoyu - 1 - j, hat),
};

/// Kareleri [yon]e kaydırır. Hiçbir kare yer değiştirmiyorsa null döner:
/// hamle sayılmaz, yeni kare de çıkmaz.
HamleSonucu? kaydir(OyunDurumu durum, Yon yon, Random r) {
  final izgara = List.generate(
    tahtaBoyu,
    (_) => List<Kare?>.filled(tahtaBoyu, null),
  );
  for (final k in durum.kareler) {
    izgara[k.satir][k.sutun] = k;
  }

  final cikan = <Kare>[];
  final olenler = <Kare>[];
  final birlesenler = <int>{};
  var skor = durum.skor;
  var hareket = false;

  for (var hat = 0; hat < tahtaBoyu; hat++) {
    final hucreler = [for (var j = 0; j < tahtaBoyu; j++) _hucre(yon, hat, j)];
    final dizi = [for (final (s, c) in hucreler) ?izgara[s][c]];
    var hedef = 0;
    for (var i = 0; i < dizi.length; i++) {
      final k = dizi[i];
      final (hs, hc) = hucreler[hedef];
      // Birleşen kare bir sonrakiyle tekrar birleşemez: i iki adım atlar.
      if (i + 1 < dizi.length && dizi[i + 1].deger == k.deger) {
        final yeniDeger = k.deger * 2;
        cikan.add(k.tasi(hs, hc, deger: yeniDeger));
        birlesenler.add(k.id);
        olenler.add(dizi[i + 1].tasi(hs, hc));
        skor += yeniDeger;
        hareket = true;
        i++;
      } else {
        cikan.add(k.tasi(hs, hc));
        if (k.satir != hs || k.sutun != hc) hareket = true;
      }
      hedef++;
    }
  }

  if (!hareket) return null;

  final yeni = kareEkle(cikan, r, durum.sonrakiId);
  final kareler = [...cikan, ?yeni];
  return HamleSonucu(
    durum: OyunDurumu(
      kareler: kareler,
      skor: skor,
      hamle: durum.hamle + 1,
      kazandi: durum.kazandi || kareler.any((k) => k.deger >= hedefDeger),
      bitti: !hamleVar(kareler),
      sonrakiId: durum.sonrakiId + (yeni == null ? 0 : 1),
    ),
    yon: yon,
    olenler: olenler,
    birlesenler: birlesenler,
    yeniKareId: yeni?.id,
  );
}
