import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Mikrofon. Testte sahtesi kullanılır.
abstract interface class Kaydedici {
  /// [iste] true ise izin yoksa Android penceresi açılır.
  Future<bool> izinVar({bool iste = true});
  Future<void> baslat(String yol);
  Future<void> duraklat();
  Future<void> devam();

  /// Dosyanın yolu; kayıt yoksa `null`.
  Future<String?> durdur();

  /// Kaydı durdurur ve dosyayı siler.
  Future<void> iptal();

  /// Ses seviyesi (dBFS), 50 ms'de bir.
  Stream<double> seviyeler();

  /// Mikrofonun gerçek durumu. Telefon gelince kendiliğinden
  /// [KaydediciDurumu.duraklatildi] olur.
  Stream<KaydediciDurumu> durumlar();

  Future<void> kapat();
}

enum KaydediciDurumu { kayit, duraklatildi, durdu }

/// `record` paketi: Opus, 32 kbps, mono (B4).
class RecordKaydedici implements Kaydedici {
  final _r = AudioRecorder();

  @override
  Future<bool> izinVar({bool iste = true}) => _r.hasPermission(request: iste);

  @override
  Future<void> baslat(String yol) => _r.start(
    const RecordConfig(
      encoder: AudioEncoder.opus,
      bitRate: 32000,
      sampleRate: 48000,
      numChannels: 1,
    ),
    path: yol,
  );

  @override
  Future<void> duraklat() => _r.pause();

  @override
  Future<void> devam() => _r.resume();

  @override
  Future<String?> durdur() => _r.stop();

  @override
  Future<void> iptal() => _r.cancel();

  @override
  Stream<double> seviyeler() => _r
      .onAmplitudeChanged(const Duration(milliseconds: 50))
      .map((g) => g.current);

  @override
  Stream<KaydediciDurumu> durumlar() => _r.onStateChanged().map(
    (d) => switch (d) {
      RecordState.record => KaydediciDurumu.kayit,
      RecordState.pause => KaydediciDurumu.duraklatildi,
      RecordState.stop => KaydediciDurumu.durdu,
    },
  );

  @override
  Future<void> kapat() => _r.dispose();
}

/// Android tarafı: "Kaydediliyor" bildirimli servis ve ayarlar.
abstract interface class Sistem {
  Future<void> servisBaslat();
  Future<void> servisDurdur();
  Future<void> bildirimIzniIste();
  Future<void> ayarlariAc();
}

class KanalSistemi implements Sistem {
  static const _kanal = MethodChannel('seskaydedici/servis');

  @override
  Future<void> servisBaslat() => _kanal.invokeMethod('baslat');

  @override
  Future<void> servisDurdur() => _kanal.invokeMethod('durdur');

  @override
  Future<void> bildirimIzniIste() => _kanal.invokeMethod('bildirimIzniIste');

  @override
  Future<void> ayarlariAc() => _kanal.invokeMethod('ayarlariAc');
}
