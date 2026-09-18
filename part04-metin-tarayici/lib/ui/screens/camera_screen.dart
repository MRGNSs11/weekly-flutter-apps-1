import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../camera/camera_permission.dart';
import '../theme/app_theme.dart';
import '../widgets/viewfinder.dart';
import 'permission_screen.dart';
import 'result_screen.dart';

/// Ana ekran: kamera önizlemesi + kadraj nişangahı + deklanşör.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _Durum { hazirlaniyor, izinYok, hazir, hata }

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const _izin = CameraPermission();

  _Durum _durum = _Durum.hazirlaniyor;
  CameraAccess _access = CameraAccess.denied;
  String _hata = '';

  List<CameraDescription> _kameralar = const [];
  CameraController? _kontrol;
  int _kameraSirasi = 0;
  bool _isikAcik = false;
  bool _cekiliyor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _baslat(ilkAcilis: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kontrol?.dispose();
    super.dispose();
  }

  /// Uygulama arka plana atılınca kamerayı bırakıyoruz: başka uygulama
  /// kamerayı kullanabilsin ve geri dönünce donuk kare kalmasın.
  ///
  /// Geri dönüşte izni yeniden okuyoruz — kullanıcı ayarlardan değiştirmiş
  /// olabilir. Kalıcı reddin tek çıkışı bu yol.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final kontrol = _kontrol;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _kontrol = null;
      kontrol?.dispose();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _baslat();
    }
  }

  Future<void> _baslat({bool ilkAcilis = false}) async {
    // İlk açılışta izni soruyoruz; sonraki dönüşlerde sadece durumu okuyoruz,
    // yoksa kullanıcı her geri geldiğinde sistem penceresiyle karşılaşır.
    final access = ilkAcilis ? await _izin.iste() : await _izin.kontrolEt();
    if (!mounted) return;

    if (access != CameraAccess.granted) {
      setState(() {
        _durum = _Durum.izinYok;
        _access = access;
      });
      return;
    }

    await _kamerayiAc();
  }

  Future<void> _kamerayiAc() async {
    try {
      if (_kameralar.isEmpty) _kameralar = await availableCameras();
      if (_kameralar.isEmpty) {
        _hataVer('Bu cihazda kullanılabilir bir kamera bulunamadı.');
        return;
      }

      final kontrol = CameraController(
        _kameralar[_kameraSirasi % _kameralar.length],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await kontrol.initialize();
      if (!mounted) {
        await kontrol.dispose();
        return;
      }

      setState(() {
        _kontrol = kontrol;
        _isikAcik = false;
        _durum = _Durum.hazir;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      if (error.code == 'CameraAccessDenied') {
        setState(() {
          _durum = _Durum.izinYok;
          _access = CameraAccess.denied;
        });
        return;
      }
      _hataVer('Kamera açılamadı: ${error.description ?? error.code}');
    }
  }

  void _hataVer(String mesaj) {
    setState(() {
      _durum = _Durum.hata;
      _hata = mesaj;
    });
  }

  Future<void> _isigiDegistir() async {
    final kontrol = _kontrol;
    if (kontrol == null) return;

    try {
      final acik = !_isikAcik;
      await kontrol.setFlashMode(acik ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _isikAcik = acik);
    } on CameraException {
      // Ön kameraların çoğunda ışık yok. Sessizce geçiyoruz; hata ekranı
      // açmak bu küçük iş için orantısız olurdu.
    }
  }

  Future<void> _kamerayiCevir() async {
    if (_kameralar.length < 2) return;
    final eski = _kontrol;
    setState(() {
      _kontrol = null;
      _durum = _Durum.hazirlaniyor;
      _kameraSirasi++;
    });
    await eski?.dispose();
    await _kamerayiAc();
  }

  Future<void> _cek() async {
    final kontrol = _kontrol;
    if (kontrol == null || _cekiliyor) return;

    setState(() => _cekiliyor = true);
    try {
      final kare = await kontrol.takePicture();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ResultScreen(karePath: kare.path),
        ),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      _hataVer('Fotoğraf çekilemedi: ${error.description ?? error.code}');
    } finally {
      if (mounted) setState(() => _cekiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_durum) {
      case _Durum.izinYok:
        return PermissionScreen(
          access: _access,
          onRequest: () => _baslat(ilkAcilis: true),
          onOpenSettings: _izin.ayarlariAc,
        );
      case _Durum.hata:
        return _HataEkrani(mesaj: _hata, onRetry: () => _baslat());
      case _Durum.hazirlaniyor:
      case _Durum.hazir:
        return _kameraEkrani();
    }
  }

  Widget _kameraEkrani() {
    final kontrol = _kontrol;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _UstCubuk(baslik: 'Yazıyı çerçeveye al'),
            Expanded(
              child: ColoredBox(
                color: AppColors.preview,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (kontrol != null && kontrol.value.isInitialized)
                      _Onizleme(kontrol: kontrol),
                    const Viewfinder(),
                  ],
                ),
              ),
            ),
            _AltCubuk(
              isikAcik: _isikAcik,
              cevrilebilir: _kameralar.length > 1,
              cekilebilir: kontrol != null && !_cekiliyor,
              onIsik: _isigiDegistir,
              onCevir: _kamerayiCevir,
              onCek: _cek,
            ),
          ],
        ),
      ),
    );
  }
}

/// Önizlemeyi kırparak dolduruyor.
///
/// Kamera 4:3 veriyor, ekran daha uzun. Siyah bantla ortalamak taslağın
/// havasını bozardı; kadrajı nişangah belirlediği için kırpmak sorun değil
/// (PLAN.md B2.4 / 2).
class _Onizleme extends StatelessWidget {
  const _Onizleme({required this.kontrol});

  final CameraController kontrol;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boyut) {
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: boyut.maxWidth,
                height: boyut.maxWidth / kontrol.value.aspectRatio,
                child: CameraPreview(kontrol),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UstCubuk extends StatelessWidget {
  const _UstCubuk({required this.baslik});

  final String baslik;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.kenar,
        vertical: 14,
      ),
      child: Row(
        children: [
          Text(baslik, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _AltCubuk extends StatelessWidget {
  const _AltCubuk({
    required this.isikAcik,
    required this.cevrilebilir,
    required this.cekilebilir,
    required this.onIsik,
    required this.onCevir,
    required this.onCek,
  });

  final bool isikAcik;
  final bool cevrilebilir;
  final bool cekilebilir;
  final VoidCallback onIsik;
  final VoidCallback onCevir;
  final VoidCallback onCek;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.kenar,
        14,
        AppSizes.kenar,
        18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _YanDugme(
                etiket: isikAcik ? 'Işık açık' : 'Işık',
                vurgulu: isikAcik,
                onTap: onIsik,
              ),
            ),
          ),
          _Deklansor(etkin: cekilebilir, onTap: onCek),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: cevrilebilir
                  ? _YanDugme(etiket: 'Çevir', onTap: onCevir)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _YanDugme extends StatelessWidget {
  const _YanDugme({
    required this.etiket,
    required this.onTap,
    this.vurgulu = false,
  });

  final String etiket;
  final VoidCallback onTap;
  final bool vurgulu;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: vurgulu ? AppColors.ink : AppColors.muted,
        backgroundColor: vurgulu ? AppColors.accent : null,
        textStyle: const TextStyle(fontSize: 13),
        shape: const StadiumBorder(),
      ),
      child: Text(etiket),
    );
  }
}

class _Deklansor extends StatelessWidget {
  const _Deklansor({required this.etkin, required this.onTap});

  final bool etkin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Fotoğraf çek',
      child: GestureDetector(
        onTap: etkin ? onTap : null,
        child: Opacity(
          opacity: etkin ? 1 : 0.4,
          child: Container(
            width: AppSizes.deklansor,
            height: AppSizes.deklansor,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg, width: 4),
              boxShadow: const [
                BoxShadow(color: AppColors.accent, spreadRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HataEkrani extends StatelessWidget {
  const _HataEkrani({required this.mesaj, required this.onRetry});

  final String mesaj;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 64, height: 14, color: AppColors.accent),
              const SizedBox(height: 28),
              Text(
                mesaj,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
