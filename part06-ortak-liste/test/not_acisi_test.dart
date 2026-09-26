import 'package:flutter_test/flutter_test.dart';
import 'package:ortak_liste/ui/parcalar/not_karti.dart';

void main() {
  test('not açısı ±3.6° içinde ve aynı kimlik için hep aynı', () {
    for (final id in ['a', 'Xy9', 'uzun-bir-firestore-kimligi', '']) {
      final aci = notAcisi(id);
      expect(aci, inInclusiveRange(-3.6, 3.6), reason: id);
      expect(notAcisi(id), aci);
    }
  });

  test('farklı kimlikler farklı açılar alabiliyor (hepsi aynı değil)', () {
    final acilar = {for (var i = 0; i < 20; i++) notAcisi('urun$i')};
    expect(acilar.length, greaterThan(3));
  });
}
