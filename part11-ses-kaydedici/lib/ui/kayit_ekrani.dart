import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alan/boyut.dart';
import '../alan/sure.dart';
import '../uygulama/kayit_kontrol.dart';
import '../uygulama/liste_kontrol.dart';
import 'bulut.dart';
import 'kayitlar_sayfasi.dart';
import 'ses_cizgisi.dart';
import 'tema.dart';

/// Y6 kayıt ekranı: hazır · kayıt · duraklatıldı · izin yok; alttan
/// "Kayıtlar" sayfası. Ölçüler taslağın `.y6` CSS'inden (telefon içi 272 px).
class KayitEkrani extends StatefulWidget {
  const KayitEkrani({
    super.key,
    required this.kontrol,
    required this.liste,
    this.simdi,
  });

  final KayitKontrol kontrol;
  final ListeKontrol liste;
  final DateTime Function()? simdi;

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani>
    with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _yasam;
  late final _sayfa = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  KayitKontrol get k => widget.kontrol;
  double _sayfaBoyu = 1;

  @override
  void initState() {
    super.initState();
    // Ayarlardan izin verip dönünce ekran kendiliğinden hazıra geçer.
    _yasam = AppLifecycleListener(onResume: k.izniYokla);
  }

  @override
  void dispose() {
    _yasam.dispose();
    _sayfa.dispose();
    super.dispose();
  }

  bool get _kilitli => k.kayitta || k.asama == Asama.kaydediliyor;

  void _ac() {
    if (_kilitli) return;
    _sayfa.animateTo(1, curve: Curves.easeOutCubic);
    widget.liste.acildi();
  }

  void _kapat() => _sayfa.animateBack(0, curve: Curves.easeOutCubic);

  void _surukle(DragUpdateDetails d) {
    if (_kilitli) return;
    _sayfa.value -= (d.primaryDelta ?? 0) / _sayfaBoyu;
  }

  void _birak(DragEndDetails d) {
    if (_kilitli) return;
    final hiz = d.primaryVelocity ?? 0;
    if (hiz < -300 || (hiz.abs() <= 300 && _sayfa.value > .5)) {
      _ac();
    } else {
      _kapat();
    }
  }

  Future<void> _kaydet() async {
    await widget.liste.durdur();
    await k.kaydet();
  }

  @override
  Widget build(BuildContext context) {
    final ust = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, kutu) {
        // Taslak: sayfanın üstü telefonun 150 px aşağısında (durum çubuğu dahil).
        final sayfaUst = ust + 126;
        _sayfaBoyu = kutu.maxHeight - sayfaUst;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (cikti, _) {
            if (cikti) return;
            if (_sayfa.value > 0) {
              _kapat();
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge([k, _sayfa]),
              builder: (context, _) {
                final asama = k.asama;
                final v = _sayfa.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Bulut(hizli: asama == Asama.kayit),
                    if (asama == Asama.izinYok)
                      _IzinYok(kontrol: k)
                    else
                      Opacity(
                        opacity: 1 - v,
                        child: _Kayit(
                          kontrol: k,
                          liste: widget.liste,
                          kaydet: _kaydet,
                          ac: _ac,
                          surukle: _surukle,
                          birak: _birak,
                        ),
                      ),
                    if (v > 0) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _kapat,
                        onVerticalDragUpdate: _surukle,
                        onVerticalDragEnd: _birak,
                      ),
                      Positioned(
                        top: ust + 16,
                        left: 22,
                        right: 22,
                        child: Opacity(
                          opacity: v,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ses Kaydedici',
                                style: yazi(13, 500, opaklik: .9),
                              ),
                              Text(
                                sureYaz(k.sure),
                                style: yazi(13, 500, opaklik: .9),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: sayfaUst + (1 - v) * _sayfaBoyu,
                        left: 0,
                        right: 0,
                        height: _sayfaBoyu,
                        child: KayitlarSayfasi(
                          liste: widget.liste,
                          surukle: _surukle,
                          birak: _birak,
                          simdi: widget.simdi,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Kayit extends StatelessWidget {
  const _Kayit({
    required this.kontrol,
    required this.liste,
    required this.kaydet,
    required this.ac,
    required this.surukle,
    required this.birak,
  });

  final KayitKontrol kontrol;
  final ListeKontrol liste;
  final VoidCallback kaydet;
  final VoidCallback ac;
  final GestureDragUpdateCallback surukle;
  final GestureDragEndCallback birak;

  @override
  Widget build(BuildContext context) {
    final asama = kontrol.asama;
    final kayitta = kontrol.kayitta || asama == Asama.kaydediliyor;
    final duraklatildi = asama == Asama.duraklatildi;
    final alt = MediaQuery.paddingOf(context).bottom;

    final String altYazi;
    if (duraklatildi) {
      altYazi = 'DEVAM İÇİN';
    } else if (kayitta) {
      altYazi = boyutYaz(kontrol.boyut);
    } else {
      altYazi = 'DOKUN, KAYDET';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Baslik(asama: asama),
              const SizedBox(height: 70),
              SizedBox(
                height: 150,
                child: Opacity(
                  opacity: duraklatildi ? .45 : 1,
                  child: SesCizgisi(
                    degerler: asama == Asama.kayit
                        ? kontrol.ornekler
                        : const [],
                    canli: asama == Asama.kayit,
                  ),
                ),
              ),
              Text(
                sureYaz(kontrol.sure),
                textAlign: TextAlign.center,
                style: yazi(52, 300, aralik: -.02, satir: 1.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(altYazi, style: yazi(12, 500, aralik: .1, opaklik: .7)),
                  if (duraklatildi)
                    Icon(
                      Icons.play_arrow,
                      size: 13,
                      color: Renk.lilaBeyaz.withValues(alpha: .7),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 110 + alt,
          child: Center(
            child: _KayitDugmesi(
              kayitta: kayitta,
              onTap: kayitta ? kontrol.durdur : kaydet,
            ),
          ),
        ),
        if (kayitta) ...[
          Positioned(
            left: 24,
            bottom: 126 + alt,
            child: _KucukCam(
              etiket: duraklatildi ? 'Devam' : 'Duraklat',
              onTap: duraklatildi ? kontrol.devam : kontrol.duraklat,
              child: duraklatildi
                  ? const Icon(
                      Icons.play_arrow,
                      color: Renk.lilaBeyaz,
                      size: 26,
                    )
                  : const _IkiCubuk(),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 100 + alt,
            child: _DugmeEtiketi(duraklatildi ? 'DEVAM' : 'DURAKLAT'),
          ),
          Positioned(
            right: 24,
            bottom: 126 + alt,
            child: _KucukCam(
              etiket: 'İptal',
              onTap: kontrol.iptal,
              child: const Icon(Icons.close, color: Renk.lilaBeyaz, size: 20),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 100 + alt,
            child: const _DugmeEtiketi('İPTAL'),
          ),
        ],
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Tutamac(
            liste: liste,
            alt: alt,
            ac: ac,
            surukle: surukle,
            birak: birak,
          ),
        ),
      ],
    );
  }
}

class _Baslik extends StatelessWidget {
  const _Baslik({required this.asama});

  final Asama asama;

  @override
  Widget build(BuildContext context) {
    final stil = yazi(14, 300, aralik: .2, opaklik: .85);
    final (Widget? isaret, String metin) = switch (asama) {
      Asama.kayit || Asama.kaydediliyor => (
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Renk.lilaBeyaz.withValues(alpha: .85),
            shape: BoxShape.circle,
          ),
        ),
        'KAYDEDİLİYOR',
      ),
      Asama.duraklatildi => (
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: _IkiCubuk(en: 3, boy: 10, ara: 2, opaklik: .85),
        ),
        'DURAKLATILDI',
      ),
      _ => (null, 'SES KAYDEDİCİ'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          ?isaret,
          Text(metin, style: stil),
        ],
      ),
    );
  }
}

/// Buzlu cam yüzey (taslak: beyaz %18, bulanıklık 10, kenar beyaz %40).
class _Cam extends StatelessWidget {
  const _Cam({
    required this.boyut,
    required this.child,
    this.dolgu = .18,
    this.kenar = .4,
  });

  final double boyut;
  final Widget child;
  final double dolgu;
  final double kenar;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: boyut,
        height: boyut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: dolgu),
          border: Border.all(color: Colors.white.withValues(alpha: kenar)),
        ),
        child: child,
      ),
    ),
  );
}

class _KayitDugmesi extends StatelessWidget {
  const _KayitDugmesi({required this.kayitta, required this.onTap});

  final bool kayitta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: kayitta ? 'Durdur ve kaydet' : 'Kaydet',
    child: GestureDetector(
      onTap: onTap,
      child: _Cam(
        boyut: 84,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: kayitta ? 24 : 30,
          height: kayitta ? 24 : 30,
          decoration: BoxDecoration(
            color: Renk.turuncu,
            borderRadius: BorderRadius.circular(kayitta ? 6 : 15),
          ),
        ),
      ),
    ),
  );
}

class _KucukCam extends StatelessWidget {
  const _KucukCam({
    required this.etiket,
    required this.onTap,
    required this.child,
  });

  final String etiket;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etiket,
    child: GestureDetector(
      onTap: onTap,
      child: _Cam(boyut: 54, dolgu: .14, kenar: .35, child: child),
    ),
  );
}

class _DugmeEtiketi extends StatelessWidget {
  const _DugmeEtiketi(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 54,
    child: Text(
      metin,
      textAlign: TextAlign.center,
      style: yazi(10, 500, aralik: .06, opaklik: .7),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    ),
  );
}

/// Duraklat simgesi (font'ta ❚ yok).
class _IkiCubuk extends StatelessWidget {
  const _IkiCubuk({this.en = 5, this.boy = 16, this.ara = 3, this.opaklik = 1});

  final double en;
  final double boy;
  final double ara;
  final double opaklik;

  @override
  Widget build(BuildContext context) {
    final cubuk = Container(
      width: en,
      height: boy,
      color: Renk.lilaBeyaz.withValues(alpha: opaklik),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        cubuk,
        SizedBox(width: ara),
        cubuk,
      ],
    );
  }
}

/// Alttaki "Kayıtlar" şeridi (K5'te yukarı çekilince liste açılır).
class _Tutamac extends StatelessWidget {
  const _Tutamac({
    required this.liste,
    required this.alt,
    required this.ac,
    required this.surukle,
    required this.birak,
  });

  final ListeKontrol liste;
  final double alt;
  final VoidCallback ac;
  final GestureDragUpdateCallback surukle;
  final GestureDragEndCallback birak;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Kayıtları aç',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ac,
      onVerticalDragUpdate: surukle,
      onVerticalDragEnd: birak,
      child: _govde(),
    ),
  );

  Widget _govde() => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        height: 70 + alt,
        padding: EdgeInsets.fromLTRB(22, 10, 22, alt),
        color: Colors.white.withValues(alpha: .12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Kayıtlar', style: yazi(14, 500)),
                const Spacer(),
                ListenableBuilder(
                  listenable: liste,
                  builder: (context, _) => Text(
                    '${liste.kayitlar.length} ↑',
                    style: yazi(13, 400, opaklik: .7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Mikrofon izni reddedildi (B2.4-5).
class _IzinYok extends StatelessWidget {
  const _IzinYok({required this.kontrol});

  final KayitKontrol kontrol;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Baslik(asama: Asama.izinYok),
        const SizedBox(height: 50),
        SizedBox(height: 110, child: CustomPaint(painter: _KesikCizgi())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Text('Mikrofon izni gerekli', style: yazi(22, 500)),
              const SizedBox(height: 8),
              Text(
                'Ses kaydı için mikrofona erişmem lazım. Kayıtlar yalnız bu '
                'telefonda kalır, hiçbir yere gönderilmez.',
                textAlign: TextAlign.center,
                style: yazi(14, 300, opaklik: .85, satir: 1.5),
              ),
              const SizedBox(height: 22),
              Material(
                color: Renk.lilaBeyaz,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: kontrol.ayarlariAc,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                    child: Text(
                      'Ayarları aç',
                      style: yazi(15, 500, renk: Renk.bulutTaban),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: kontrol.tekrarSor,
                child: Text('Tekrar sor', style: yazi(13, 400, opaklik: .7)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _KesikCizgi extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()
      ..color = Renk.lilaBeyaz.withValues(alpha: .45)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), boya);
    }
  }

  @override
  bool shouldRepaint(_KesikCizgi eski) => false;
}
