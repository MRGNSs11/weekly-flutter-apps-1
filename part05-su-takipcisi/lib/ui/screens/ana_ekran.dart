import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../su/gunluk_durum.dart';
import '../../su/su_deposu.dart';
import '../su/su_boyaci.dart';
import '../su/su_fizigi.dart';
import '../theme/app_theme.dart';
import '../widgets/cam_kutu.dart';
import 'ayarlar_ekrani.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _fizik = SuFizigi();
  final _kare = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _onceki = Duration.zero;

  GunlukDurum? _durum;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tik)..start();
    _yukle(ilk: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fizik.hareketAzaltilmis = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _kare.dispose();
    super.dispose();
  }

  /// Uygulama öne gelince yeniden oku: bu arada widget'tan "+1" gelmiş
  /// ya da gece yarısı geçmiş olabilir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _yukle();
  }

  Future<void> _yukle({bool ilk = false}) async {
    final yeni = await SuDeposu.oku();
    if (!mounted) return;
    final eski = _durum;
    setState(() => _durum = yeni);
    _fizik.hedefOran = yeni.oran;
    // Widget'tan gelen bardaklar da görünür olsun: sayı arttıysa damla düşer.
    if (!ilk && eski != null && yeni.sayi > eski.sayi) _fizik.damlaBirak();
    if (yeni != eski && eski != null && yeni.sayi < eski.sayi) _fizik.sallan();
  }

  void _tik(Duration gecen) {
    final dt = ((gecen - _onceki).inMicroseconds / 1e6).clamp(0.0, .05);
    _onceki = gecen;
    _fizik.ilerle(dt);
    _kare.value++;
  }

  Future<void> _ekle() async {
    HapticFeedback.lightImpact();
    _fizik.damlaBirak();
    final yeni = await SuDeposu.degistir((d) => d.ekle());
    if (!mounted) return;
    setState(() => _durum = yeni);
    _fizik.hedefOran = yeni.oran;
  }

  Future<void> _geriAl() async {
    if ((_durum?.sayi ?? 0) == 0) return;
    _fizik.sallan();
    final yeni = await SuDeposu.degistir((d) => d.geriAl());
    if (!mounted) return;
    setState(() => _durum = yeni);
    _fizik.hedefOran = yeni.oran;
  }

  Future<void> _ayarlaraGit() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AyarlarEkrani()));
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final durum = _durum;
    final alt = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        // Samsung 3 tuşlu gezinmede koyu şerit çizmesin; su alta kadar insin.
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: BackdropGroup(
          child: LayoutBuilder(
            builder: (context, kutu) {
              _fizik
                ..genislik = kutu.maxWidth
                ..yukseklik = kutu.maxHeight
                // Düğmeler hep suyun içinde kalsın (beyaz yazı açık zeminde okunmaz).
                ..enAzPx = Olcu.dugmeYukseklik + Olcu.altBosluk + 12 + alt + 14;
              // Üst kısıt gevşek geliyor; Stack kendini başlık kadar küçültmesin.
              return SizedBox(
                width: kutu.maxWidth,
                height: kutu.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _fizik.dokun(
                          d.localPosition.dx,
                          d.localPosition.dy,
                        ),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: SuBoyaci(_fizik, kare: _kare),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                        child: Row(
                          children: [
                            Text('Bugün', style: sora(15, kalinlik: 600)),
                            const Spacer(),
                            TextButton(
                              onPressed: _ayarlaraGit,
                              style: TextButton.styleFrom(
                                foregroundColor: Renk.muted,
                              ),
                              child: Text(
                                'Ayarlar',
                                style: sora(12, renk: Renk.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: kutu.maxHeight * .19,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IgnorePointer(
                          child: durum == null
                              ? const SizedBox.shrink()
                              : _SayiKutusu(durum: durum),
                        ),
                      ),
                    ),
                    Positioned(
                      left: Olcu.kenar,
                      right: Olcu.kenar,
                      bottom: Olcu.altBosluk + alt,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _CamDugme(
                              yazi: '+1 bardak',
                              kalinlik: 700,
                              onTap: _ekle,
                            ),
                          ),
                          const SizedBox(width: Olcu.dugmeArasi),
                          Expanded(
                            child: _CamDugme(
                              yazi: 'Geri al',
                              kalinlik: 500,
                              onTap: (durum?.sayi ?? 0) == 0 ? null : _geriAl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SayiKutusu extends StatelessWidget {
  const _SayiKutusu({required this.durum});

  final GunlukDurum durum;

  @override
  Widget build(BuildContext context) {
    final ml = binlikAyir(durum.toplamMl);
    return Semantics(
      label:
          'Bugün ${durum.hedef} bardaktan ${durum.sayi} tanesi, $ml mililitre',
      excludeSemantics: true,
      child: CamKutu(
        icBosluk: const EdgeInsets.fromLTRB(26, 14, 26, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${durum.sayi}'),
                  TextSpan(
                    text: ' / ${durum.hedef}',
                    style: sora(46 * .45, kalinlik: 300, renk: Renk.muted),
                  ),
                ],
              ),
              style: sora(46, kalinlik: 300, harfAraligi: -46 * .03, satir: 1),
            ),
            const SizedBox(height: 6),
            Text('$ml ml içildi', style: sora(12, renk: Renk.muted)),
          ],
        ),
      ),
    );
  }
}

class _CamDugme extends StatelessWidget {
  const _CamDugme({
    required this.yazi,
    required this.kalinlik,
    required this.onTap,
  });

  final String yazi;
  final int kalinlik;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return Opacity(
      opacity: aktif ? 1 : .55,
      child: CamKutu(
        yaricap: 999,
        dolgu: const Color(0x33FFFFFF), // CSS: rgba(255,255,255,.2)
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: Olcu.dugmeYukseklik,
              child: Center(
                child: Text(
                  yazi,
                  style: sora(15, kalinlik: kalinlik, renk: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
