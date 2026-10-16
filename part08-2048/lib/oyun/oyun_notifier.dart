import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kurallar.dart' as kural;
import 'kurallar.dart' show HamleSonucu, Yon;
import 'oyun_durumu.dart';
import 'kayit_deposu.dart';

/// Ekranın üstüne açılan katman.
enum Katman { yok, kazandi, bitti }

/// Son değişikliğin türü. Ekran animasyonu buna göre seçer.
enum Olay { baslangic, hamle, geriAl, yeniOyun, devam }

/// Ekranın bilmesi gereken her şey. Durumlar değişmez olduğu için geçmiş,
/// eski durumların listesinden ibaret; geri al = sondakini geri koymak.
class Oyun {
  const Oyun({
    required this.durum,
    this.gecmis = const [],
    this.enIyi = 0,
    this.olay = Olay.baslangic,
    this.olaySayaci = 0,
    this.sonHamle,
    this.katman = Katman.yok,
  });

  final OyunDurumu durum;
  final List<OyunDurumu> gecmis;
  final int enIyi;
  final Olay olay;

  /// Her değişiklikte bir artar; ekran "yeni bir şey oldu mu?" diye buna bakar.
  final int olaySayaci;

  /// [olay] hamle ise o hamlenin ayrıntısı (kim kaydı, kim birleşti).
  final HamleSonucu? sonHamle;
  final Katman katman;

  bool get geriAlinabilir => gecmis.isNotEmpty;
}

/// Testte sabit tohum verilir, oyunda normal.
final rastgeleProvider = Provider<Random>((ref) => Random());

/// `main` içinde gerçek `SharedPreferences` ile verilir.
final kayitDeposuProvider = Provider<KayitDeposu>(
  (ref) => throw UnimplementedError('kayitDeposuProvider main içinde verilir'),
);

/// Testlerde ve entegrasyon testinde belirli bir tahtayla başlamak için.
final baslangicDurumuProvider = Provider<OyunDurumu?>((ref) => null);

final oyunProvider = NotifierProvider<OyunNotifier, Oyun>(OyunNotifier.new);

class OyunNotifier extends Notifier<Oyun> {
  /// Geri alınabilecek en fazla hamle.
  static const gecmisSiniri = 20;

  KayitDeposu get _depo => ref.read(kayitDeposuProvider);

  /// Açılış sırası: verilen başlangıç (test) → yarım kalan oyun → yeni oyun.
  @override
  Oyun build() {
    final depo = ref.watch(kayitDeposuProvider);
    final durum =
        ref.watch(baslangicDurumuProvider) ??
        depo.oyunOku() ??
        kural.yeniOyun(ref.watch(rastgeleProvider));
    return Oyun(
      durum: durum,
      enIyi: max(depo.enIyiOku(), durum.skor),
      katman: durum.bitti ? Katman.bitti : Katman.yok,
    );
  }

  /// Hamle olduysa true. Katman açıkken ya da hiçbir kare kıpırdamıyorsa false.
  bool kaydir(Yon yon) {
    if (state.katman != Katman.yok) return false;
    final sonuc = kural.kaydir(state.durum, yon, ref.read(rastgeleProvider));
    if (sonuc == null) return false;

    final gecmis = [...state.gecmis, state.durum];
    if (gecmis.length > gecmisSiniri) gecmis.removeAt(0);

    final ilkKazanma = !state.durum.kazandi && sonuc.durum.kazandi;
    final enIyi = max(state.enIyi, sonuc.durum.skor);
    if (enIyi > state.enIyi) _depo.enIyiYaz(enIyi);
    _yarimOyunuKaydet(sonuc.durum);

    state = Oyun(
      durum: sonuc.durum,
      gecmis: List.unmodifiable(gecmis),
      enIyi: enIyi,
      olay: Olay.hamle,
      olaySayaci: state.olaySayaci + 1,
      sonHamle: sonuc,
      katman: ilkKazanma
          ? Katman.kazandi
          : (sonuc.durum.bitti ? Katman.bitti : Katman.yok),
    );
    return true;
  }

  /// Bir önceki durumu olduğu gibi geri koyar. En iyi skor geri alınmaz.
  void geriAl() {
    if (state.gecmis.isEmpty) return;
    _yarimOyunuKaydet(state.gecmis.last);
    state = Oyun(
      durum: state.gecmis.last,
      gecmis: List.unmodifiable(
        state.gecmis.sublist(0, state.gecmis.length - 1),
      ),
      enIyi: state.enIyi,
      olay: Olay.geriAl,
      olaySayaci: state.olaySayaci + 1,
    );
  }

  void yeniOyun() {
    _depo.oyunSil();
    state = Oyun(
      durum: kural.yeniOyun(ref.read(rastgeleProvider)),
      enIyi: state.enIyi,
      olay: Olay.yeniOyun,
      olaySayaci: state.olaySayaci + 1,
    );
  }

  /// "2048!" katmanından sonra aynı tahtayla sürdürür.
  void devamEt() {
    if (state.katman != Katman.kazandi) return;
    state = Oyun(
      durum: state.durum,
      gecmis: state.gecmis,
      enIyi: state.enIyi,
      olay: Olay.devam,
      olaySayaci: state.olaySayaci + 1,
      katman: state.durum.bitti ? Katman.bitti : Katman.yok,
    );
  }

  /// Bitmiş oyun kaydedilmez: kayıt silinir, açılışta yeni oyun gelir.
  void _yarimOyunuKaydet(OyunDurumu d) =>
      d.bitti ? _depo.oyunSil() : _depo.oyunYaz(d);
}
