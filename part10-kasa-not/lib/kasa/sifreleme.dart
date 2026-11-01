import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Şifre çözülemedi: anahtar yanlış ya da veri bozuk.
class SifrelemeHatasi implements Exception {
  const SifrelemeHatasi(this.mesaj);
  final String mesaj;
  @override
  String toString() => 'SifrelemeHatasi: $mesaj';
}

/// AES-256-GCM. Diske giden bayt dizisi: `nonce(12) + şifreli metin + mac(16)`.
///
/// GCM şifrelerken bir doğrulama etiketi (mac) de üretir; yanlış anahtar ya da
/// değişmiş veri, çöp metin vermek yerine hata verir.
class Sifreleme {
  Sifreleme() : _aes = AesGcm.with256bits();

  final AesGcm _aes;

  static const anahtarUzunlugu = 32;

  Future<Uint8List> sifrele(String metin, List<int> anahtar) async {
    final kutu = await _aes.encrypt(
      utf8.encode(metin),
      secretKey: SecretKey(anahtar),
      nonce: _aes.newNonce(), // her kayıtta yeni
    );
    return kutu.concatenation();
  }

  Future<String> coz(Uint8List veri, List<int> anahtar) async {
    try {
      final kutu = SecretBox.fromConcatenation(
        veri,
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
      final duz = await _aes.decrypt(kutu, secretKey: SecretKey(anahtar));
      return utf8.decode(duz);
    } on SecretBoxAuthenticationError {
      throw const SifrelemeHatasi('anahtar yanlış ya da veri değişmiş');
    } catch (e) {
      throw SifrelemeHatasi('veri okunamadı: $e');
    }
  }
}
