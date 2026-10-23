/// Saat dışarıdan verilir (PLAN B4.1): testte sahte saat kullanılır.
typedef Saat = DateTime Function();

DateTime gercekSaat() => DateTime.now();

/// Testler için elle ilerletilen saat.
class SahteSaat {
  SahteSaat(this.simdi);

  DateTime simdi;

  void ilerle(Duration d) => simdi = simdi.add(d);

  DateTime call() => simdi;
}
