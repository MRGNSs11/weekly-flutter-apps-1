/// Bir ses kaydı. [dalga] kayıt sırasında toplanan seviyelerdir (0..1).
class Kayit {
  const Kayit({
    required this.id,
    required this.ad,
    required this.dosyaYolu,
    required this.sure,
    required this.boyutBayt,
    required this.olusturma,
    required this.dalga,
  });

  final int id;
  final String ad;
  final String dosyaYolu;
  final Duration sure;
  final int boyutBayt;
  final DateTime olusturma;
  final List<double> dalga;
}
