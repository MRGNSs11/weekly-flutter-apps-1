import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../alan/faz.dart';
import '../alan/pomodoro_durumu.dart';
import '../bildirim/bildirim_metinleri.dart';
import '../uygulama/pomodoro_kontrol.dart';
import 'ayarlar_ekrani.dart';
import 'parcalar/butonlar.dart';
import 'parcalar/dolgu_boyaci.dart';
import 'parcalar/izin_bandi.dart';
import 'parcalar/konfeti.dart';
import 'parcalar/noktalar.dart';
import 'tema.dart';

/// Çalışma boştayken dolgunun seviyesi (PLAN B2.4).
const bosSeviye = 0.03;

/// Dolgu seviyesi: çalışmada ilerleme kadar dolar, molada boşalır.
double hedefSeviye(PomodoroKontrol k, {required bool azalt}) {
  final dk = k.surukDk;
  if (dk != null) return dk / 90;
  final d = k.durum;
  DateTime? an;
  if (azalt) {
    // Animasyonları azalt: dolgu akmaz, saniye adımlı ilerler.
    final ms = k.simdi.millisecondsSinceEpoch;
    an = DateTime.fromMillisecondsSinceEpoch(ms - ms % 1000, isUtc: true);
  }
  final p = k.ilerlemeOrani(an);
  if (d.faz == Faz.calisma) return d.durum == Durum.bosta ? bosSeviye : p;
  return d.durum == Durum.bosta ? 1 : 1 - p;
}

class SayacEkrani extends StatefulWidget {
  const SayacEkrani({super.key, required this.kontrol});

  final PomodoroKontrol kontrol;

  @override
  State<SayacEkrani> createState() => _SayacEkraniState();
}

class _SayacEkraniState extends State<SayacEkrani>
    with TickerProviderStateMixin {
  PomodoroKontrol get k => widget.kontrol;

  late final Ticker _ticker = createTicker(_kareGeldi);
  Duration _onceki = Duration.zero;
  double _seviye = bosSeviye;
  double _dalga = 0;
  final _kare = ValueNotifier(const DolguKaresi(seviye: bosSeviye, dalga: 0));
  final _ustDolu = ValueNotifier(false);

  late final _nefesKontrol = AnimationController(
    vsync: this,
    duration: Sure.nefes,
  );
  late final Animation<double> _nefes = _nefesKontrol.drive(
    TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]),
  );

  late final _konfeti = KonfetiKontrol(this);
  final _noktalar = GlobalKey<DonguNoktalariState>();
  final _sahne = GlobalKey();
  final _artilar = <Key>[];
  int _artiNo = 0;
  StreamSubscription<KontrolOlayi>? _olay;
  int? _sonSurukDk;
  Size _boyut = Size.zero;
  double _ustBosluk = 0;
  bool _azalt = false;

  @override
  void initState() {
    super.initState();
    k.addListener(_degisti);
    _olay = k.olaylar.listen(_olayGeldi);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _azalt = MediaQuery.disableAnimationsOf(context);
    _ustBosluk = MediaQuery.paddingOf(context).top;
    _animasyonlariAyarla();
  }

  @override
  void dispose() {
    k.removeListener(_degisti);
    unawaited(_olay?.cancel());
    _ticker.dispose();
    _nefesKontrol.dispose();
    _konfeti.dispose();
    _kare.dispose();
    _ustDolu.dispose();
    super.dispose();
  }

  void _degisti() {
    _animasyonlariAyarla();
    setState(() {});
  }

  void _animasyonlariAyarla() {
    if (_azalt) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _onceki = Duration.zero;
      _ticker.start();
    }
    final nefesSin = !_azalt && k.durum.durum == Durum.duraklatildi;
    if (nefesSin && !_nefesKontrol.isAnimating) {
      _nefesKontrol.repeat();
    } else if (!nefesSin && _nefesKontrol.value != 0) {
      _nefesKontrol
        ..stop()
        ..value = 0;
    }
  }

  /// Her karede seviye ve kenar (PLAN B2.4). Fark %1'den büyükse 90 ms
  /// zaman sabitiyle yaklaşır.
  void _kareGeldi(Duration gecen) {
    final dt = _onceki == Duration.zero
        ? 16.0
        : math.min(64.0, (gecen - _onceki).inMicroseconds / 1000);
    _onceki = gecen;
    final hedef = hedefSeviye(k, azalt: false);
    final fark = hedef - _seviye;
    _seviye = fark.abs() < 0.01 ? hedef : _seviye + fark * math.min(1, dt / 90);
    _dalga += dt * kenarHiz;
    _kareyiYaz();
  }

  void _kareyiYaz() {
    _kare.value = DolguKaresi(seviye: _seviye, dalga: _dalga);
    // Dolgu durum çubuğuna girince ikonlar açığa döner (PLAN B2.5).
    if (_boyut.height > 0) {
      final y0 = _boyut.height * (1 - _seviye) - kenarGenlik;
      _ustDolu.value = y0 < _ustBosluk;
    }
  }

  void _olayGeldi(KontrolOlayi o) {
    switch (o) {
      case FazBitti():
        unawaited(HapticFeedback.mediumImpact());
      case Kutla(:final nokta, :final buyuk):
        _noktalar.currentState?.pop(nokta);
        if (_azalt) return;
        final kok = _sahne.currentContext?.findRenderObject();
        final kaynak = kok is RenderBox
            ? _noktalar.currentState?.merkez(nokta, kok)
            : null;
        _konfeti.patlat(
          kaynak: kaynak ?? _boyut.center(Offset.zero),
          buyuk: buyuk,
          ekran: _boyut,
        );
    }
  }

  Future<void> _anaButon() async {
    unawaited(HapticFeedback.lightImpact());
    switch (k.durum.durum) {
      case Durum.calisiyor:
        await k.eylemYap('duraklat');
      case Durum.duraklatildi:
        await k.eylemYap('devam');
      case Durum.bosta:
        await k.eylemYap('baslat');
        await k.izinAkisi(_aciklama);
    }
  }

  Future<bool> _aciklama(String baslik, String metin) async {
    if (!mounted) return false;
    final cevap = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(baslik),
        content: Text(metin),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('İzin ver'),
          ),
        ],
      ),
    );
    return cevap ?? false;
  }

  void _artiBir() {
    unawaited(k.eylemYap('dakika_ekle'));
    if (_azalt) return;
    setState(() => _artilar.add(ValueKey(_artiNo++)));
  }

  void _surukBasla(DragStartDetails d) {
    _sonSurukDk = null;
    _surukle(d.localPosition.dy);
  }

  void _surukle(double y) {
    if (_boyut.height == 0) return;
    final dk = k.surukle(1 - y / _boyut.height);
    if (dk == null) return;
    final once = _sonSurukDk;
    // Her 5 dakikada bir tık (PLAN B2.6).
    if (once != null && once ~/ 5 != dk ~/ 5) {
      unawaited(HapticFeedback.selectionClick());
    }
    _sonSurukDk = dk;
  }

  @override
  Widget build(BuildContext context) {
    final d = k.durum;
    final azalt = _azalt;
    if (azalt) {
      _seviye = hedefSeviye(k, azalt: true);
      _kareyiYaz();
    }
    final metin = dakikaSaniye(k.kalan);
    final altBosluk = MediaQuery.paddingOf(context).bottom;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: Renk.faz(d.faz)),
      duration: azalt ? Duration.zero : Sure.fazRengi,
      builder: (context, renk, _) {
        final aktif = renk ?? Renk.faz(d.faz);
        return ValueListenableBuilder<bool>(
          valueListenable: _ustDolu,
          builder: (_, ustDolu, child) => AnnotatedRegion(
            value: ustDolu
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                  ),
            child: child!,
          ),
          child: Scaffold(
            backgroundColor: Renk.zemin,
            body: LayoutBuilder(
              builder: (context, c) {
                _boyut = c.biggest;
                return Stack(
                  key: _sahne,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: _surukBasla,
                        onVerticalDragUpdate: (u) =>
                            _surukle(u.localPosition.dy),
                        onVerticalDragEnd: (_) => k.surukBitti(),
                        onVerticalDragCancel: k.surukBitti,
                        child: CustomPaint(
                          key: const ValueKey('dolgu'),
                          painter: DolguBoyaci(
                            kare: _kare,
                            renk: aktif,
                            metin: metin,
                            nefes: _nefes,
                          ),
                        ),
                      ),
                    ),
                    // Ekran okuyucu için rakam.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: c.maxHeight * rakamKonumu,
                      child: Semantics(
                        label: 'Kalan süre $metin',
                        child: const SizedBox(height: 86),
                      ),
                    ),
                    SafeArea(child: _onPlan(d, aktif)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6 + altBosluk,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: k.surukleyebilir ? 0.65 : 0,
                          duration: azalt
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                          child: Text(
                            '↕ Yukarı-aşağı sürükle: süre',
                            textAlign: TextAlign.center,
                            style: Yazi.inter(11, 500, renk: Colors.white)
                                .copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ),
                    for (final a in _artilar)
                      Positioned(
                        key: a,
                        left: 0,
                        right: 0,
                        top: c.maxHeight * 0.42,
                        child: _UcanArti(
                          renk: aktif,
                          bitti: () => setState(() => _artilar.remove(a)),
                        ),
                      ),
                    Positioned(
                      top: _ustBosluk + 4,
                      left: 12,
                      right: 12,
                      child: IzinBandi(bant: k.bant, onTap: k.bantEylemi),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: KonfetiBoyaci(_konfeti)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _onPlan(PomodoroDurumu d, Color aktif) {
    final bosta = d.durum == Durum.bosta;
    final oynuyor = d.durum == Durum.calisiyor;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Row(
            children: [
              YaziHapi(fazEtiketi(d), stil: Yazi.inter(14, 600)),
              const SizedBox(width: 8),
              YaziHapi('Bugün ${k.bugun}', stil: Yazi.inter(12, 500)),
              const Spacer(),
              HapDugme(
                etiket: 'Ayarlar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AyarlarEkrani(kontrol: k),
                  ),
                ),
                child: const Icon(Icons.settings_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              HapDugme(
                etiket: 'Atla',
                onTap: () {
                  unawaited(HapticFeedback.lightImpact());
                  unawaited(k.eylemYap('atla'));
                },
                child: const AtlaIkonu(),
              ),
            ],
          ),
        ),
        const Spacer(),
        DonguNoktalari(
          key: _noktalar,
          dolu: d.donguSayaci,
          aktif: d.faz == Faz.calisma && !bosta ? d.donguSayaci : null,
          renk: aktif,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KucukButon(
                ust: '■',
                alt: 'Bitir',
                etiket: 'Bitir',
                onTap: bosta ? null : () => k.eylemYap('bitir'),
              ),
              const SizedBox(width: 22),
              AnaButon(
                oynuyor: oynuyor,
                renk: aktif,
                etiket: oynuyor
                    ? 'Duraklat'
                    : d.durum == Durum.duraklatildi
                    ? 'Devam'
                    : 'Başlat',
                onTap: _anaButon,
              ),
              const SizedBox(width: 22),
              KucukButon(
                ust: '+1',
                alt: 'dk',
                etiket: '1 dakika ekle',
                onTap: bosta ? null : _artiBir,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "+1" yazısı 56 px yukarı uçup söner (PLAN B2.4: 600 ms).
class _UcanArti extends StatelessWidget {
  const _UcanArti({required this.renk, required this.bitti});

  final Color renk;
  final VoidCallback bitti;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Sure.artiBir,
      curve: Curves.easeOut,
      onEnd: bitti,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(0, -56 * t),
        child: Opacity(opacity: 1 - t, child: child),
      ),
      child: Text(
        '+1',
        textAlign: TextAlign.center,
        style: Yazi.inter(30, 700, renk: renk),
      ),
    ),
  );
}
