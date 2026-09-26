import 'dart:math';

/// Listeye katılma kodu: 6 hane, "K7M4XP" gibi.
///
/// Birbirine karışan karakterler alfabede yok: 0/O, 1/I/L. Kod sesli
/// söylenip elle yazılıyor, "sıfır mı o mu" sorusu hiç doğmasın.
/// 31 karakter × 6 hane ≈ 887 milyon ihtimal.
abstract final class Kod {
  static const alfabe = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const uzunluk = 6;

  /// Yeni bir kod üretir. Testte aynı sonucu almak için [rastgele] verilir;
  /// uygulamada `Random.secure()` kullanılır (tahmin edilemesin).
  static String uret([Random? rastgele]) {
    final r = rastgele ?? Random.secure();
    return List.generate(
      uzunluk,
      (_) => alfabe[r.nextInt(alfabe.length)],
    ).join();
  }

  /// Kullanıcının yazdığını kod biçimine getirir: boşluklar atılır, harfler
  /// büyütülür. Alfabe dışı karakterlere dokunmaz — onları [gecerliMi] yakalar.
  static String normalize(String ham) =>
      ham.replaceAll(RegExp(r'\s'), '').toUpperCase();

  static bool gecerliMi(String kod) =>
      kod.length == uzunluk && kod.split('').every(alfabe.contains);

  /// Yazarken alfabe dışı karakterleri eler (kod kutusunun girdi süzgeci).
  static String suz(String ham) =>
      normalize(ham).split('').where(alfabe.contains).take(uzunluk).join();
}
