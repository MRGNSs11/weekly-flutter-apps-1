import 'dart:typed_data';

/// Bir not. Açık notta [icerik] dolu, [sifreli] boştur; kilitli notta tersi.
///
/// İkisi aynı anda dolu olmaz: kilitli notun düz metni diske hiç yazılmaz.
class Not {
  const Not({
    required this.id,
    required this.icerik,
    required this.sifreli,
    required this.kilitli,
    required this.sabit,
    required this.olusturma,
    required this.guncelleme,
  });

  final int id;
  final String? icerik;
  final Uint8List? sifreli;
  final bool kilitli;
  final bool sabit;
  final DateTime olusturma;
  final DateTime guncelleme;
}
