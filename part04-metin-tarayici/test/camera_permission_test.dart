import 'package:flutter_test/flutter_test.dart';
import 'package:metin_tarayici/camera/camera_permission.dart';
import 'package:permission_handler/permission_handler.dart';

/// İzin durumunun hangi ekranı açtığı buradan belli oluyor.
/// Eklentiye dokunulmuyor: `statusuCevir` saf bir fonksiyon.
void main() {
  group('CameraPermission.statusuCevir', () {
    test('izin verildiyse kamera açılır', () {
      expect(
        CameraPermission.statusuCevir(PermissionStatus.granted),
        CameraAccess.granted,
      );
    });

    test('reddedildiyse tekrar sorulabilir', () {
      expect(
        CameraPermission.statusuCevir(PermissionStatus.denied),
        CameraAccess.denied,
      );
    });

    test('"bir daha sorma" ayrı bir hâldir — tekrar sormak işe yaramaz', () {
      expect(
        CameraPermission.statusuCevir(PermissionStatus.permanentlyDenied),
        CameraAccess.blocked,
      );
    });

    test('cihaz politikası engelliyorsa da tek çıkış ayarlar', () {
      expect(
        CameraPermission.statusuCevir(PermissionStatus.restricted),
        CameraAccess.blocked,
      );
    });

    test('kısıtlı izin (limited) kamera için yeterli sayılır', () {
      expect(
        CameraPermission.statusuCevir(PermissionStatus.limited),
        CameraAccess.granted,
      );
    });

    test('bilinmeyen hiçbir durum sessizce "izin var" sayılmaz', () {
      for (final status in PermissionStatus.values) {
        final sonuc = CameraPermission.statusuCevir(status);
        final izinli = status.isGranted || status.isLimited;
        expect(
          sonuc == CameraAccess.granted,
          izinli,
          reason: '$status yanlış tarafa düşüyor',
        );
      }
    });
  });
}
