import 'package:flutter_test/flutter_test.dart';
import 'package:metin_tarayici/camera/gecici_kare.dart';

/// Silme kuralının sınırı: uygulama yalnızca kendi klasöründeki dosyaya
/// dokunur. Bu testler kullanıcının galerisindeki fotoğrafın asla
/// silinemeyeceğini tutuyor.
void main() {
  group('GeciciKare.silinebilirMi', () {
    const paket = GeciciKare.paketAdi;

    test('kameranın önbelleğe yazdığı kare silinebilir', () {
      expect(
        GeciciKare.silinebilirMi('/data/user/0/$paket/cache/CAP123.jpg'),
        isTrue,
      );
    });

    test('image_picker kopyası da uygulamanın klasöründedir', () {
      expect(
        GeciciKare.silinebilirMi(
          '/data/user/0/$paket/cache/image_picker/secilen.jpg',
        ),
        isTrue,
      );
    });

    test('kullanıcının galerisindeki fotoğraf SİLİNMEZ', () {
      expect(
        GeciciKare.silinebilirMi('/storage/emulated/0/DCIM/Camera/foto.jpg'),
        isFalse,
      );
    });

    test('başka bir uygulamanın klasörüne dokunulmaz', () {
      expect(
        GeciciKare.silinebilirMi('/data/user/0/com.baska.uygulama/cache/x.jpg'),
        isFalse,
      );
    });

    test('paket adını içeren ama bizim olmayan yol kabul edilmez', () {
      // Sondaki ek yüzünden bu başka bir pakettir.
      expect(
        GeciciKare.silinebilirMi('/data/user/0/$paket.baska/cache/x.jpg'),
        isFalse,
      );
    });

    test('boş yol silinmez', () {
      expect(GeciciKare.silinebilirMi(''), isFalse);
    });

    test('ters bölü kullanan yollar da tanınır', () {
      expect(
        GeciciKare.silinebilirMi('C:\\tmp\\$paket\\cache\\kare.jpg'),
        isTrue,
      );
    });
  });

  group('GeciciKare.sil', () {
    test('izin verilmeyen yolda hiçbir şey yapmaz, hata da atmaz', () async {
      await expectLater(
        GeciciKare.sil('/storage/emulated/0/DCIM/Camera/foto.jpg'),
        completes,
      );
    });

    test('olmayan dosyada çökmez', () async {
      await expectLater(
        GeciciKare.sil(
          '/data/user/0/${GeciciKare.paketAdi}/cache/olmayan.jpg',
        ),
        completes,
      );
    });
  });
}
