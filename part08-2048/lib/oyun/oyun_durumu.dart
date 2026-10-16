import 'kare.dart';

/// Oyunun bir anı. Değişmez: her hamle eskisini bozmadan yeni bir durum
/// üretir. Geri al bu yüzden ayrıca yazılmadı; geçmiş, durumların listesi.
class OyunDurumu {
  OyunDurumu({
    required List<Kare> kareler,
    this.skor = 0,
    this.hamle = 0,
    this.kazandi = false,
    this.bitti = false,
    required this.sonrakiId,
  }) : kareler = List.unmodifiable(kareler);

  final List<Kare> kareler;
  final int skor;
  final int hamle;

  /// Tahtada en az bir kez 2048 oluştu. Devam edilse de doğru kalır.
  final bool kazandi;

  /// Boş hücre yok ve yan yana eşit kare yok.
  final bool bitti;

  /// Yeni karelere verilecek kimlik. Durumun içinde durduğu için kurallar
  /// saf kalır: aynı durum + aynı rastgele sayı = aynı sonuç.
  final int sonrakiId;

  int get enBuyuk => kareler.fold(0, (m, k) => k.deger > m ? k.deger : m);

  Kare? hucredeki(int satir, int sutun) {
    for (final k in kareler) {
      if (k.satir == satir && k.sutun == sutun) return k;
    }
    return null;
  }

  OyunDurumu copyWith({bool? kazandi, bool? bitti}) => OyunDurumu(
    kareler: kareler,
    skor: skor,
    hamle: hamle,
    kazandi: kazandi ?? this.kazandi,
    bitti: bitti ?? this.bitti,
    sonrakiId: sonrakiId,
  );

  /// Testlerde ve örnek durumlarda tahtayı satır satır yazmak için.
  /// 0 = boş hücre.
  factory OyunDurumu.izgaradan(
    List<List<int>> izgara, {
    int skor = 0,
    int hamle = 0,
  }) {
    final kareler = <Kare>[];
    var id = 1;
    for (var r = 0; r < izgara.length; r++) {
      for (var c = 0; c < izgara[r].length; c++) {
        final v = izgara[r][c];
        if (v != 0) kareler.add(Kare(id: id++, satir: r, sutun: c, deger: v));
      }
    }
    return OyunDurumu(
      kareler: kareler,
      skor: skor,
      hamle: hamle,
      kazandi: kareler.any((k) => k.deger >= 2048),
      sonrakiId: id,
    );
  }

  /// Satır satır değerler (0 = boş). Testlerde karşılaştırma için.
  List<List<int>> get izgara {
    final g = List.generate(4, (_) => List.filled(4, 0));
    for (final k in kareler) {
      g[k.satir][k.sutun] = k.deger;
    }
    return g;
  }
}
