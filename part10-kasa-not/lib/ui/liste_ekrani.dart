import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alan/not.dart';
import '../uygulama/kasa_kontrol.dart';
import '../uygulama/notlar_kontrol.dart';
import '../uygulama/rehber_kontrol.dart';
import '../uygulama/tema_kontrol.dart';
import 'parcalar/kasa_seridi.dart';
import 'parcalar/not_karti.dart';
import 'parcalar/tema_dugmesi.dart';
import 'tema.dart';

/// Y3 Buğulu Cam: kilitli notlar ızgarada yerinde, camın arkasında.
class ListeEkrani extends StatelessWidget {
  const ListeEkrani({
    super.key,
    required this.notlar,
    required this.kasa,
    required this.tema,
    required this.rehber,
    required this.notuAc,
  });

  final NotlarKontrol notlar;
  final KasaKontrol kasa;
  final TemaKontrol tema;
  final RehberKontrol rehber;

  /// Düzenleyiciyi açar; `null` yeni not demek.
  final void Function(BuildContext, Not?) notuAc;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: r.zemin,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: Listenable.merge([notlar, kasa, tema]),
            builder: (context, _) => Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Ust(notlar: notlar, tema: tema, rehber: rehber),
                    ),
                    if (notlar.yuklendi && notlar.gorunen.isEmpty)
                      SliverToBoxAdapter(
                        child: _Bos(arama: notlar.sorgu.isNotEmpty),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 150),
                      sliver: SliverToBoxAdapter(child: _Izgara(ekran: this)),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 96 + MediaQuery.paddingOf(context).bottom,
                  child: FloatingActionButton(
                    key: rehber.hedefler.yeniNot,
                    onPressed: () => notuAc(context, null),
                    backgroundColor: r.vurgu,
                    foregroundColor: Colors.white,
                    tooltip: 'Yeni not',
                    child: const Icon(Icons.add_rounded, size: 30),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 14 + MediaQuery.paddingOf(context).bottom,
                  child: KasaSeridi(
                    key: rehber.hedefler.kasaSeridi,
                    kasa: kasa,
                    kilitliSayisi: notlar.kilitliSayisi,
                    onAc: () {
                      HapticFeedback.selectionClick();
                      kasa.ac(notlar.tumu);
                    },
                    onKapat: kasa.kapat,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, Not not) async {
    final r = Renkler.of(context);
    final kasaVar =
        kasa.durum != KasaDurumu.kullanilamaz && kasa.durum != KasaDurumu.bozuk;
    final secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!not.kilitli)
              ListTile(
                enabled: kasaVar,
                leading: Icon(Icons.lock_rounded, color: r.vurgu),
                title: const Text('Kilitle'),
                subtitle: kasaVar
                    ? null
                    : const Text('Bu telefonda kasa kullanılamıyor'),
                onTap: () => Navigator.pop(c, 'kilitle'),
              ),
            if (not.kilitli && kasa.acik)
              ListTile(
                leading: Icon(Icons.lock_open_rounded, color: r.vurgu),
                title: const Text('Kasadan çıkar'),
                onTap: () => Navigator.pop(c, 'ac'),
              ),
            if (!not.kilitli || kasa.acik)
              ListTile(
                leading: Icon(
                  not.sabit ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                ),
                title: Text(not.sabit ? 'Sabitlemeyi kaldır' : 'Sabitle'),
                onTap: () => Navigator.pop(c, 'sabit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Sil'),
              onTap: () => Navigator.pop(c, 'sil'),
            ),
          ],
        ),
      ),
    );
    switch (secim) {
      case 'kilitle':
        await kasa.kilitle(not, notlar.tumu);
      case 'ac':
        await kasa.kilidiAc(not.id);
      case 'sabit':
        await notlar.depo.sabitle(not.id, !not.sabit);
      case 'sil':
        await notlar.depo.sil(not.id);
    }
  }
}

class _Ust extends StatelessWidget {
  const _Ust({required this.notlar, required this.tema, required this.rehber});
  final NotlarKontrol notlar;
  final TemaKontrol tema;
  final RehberKontrol rehber;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notlar',
                  style: yazi(28, kalinlik: FontWeight.w700, renk: r.metin),
                ),
              ),
              IconButton(
                key: rehber.hedefler.soru,
                tooltip: 'Rehber',
                onPressed: rehber.baslat,
                icon: Icon(Icons.help_outline_rounded, color: r.metin),
              ),
              TemaDugmesi(tema: tema),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (s) => notlar.sorgu = s,
            style: yazi(14, renk: r.metin),
            decoration: InputDecoration(
              hintText: 'Notlarda ara',
              hintStyle: yazi(13, renk: r.soluk),
              prefixIcon: Icon(Icons.search_rounded, color: r.soluk, size: 20),
              filled: true,
              fillColor: r.kart,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: r.cizgi),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: r.cizgi),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// İki sütunlu bento ızgara: her not kısa olan sütuna eklenir.
class _Izgara extends StatelessWidget {
  const _Izgara({required this.ekran});
  final ListeEkrani ekran;

  @override
  Widget build(BuildContext context) {
    final notlar = ekran.notlar.gorunen;
    final sol = <Widget>[], sag = <Widget>[];
    var solH = 0.0, sagH = 0.0;
    // Rehberin "basılı tut" adımı ilk açık notu gösterir.
    final ilkAcik = notlar.where((n) => !n.kilitli).firstOrNull?.id;
    for (final n in notlar) {
      final metin = n.kilitli ? ekran.kasa.cozulmus(n.id) : n.icerik;
      final kart = Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: KeyedSubtree(
          key: n.id == ilkAcik ? ekran.rehber.hedefler.ilkKart : null,
          child: NotKarti(
            key: ValueKey(n.id),
            metin: metin,
            kilitli: n.kilitli,
            sabit: n.sabit,
            onTap: () => ekran.notuAc(context, n),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              ekran._menu(context, n);
            },
          ),
        ),
      );
      // Yükseklik tahmini: satır sayısı (kilitli kapalı kart sabit kısa).
      final h = metin == null
          ? 3.0
          : 2 + '\n'.allMatches(metin).length.clamp(0, 6).toDouble();
      if (solH <= sagH) {
        sol.add(kart);
        solH += h;
      } else {
        sag.add(kart);
        sagH += h;
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: sol)),
        const SizedBox(width: 8),
        Expanded(child: Column(children: sag)),
      ],
    );
  }
}

class _Bos extends StatelessWidget {
  const _Bos({required this.arama});
  final bool arama;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Text(
        arama ? 'Eşleşen not yok.' : 'Henüz not yok.\n+ ile ilk notunu yaz.',
        textAlign: TextAlign.center,
        style: yazi(14, renk: r.soluk),
      ),
    );
  }
}
