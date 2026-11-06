import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../alan/ad.dart';
import '../alan/dalga.dart';
import '../alan/hiz.dart';
import '../alan/kayit.dart';
import '../alan/konum.dart';
import '../alan/sure.dart';
import '../uygulama/liste_kontrol.dart';
import 'tema.dart';

/// F8 — alttan çekilen lila beyaz sayfa (taslak Y6 üçüncü ekran + ek
/// durumlar 2-5). Başlık bölgesi aşağı sürüklenince sayfa iner.
class KayitlarSayfasi extends StatelessWidget {
  const KayitlarSayfasi({
    super.key,
    required this.liste,
    required this.surukle,
    required this.birak,
    this.simdi,
  });

  final ListeKontrol liste;
  final GestureDragUpdateCallback surukle;
  final GestureDragEndCallback birak;

  /// Tarih yazısı için (testte sabit).
  final DateTime Function()? simdi;

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Renk.lilaBeyaz,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: liste,
        builder: (context, _) {
          final s = liste.secili;
          final digerleri = [
            for (final k in liste.kayitlar)
              if (k.id != s?.id) k,
          ];
          final an = (simdi ?? DateTime.now)();
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: surukle,
                    onVerticalDragEnd: birak,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Renk.tutamacGri,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Kayıtlar',
                            style: yazi(18, 500, renk: Renk.bulutTaban),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: liste.kayitlar.isEmpty
                        ? const _Bos()
                        : ListView(
                            padding: EdgeInsets.fromLTRB(18, 0, 18, 80 + alt),
                            children: [
                              if (s != null)
                                OynaticiKart(
                                  liste: liste,
                                  kayit: s,
                                  tarih: tarihEtiketi(s.olusturma, an),
                                ),
                              for (final k in digerleri)
                                _Satir(
                                  kayit: k,
                                  tarih: tarihEtiketi(k.olusturma, an),
                                  onTap: () => liste.sec(k),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
              if (liste.silinen case final k?)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 16 + alt,
                  child: _GeriAlMesaji(ad: k.ad, onGeriAl: liste.geriAl),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.kayit, required this.tarih, required this.onTap});

  final Kayit kayit;
  final String tarih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Renk.sayfaCizgi)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kayit.ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: yazi(14, 400, renk: Renk.bulutTaban),
                ),
                Text(tarih, style: yazi(11.5, 400, renk: Renk.sayfaSoluk)),
              ],
            ),
          ),
          Text(
            sureYaz(kayit.sure),
            style: yazi(11.5, 400, renk: Renk.sayfaSoluk),
          ),
        ],
      ),
    ),
  );
}

/// Koyu mor oynatıcı kartı.
class OynaticiKart extends StatefulWidget {
  const OynaticiKart({
    super.key,
    required this.liste,
    required this.kayit,
    required this.tarih,
  });

  final ListeKontrol liste;
  final Kayit kayit;
  final String tarih;

  @override
  State<OynaticiKart> createState() => _OynaticiKartState();
}

class _OynaticiKartState extends State<OynaticiKart> {
  bool _duzenle = false;
  late final _ad = TextEditingController();
  final _odak = FocusNode();

  /// Sürüklerken çizgi parmağı izler; bırakınca sarılır.
  double? _surukleOran;

  ListeKontrol get l => widget.liste;

  @override
  void dispose() {
    _ad.dispose();
    _odak.dispose();
    super.dispose();
  }

  void _duzenlemeyiAc() {
    _ad.text = widget.kayit.ad;
    setState(() => _duzenle = true);
    _odak.requestFocus();
  }

  Future<void> _kaydet() async {
    setState(() => _duzenle = false);
    await l.adDegistir(_ad.text);
  }

  Duration _konumu(double x, double genislik) =>
      dokunulanKonum(x, genislik, l.toplam);

  @override
  Widget build(BuildContext context) {
    final oran = _surukleOran ?? ilerlemeOrani(l.konum, l.toplam);
    final gosterilen = _surukleOran == null
        ? l.konum
        : Duration(
            milliseconds: (l.toplam.inMilliseconds * _surukleOran!).round(),
          );
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Renk.kartMor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_duzenle)
            _AdAlani(denetim: _ad, odak: _odak, onBitti: _kaydet)
          else
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Yeniden adlandır',
                    value: widget.kayit.ad,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _duzenlemeyiAc,
                      child: Text(
                        widget.kayit.ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: yazi(14, 700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(widget.tarih, style: yazi(11.5, 400, opaklik: .75)),
              ],
            ),
          LayoutBuilder(
            builder: (context, kutu) {
              final g = kutu.maxWidth;
              return Semantics(
                label: 'Dalga, dokun ve sar',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => l.sar(_konumu(d.localPosition.dx, g)),
                  onHorizontalDragUpdate: (d) => setState(
                    () => _surukleOran = (d.localPosition.dx / g).clamp(0, 1),
                  ),
                  onHorizontalDragEnd: (_) {
                    final o = _surukleOran;
                    setState(() => _surukleOran = null);
                    if (o != null) l.sar(_konumu(o * g, g));
                  },
                  child: SizedBox(
                    height: 56,
                    child: CustomPaint(
                      painter: OynaticiCizgisi(
                        sikistir(widget.kayit.dalga, 60),
                        oran,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sureYaz(gosterilen), style: yazi(11, 400, opaklik: .85)),
              Text(sureYaz(l.toplam), style: yazi(11, 400, opaklik: .85)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Hap(
                metin: hizYaz(l.hiz),
                dolu: l.hiz != 1,
                etiket: 'Hız ${hizYaz(l.hiz)}',
                onTap: l.hizDegistir,
              ),
              Semantics(
                button: true,
                label: l.caliyor ? 'Duraklat' : 'Oynat',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: l.oynatDuraklat,
                  child: SizedBox(
                    width: 48,
                    height: 32,
                    child: Center(
                      child: l.caliyor
                          ? const _IkiCubuk()
                          : const Icon(
                              Icons.play_arrow,
                              color: Renk.lilaBeyaz,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ),
              _Hap(
                metin: 'Sil',
                etiket: 'Sil',
                onTap: () => l.sil(widget.kayit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdAlani extends StatelessWidget {
  const _AdAlani({
    required this.denetim,
    required this.odak,
    required this.onBitti,
  });

  final TextEditingController denetim;
  final FocusNode odak;
  final VoidCallback onBitti;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 4),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Renk.turuncu, width: 2)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: denetim,
            focusNode: odak,
            maxLength: 60,
            cursorColor: Renk.turuncu,
            style: yazi(15, 500),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onBitti(),
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Adı kaydet',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onBitti,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: Text('✓', style: yazi(13, 500)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Hap extends StatelessWidget {
  const _Hap({
    required this.metin,
    required this.etiket,
    required this.onTap,
    this.dolu = false,
  });

  final String metin;
  final String etiket;
  final VoidCallback onTap;
  final bool dolu;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etiket,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: dolu ? Renk.lilaBeyaz : Colors.white.withValues(alpha: .25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          metin,
          style: yazi(12, 500, renk: dolu ? Renk.bulutTaban : Renk.lilaBeyaz),
        ),
      ),
    ),
  );
}

class _IkiCubuk extends StatelessWidget {
  const _IkiCubuk();

  @override
  Widget build(BuildContext context) {
    final c = Container(width: 5, height: 16, color: Renk.lilaBeyaz);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [c, const SizedBox(width: 4), c],
    );
  }
}

/// Kaydın kendi dalgası; dinlenen kısım tam beyaz, kalanı soluk,
/// konumda turuncu çizgi + nokta (taslak `cizgiCiz`, faz 0).
class OynaticiCizgisi extends CustomPainter {
  OynaticiCizgisi(this.degerler, this.oran);

  final List<double> degerler;
  final double oran;

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.max(degerler.length, 2);
    final orta = size.height / 2;
    Offset nokta(int i) {
      final t = i / (n - 1);
      final v = i < degerler.length ? degerler[i] : 0.0;
      return Offset(
        t * size.width,
        orta +
            v * size.height * .42 * math.sin(t * math.pi) * math.sin(i * 1.7),
      );
    }

    final yol = Path();
    var onceki = nokta(0);
    yol.moveTo(onceki.dx, onceki.dy);
    for (var i = 1; i < n; i++) {
      final p = nokta(i);
      yol.quadraticBezierTo(
        onceki.dx,
        onceki.dy,
        (onceki.dx + p.dx) / 2,
        (onceki.dy + p.dy) / 2,
      );
      onceki = p;
    }

    final kx = oran * size.width;
    canvas
      ..drawPath(
        yol,
        Paint()
          ..color = Renk.lilaBeyaz.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, kx, size.height))
      ..drawPath(
        yol,
        Paint()
          ..color = Renk.lilaBeyaz
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      )
      ..restore()
      ..drawLine(
        Offset(kx, 4),
        Offset(kx, size.height - 4),
        Paint()
          ..color = Renk.turuncu
          ..strokeWidth = 1.5,
      )
      ..drawCircle(Offset(kx, orta), 5, Paint()..color = Renk.turuncu);
  }

  @override
  bool shouldRepaint(OynaticiCizgisi eski) =>
      eski.oran != oran || eski.degerler != degerler;
}

class _GeriAlMesaji extends StatelessWidget {
  const _GeriAlMesaji({required this.ad, required this.onGeriAl});

  final String ad;
  final VoidCallback onGeriAl;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Renk.kartMor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Renk.bulutTaban.withValues(alpha: .6),
          offset: const Offset(0, 10),
          blurRadius: 24,
          spreadRadius: -10,
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '"$ad" silindi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: yazi(13, 500),
          ),
        ),
        Semantics(
          button: true,
          label: 'Geri al',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onGeriAl,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('Geri al', style: yazi(13, 600, renk: Renk.turuncu)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Bos extends StatelessWidget {
  const _Bos();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
    child: Column(
      children: [
        SizedBox(
          width: 180,
          height: 50,
          child: CustomPaint(painter: _BosCizgi()),
        ),
        const SizedBox(height: 14),
        Text('Henüz kayıt yok', style: yazi(17, 500, renk: Renk.bulutTaban)),
        const SizedBox(height: 4),
        Text(
          'Aşağı kaydır, turuncu düğmeye dokun.\nİlk kaydın burada görünür.',
          textAlign: TextAlign.center,
          style: yazi(13, 400, renk: Renk.sayfaSoluk, satir: 1.5),
        ),
      ],
    ),
  );
}

class _BosCizgi extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas
      ..drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Renk.tutamacGri
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(Offset(size.width / 2, y), 5, Paint()..color = Renk.turuncu);
  }

  @override
  bool shouldRepaint(_BosCizgi eski) => false;
}
