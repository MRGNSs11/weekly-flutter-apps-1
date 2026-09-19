import 'dart:io';

/// Çekilen/seçilen karenin ömrünü yöneten yer.
///
/// `takePicture()` fotoğrafı uygulamanın özel önbelleğine yazıyor,
/// `image_picker` de galeriden seçileni oraya **kopyalıyor**. İkisi de diskte
/// dosya bırakıyor. "Fotoğraf hiçbir yere kaydedilmiyor" demek istiyorsak
/// işimiz bitince silmemiz gerekiyor.
class GeciciKare {
  const GeciciKare._();

  /// Uygulamanın Android paket adı. Silme izninin sınırı bu.
  static const String paketAdi = 'com.omergunes.metin_tarayici';

  /// Bir dosyanın silinmesine izin verilip verilmediği.
  ///
  /// Kural tek cümle: **uygulama yalnızca kendi klasöründeki dosyayı siler.**
  /// Galeriden seçilen fotoğrafta sildiğimiz şey `image_picker`'ın önbelleğe
  /// aldığı kopya; kullanıcının galerisindeki asıl fotoğrafa dokunulmuyor.
  /// Yol beklenmedik bir yere işaret ediyorsa hiçbir şey silmiyoruz —
  /// yanlış dosya silmektense önbellekte dosya bırakmak yeğdir.
  static bool silinebilirMi(String yol) {
    if (yol.isEmpty) return false;
    final duz = yol.replaceAll('\\', '/');
    return duz.contains('/$paketAdi/');
  }

  /// Kareyi siler. Dosya yoksa veya silinemezse sessizce geçer: bu bir
  /// temizlik işi, kullanıcıya gösterilecek bir hata değil.
  static Future<void> sil(String yol) async {
    if (!silinebilirMi(yol)) return;
    try {
      await File(yol).delete();
    } on FileSystemException {
      // Dosya zaten yok ya da kilitli. Yapacak bir şey yok.
    }
  }
}
