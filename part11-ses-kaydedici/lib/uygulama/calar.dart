import 'package:just_audio/just_audio.dart';

/// Hoparlör. Testte sahtesi kullanılır.
abstract interface class Calar {
  /// Dosyayı hazırlar; dosyanın süresini döndürür (bilinmiyorsa `null`).
  Future<Duration?> yukle(String yol);
  Future<void> oynat();
  Future<void> duraklat();
  Future<void> sar(Duration konum);
  Future<void> hiz(double h);
  Future<void> durdur();

  Stream<Duration> konum();
  Stream<bool> caliyor();

  /// Kayıt sonuna gelindi.
  Stream<void> bitti();

  Future<void> kapat();
}

class JustAudioCalar implements Calar {
  final _p = AudioPlayer();

  @override
  Future<Duration?> yukle(String yol) => _p.setFilePath(yol);

  @override
  Future<void> oynat() async {
    // `play()` çalma bitene kadar dönmez; beklemiyoruz.
    _p.play();
  }

  @override
  Future<void> duraklat() => _p.pause();

  @override
  Future<void> sar(Duration konum) => _p.seek(konum);

  @override
  Future<void> hiz(double h) => _p.setSpeed(h);

  @override
  Future<void> durdur() => _p.stop();

  @override
  Stream<Duration> konum() => _p.positionStream;

  @override
  Stream<bool> caliyor() => _p.playingStream;

  @override
  Stream<void> bitti() => _p.processingStateStream
      .where((d) => d == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> kapat() => _p.dispose();
}
