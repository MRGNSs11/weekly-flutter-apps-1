// K1 risk denemesi: kasa anahtarı parmak izine bağlı mı, pencere kasayı
// kapatıyor mu, son uygulamalarda önizleme gizleniyor mu? K5'te silinir.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

void main() => runApp(const DenemeUygulamasi());

class DenemeUygulamasi extends StatelessWidget {
  const DenemeUygulamasi({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kasa Not',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const DenemeEkrani(),
  );
}

const _anahtarAdi = 'kasa_anahtari';
const _gizlilik = MethodChannel('kasanot/gizlilik');

// Anahtar parmak izine bağlı; her okuma yeniden doğrulama ister,
// hata olursa veriyi sessizce silmez (paketin varsayılanı siler).
const _depo = FlutterSecureStorage(
  aOptions: AndroidOptions.biometric(
    enforceBiometrics: true,
    requireBiometricsPerOperation: true,
    resetOnError: false,
    biometricPromptTitle: 'Kasayı aç',
    biometricPromptSubtitle: 'Kilitli notları görmek için doğrula',
  ),
);

class DenemeEkrani extends StatefulWidget {
  const DenemeEkrani({super.key});

  @override
  State<DenemeEkrani> createState() => _DenemeEkraniState();
}

class _DenemeEkraniState extends State<DenemeEkrani> {
  final _auth = LocalAuthentication();
  final _kayit = <String>[];
  late final AppLifecycleListener _dinleyici;

  bool _acik = false;
  bool _dogrulaniyor = false;
  String _cihaz = '…';

  @override
  void initState() {
    super.initState();
    _dinleyici = AppLifecycleListener(onStateChange: _durumDegisti);
    _cihaziOku();
  }

  @override
  void dispose() {
    _dinleyici.dispose();
    super.dispose();
  }

  void _yaz(String satir) {
    final t = TimeOfDay.now();
    final s = DateTime.now().second.toString().padLeft(2, '0');
    setState(
      () => _kayit.insert(
        0,
        '${t.hour}:${t.minute.toString().padLeft(2, '0')}:$s  $satir',
      ),
    );
  }

  void _durumDegisti(AppLifecycleState durum) {
    _yaz('yaşam: ${durum.name}${_dogrulaniyor ? ' (doğrulama sürüyor)' : ''}');
    final arkada =
        durum == AppLifecycleState.hidden || durum == AppLifecycleState.paused;
    if (arkada && _acik && !_dogrulaniyor) _kapat('arka plan');
  }

  Future<void> _cihaziOku() async {
    try {
      final destek = await _auth.isDeviceSupported();
      final biyo = await _auth.canCheckBiometrics;
      final turler = await _auth.getAvailableBiometrics();
      setState(
        () => _cihaz =
            'kilit var: $destek · biyometrik: $biyo · türler: ${turler.map((e) => e.name).join(', ')}',
      );
    } catch (e) {
      setState(() => _cihaz = 'hata: $e');
    }
  }

  Future<void> _gizle(bool gizle) async {
    final oldu = await _gizlilik.invokeMethod<bool>('onizlemeyiGizle', gizle);
    _yaz('önizleme gizli=$gizle (uygulandı: $oldu)');
  }

  Future<void> _anahtarOlustur() async {
    final rastgele = Random.secure();
    final bayt = List<int>.generate(32, (_) => rastgele.nextInt(256));
    await _calis('anahtar oluştur', () async {
      await _depo.write(key: _anahtarAdi, value: base64Encode(bayt));
      _yaz('anahtar yazıldı');
    });
  }

  Future<void> _ac() async {
    await _calis('kasayı aç', () async {
      final deger = await _depo.read(key: _anahtarAdi);
      if (deger == null) {
        _yaz('anahtar yok — önce oluştur');
        return;
      }
      setState(() => _acik = true);
      _yaz('KASA AÇIK (anahtar ${base64Decode(deger).length} bayt)');
      await _gizle(true);
    });
  }

  Future<void> _kapat(String neden) async {
    setState(() => _acik = false);
    _yaz('KASA KAPANDI ($neden)');
    await _gizle(false);
  }

  Future<void> _sil() async {
    await _calis('anahtarı sil', () async {
      await _depo.delete(key: _anahtarAdi);
      _yaz('anahtar silindi');
    });
  }

  Future<void> _localAuth() async {
    await _calis('local_auth', () async {
      final ok = await _auth.authenticate(
        localizedReason: 'local_auth karşılaştırması',
      );
      _yaz('local_auth sonucu: $ok');
    });
  }

  Future<void> _calis(String ad, Future<void> Function() is_) async {
    setState(() => _dogrulaniyor = true);
    try {
      await is_();
    } on PlatformException catch (e) {
      _yaz('$ad HATA: ${e.code} — ${e.message}');
    } on LocalAuthException catch (e) {
      _yaz('$ad HATA: ${e.code.name} — ${e.description}');
    } catch (e) {
      _yaz('$ad HATA: $e');
    } finally {
      if (mounted) setState(() => _dogrulaniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final renk = _acik ? Colors.green : Colors.red;
    return Scaffold(
      appBar: AppBar(title: const Text('Kasa Not — risk denemesi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: renk.withValues(alpha: 0.15),
            child: Text(
              _acik
                  ? '🔓 KASA AÇIK\nGizli not: "Bu yazı son uygulamalarda görünmemeli."'
                  : '🔒 KASA KAPALI',
              style: TextStyle(fontSize: 20, color: renk.shade900),
            ),
          ),
          const SizedBox(height: 8),
          Text('Cihaz: $_cihaz'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _anahtarOlustur,
                child: const Text('1 · Anahtar oluştur'),
              ),
              FilledButton(onPressed: _ac, child: const Text('2 · Kasayı aç')),
              OutlinedButton(
                onPressed: _acik ? () => _kapat('buton') : null,
                child: const Text('Kasayı kapat'),
              ),
              OutlinedButton(
                onPressed: _localAuth,
                child: const Text('local_auth dene'),
              ),
              TextButton(onPressed: _sil, child: const Text('Anahtarı sil')),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Kayıt (en yeni üstte):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final s in _kayit)
            Text(
              s,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
        ],
      ),
    );
  }
}
