/// Tahtadaki tek kare.
///
/// [id] kalıcıdır: kare kayarken ve birleşirken aynı kalır. Ekran, hangi
/// karenin nereden nereye gittiğini ve hangisinin birleştiğini bundan bilir.
class Kare {
  const Kare({
    required this.id,
    required this.satir,
    required this.sutun,
    required this.deger,
  });

  final int id;
  final int satir;
  final int sutun;
  final int deger;

  Kare tasi(int satir, int sutun, {int? deger}) =>
      Kare(id: id, satir: satir, sutun: sutun, deger: deger ?? this.deger);

  @override
  bool operator ==(Object other) =>
      other is Kare &&
      other.id == id &&
      other.satir == satir &&
      other.sutun == sutun &&
      other.deger == deger;

  @override
  int get hashCode => Object.hash(id, satir, sutun, deger);

  @override
  String toString() => 'Kare#$id($satir,$sutun)=$deger';
}
