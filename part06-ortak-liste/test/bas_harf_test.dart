import 'package:flutter_test/flutter_test.dart';
import 'package:ortak_liste/liste/bas_harf.dart';

void main() {
  test('Türkçe i ve ı doğru büyür', () {
    expect(basHarf('incir'), 'İ');
    expect(basHarf('ılık süt'), 'I');
  });

  test('diğer Türkçe harfler', () {
    expect(basHarf('şeker'), 'Ş');
    expect(basHarf('çay'), 'Ç');
    expect(basHarf('üzüm'), 'Ü');
    expect(basHarf('öğütülmüş kahve'), 'Ö');
    expect(basHarf('ğ'), 'Ğ');
  });

  test('zaten büyük harf olduğu gibi kalır', () {
    expect(basHarf('Süt'), 'S');
    expect(basHarf('İncir'), 'İ');
  });

  test('harf olmayan ilk karakter olduğu gibi döner', () {
    expect(basHarf('3 yumurta'), '3');
    expect(basHarf('🍋 limon'), '🍋');
  });

  test('baştaki boşluk atlanır, boş ad soru işareti olur', () {
    expect(basHarf('   ekmek'), 'E');
    expect(basHarf(''), '?');
    expect(basHarf('   '), '?');
  });

  test('turkceBuyuk bütün kelimede çalışır', () {
    expect(turkceBuyuk('liste'), 'LİSTE');
    expect(turkceBuyuk('ılık'), 'ILIK');
  });
}
