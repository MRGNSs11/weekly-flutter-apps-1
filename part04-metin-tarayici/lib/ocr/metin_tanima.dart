import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'okunan_metin.dart';

/// Cihazdaki ML Kit modelini çağıran ince katman.
///
/// Burada iş mantığı yok — model çıktısını [OkunanBlok] listesine çevirip
/// [MetinDuzenleyici]'ye veriyor. Test edilen yer orası; burası eklentiye
/// bağlı olduğu için test edilmiyor.
///
/// Ağ yok: model APK'nın içinde (+27 MB'ın sebebi bu). Fotoğraf da metin de
/// cihazdan çıkmıyor.
class MetinTanima {
  MetinTanima() : _tanici = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _tanici;

  Future<OkunanSonuc> dosyadanOku(String dosyaYolu) async {
    final girdi = InputImage.fromFilePath(dosyaYolu);
    final sonuc = await _tanici.processImage(girdi);
    return MetinDuzenleyici.duzenle(
      sonuc.blocks.where((blok) => blok.lines.isNotEmpty).map(_bloguCevir).toList(),
    );
  }

  Future<void> kapat() => _tanici.close();

  static OkunanBlok _bloguCevir(TextBlock blok) => OkunanBlok(
    satirlar: [
      for (final satir in blok.lines)
        OkunanSatir(metin: satir.text, kutu: satir.boundingBox),
    ],
  );
}
