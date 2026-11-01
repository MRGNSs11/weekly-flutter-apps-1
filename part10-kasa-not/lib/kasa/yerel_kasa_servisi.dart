import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'kasa_servisi.dart';
import 'sifreleme.dart';

/// Anahtar `flutter_secure_storage` ile Android Keystore'da, parmak izine bağlı.
///
/// Ayarlar K1 risk denemesinde telefonda doğrulandı:
/// - `requireBiometricsPerOperation`: yoksa paket anahtarı ilk açılıştan sonra
///   bellekte tutar, kasa her açılışta parmak izi istemez.
/// - `resetOnError: false`: paketin varsayılanı hata olunca tüm veriyi siler.
class YerelKasaServisi implements KasaServisi {
  static const _anahtarAdi = 'kasa_anahtari';

  final _auth = LocalAuthentication();
  final _depo = const FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      requireBiometricsPerOperation: true,
      resetOnError: false,
      biometricPromptTitle: 'Kasayı aç',
      biometricPromptSubtitle: 'Kilitli notları görmek için doğrula',
    ),
  );

  @override
  Future<bool> cihazUygun() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> anahtarVar() => _depo.containsKey(key: _anahtarAdi);

  @override
  Future<List<int>> anahtarOlustur() async {
    final r = Random.secure();
    final anahtar = List<int>.generate(
      Sifreleme.anahtarUzunlugu,
      (_) => r.nextInt(256),
    );
    await _cevir(
      () => _depo.write(key: _anahtarAdi, value: base64Encode(anahtar)),
    );
    return anahtar;
  }

  @override
  Future<List<int>> anahtariOku() async {
    final deger = await _cevir(() => _depo.read(key: _anahtarAdi));
    if (deger == null) throw const AnahtarGecersiz('anahtar bulunamadı');
    return base64Decode(deger);
  }

  @override
  Future<bool> dogrula() async {
    try {
      return await _auth.authenticate(localizedReason: 'Kasayı aç');
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        throw const KasaIptal();
      }
      rethrow;
    }
  }

  /// Paketin hata kodlarını uygulamanın diline çevirir.
  Future<T> _cevir<T>(Future<T> Function() is_) async {
    try {
      return await is_();
    } on PlatformException catch (e) {
      final metin = '${e.code} ${e.message}'.toLowerCase();
      // BiometricPrompt hata kodları: 5 iptal, 10 kullanıcı iptal, 13 "İptal" düğmesi.
      if (RegExp(r'error \[(5|10|13)\]').hasMatch(metin) ||
          metin.contains('cancel')) {
        throw const KasaIptal();
      }
      if (metin.contains('invalid') ||
          metin.contains('unwrap') ||
          metin.contains('permanently')) {
        throw AnahtarGecersiz('${e.code}: ${e.message}');
      }
      rethrow;
    }
  }
}

class KanalGizlilik implements Gizlilik {
  static const _kanal = MethodChannel('kasanot/gizlilik');

  @override
  Future<void> onizlemeyiGizle(bool gizle) async {
    try {
      await _kanal.invokeMethod<bool>('onizlemeyiGizle', gizle);
    } on MissingPluginException {
      // Testte kanal yok.
    }
  }
}
