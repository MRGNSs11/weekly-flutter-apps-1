import 'package:permission_handler/permission_handler.dart';

/// Kamera izninin uygulama açısından anlamlı üç hali.
///
/// `camera` paketi Android'de yalnızca "izin yok" diyor; "şimdi olmaz" ile
/// "bir daha sorma" arasındaki farkı vermiyor. Fark önemli: birincisinde
/// tekrar sorabiliriz, ikincisinde tek çıkış sistem ayarları.
enum CameraAccess {
  granted,

  /// Kullanıcı reddetti ama tekrar sorulabilir.
  denied,

  /// "Bir daha sorma" seçildi ya da cihaz yönetimi engelliyor.
  /// Sistem diyaloğu bir daha AÇILMAZ; uygulama sorsa da hiçbir şey olmaz.
  blocked,
}

/// İzin sorma işini tek yerde toplar.
///
/// `statusuCevir` saf bir fonksiyon: eklentiye dokunmadan test edilebiliyor.
class CameraPermission {
  const CameraPermission();

  Future<CameraAccess> iste() async {
    final status = await Permission.camera.request();
    return statusuCevir(status);
  }

  Future<CameraAccess> kontrolEt() async {
    final status = await Permission.camera.status;
    return statusuCevir(status);
  }

  /// Ayarlar ekranını açar. Yalnızca [CameraAccess.blocked] halinde anlamlı.
  Future<bool> ayarlariAc() => openAppSettings();

  static CameraAccess statusuCevir(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return CameraAccess.granted;
    // restricted: ebeveyn denetimi / kurumsal politika. Kullanıcı açısından
    // sonucu "bir daha sorma" ile aynı — sistem diyaloğu çıkmıyor.
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAccess.blocked;
    }
    return CameraAccess.denied;
  }
}
