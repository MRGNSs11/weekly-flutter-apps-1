# Part 04 — Metin Tarayıcı

Kâğıttaki yazıyı kamerayla okuyup metne çeviren Flutter uygulaması.
"Her hafta 1 uygulama" serisinin dördüncü parçası.

**Gösterilen yetenek:** kamera + **cihazda çalışan makine öğrenmesi**
(Google ML Kit, Latin metin tanıma) ve çalışma anı izin yönetimi.

Uygulamanın **internet izni yoktur.** Model APK'nın içinde çalışır; fotoğraf da
metin de cihazdan çıkmaz. Veritabanı, ayar dosyası, günlük yok — okunan metin
yalnızca bellekte durur, çekilen kare ise sonuç ekranı kapanınca silinir.

## Çalıştırma

API anahtarı, hesap, sunucu yok:

```bash
flutter pub get
flutter run
```

**Gerçek cihaz gerekir.** Emülatörde kamera iş görmez.

## Ekranlar

| Ekran | Ne yapar |
|---|---|
| Kamera | Canlı önizleme, kadraj nişangahı, deklanşör; ışık, kamera çevirme, galeriden seçme |
| Sonuç | Çekilen kare + okunan metin (düzenlenebilir); kopyala, paylaş, yeniden çek |
| İzin | Kamera izni yokken ne olduğunu söyler; kalıcı redde "Ayarları aç" |

![Kamera ekranı](screenshots/01-kamera.png)
![Okunan metin](screenshots/02-sonuc.png)

## Neden bulut OCR değil?

Google Cloud Vision veya AWS Textract daha iyi okur. Karşılığında saklanması
gereken bir anahtar, bir kota ilişkisi ve **kullanıcının fotoğrafının bir
sunucuya gitmesi** gelir. Bu uygulamaya insanların faturasını, reçetesini,
kimliğini tutacağı düşünülürse üçüncüsü kabul edilemezdi.

Bedeli ölçüldü: **modelin kendisi +27 MB** (boş projede debug APK 147 → 174 MB,
paketten önce ve sonra derlenip fark alındı). Release APK 77 MB.

## Diskte ne kalıyor?

Hiçbir şey — ama bu bedavaya gelmiyor. `takePicture()` fotoğrafı uygulamanın
özel önbelleğine **yazıyor**, `image_picker` da galeriden seçileni oraya
**kopyalıyor**. Hiç dokunmasan her çekim diskte birikirdi.

`lib/camera/gecici_kare.dart` sonuç ekranı kapanınca kareyi siliyor. Silme
kuralının tek bir sınırı var: **uygulama yalnızca kendi klasöründeki dosyaya
dokunur.** Galeriden seçilende silinen şey `image_picker`'ın aldığı kopya;
kullanıcının galerisindeki asıl fotoğraf yerinde kalıyor. Yol beklenmedik bir
yere işaret ediyorsa hiçbir şey silinmiyor — yanlış dosya silmektense
önbellekte dosya bırakmak yeğdir. Kural yedi testle tutuluyor.

Okunan metin hiç diske yazılmıyor; veritabanı, ayar dosyası, günlük yok.

Cihaz yedeği de kapalı (`allowBackup` + `fullBackupContent` +
`dataExtractionRules`). Yedeklenecek kalıcı veri zaten yok; kapatmanın sebebi
tek istisnayı da kapamak: bir kare silinmeye fırsat bulamadan uygulama
öldürülürse o kare de buluta gitmesin.

## İzinler: manifest'e izin yazmamak yetmiyor

"Ağa çıkmıyoruz" demek kolay. Bunu doğrulanabilir yapmak için birleşmiş
manifest'i okumak gerekti — çünkü **eklentiler kendi izinlerini getiriyor.**
Bu projenin kendi manifest'i tek satır `CAMERA` yazdığı hâlde birleşmiş
manifest'te beş izin daha vardı:

| İzin | Nereden geliyordu | Neden kaldırıldı |
|---|---|---|
| `RECORD_AUDIO` | `camera_android_camerax` | Video kaydı için; biz `enableAudio: false` ile tek kare alıyoruz |
| `WRITE_EXTERNAL_STORAGE` | `camera_android_camerax` | Diske bir şey yazmıyoruz |
| `READ_EXTERNAL_STORAGE` | yukarıdakinden türetiliyor | — |
| `ACCESS_NETWORK_STATE` | `androidx.media3-common` (camerax'in bağımlısı) | Ağ diye bir şey yok |
| **`INTERNET`** | **`com.google.android.datatransport`** (ML Kit'in bağımlısı) | **Model için değil, Google'ın kullanım telemetrisi için geliyordu** |

Sonuncusu haftanın sürpriziydi: metin tanıma gerçekten cihazda çalışıyor, ama
ML Kit yanında Google'ın telemetri kütüphanesini de getiriyor ve o kütüphane
ağ izni istiyor. Beşi de `tools:node="remove"` ile çıkarıldı.

Doğrulama, iddia değil — release derlemesinden sonra:

```bash
grep -o 'uses-permission android:name="[^"]*"' \
  build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml
```

Çıktıda yalnızca `CAMERA` (bir de androidx'in kendi imza-seviyesi iç izni) var.
Flutter'ın **debug** derlemesi hot reload için `INTERNET` ekler ve bu bilerek
korundu — geliştirirken gerekiyor, release'de yok.

## İzin: "şimdi olmaz" ile "bir daha sorma" aynı şey değil

`camera` paketi Android'de yalnızca "izin yok" der. Oysa iki hâl farklıdır:
ilkinde tekrar sorulabilir, ikincisinde sistem diyaloğu bir daha **hiç
açılmaz** — uygulama sorsa da hiçbir şey olmaz ve kullanıcı boş ekrana bakar.
Ayrım `lib/camera/camera_permission.dart` içinde üç değerli bir enum'a
indiriliyor; kalıcı redde tek çıkış olarak "Ayarları aç" düğmesi çıkıyor.

## Metin düzenleme

ML Kit çağrısı üç satır; asıl kod **modelden sonra** başlıyor. Ham çıktı
doğrudan gösterilemez:

| Sorun | Ne yapılıyor |
|---|---|
| Bloklar sayfadaki sırayla gelmez | Önce dikey bantlara ayrılıyor, her bant soldan sağa sıralanıyor (yan yana sütunlar doğru okunuyor) |
| Paragraf satır satır kırık | Bir bloğun satırları tek paragrafa akıtılıyor |
| Satır sonundaki tire kelimeyi böler | `eko-` + `nomi` → `ekonomi`; ama `Ankara-` + `İstanbul` ve `2024-` + `2025` bozulmuyor |
| Fazla boşluk, boş satır | Temizleniyor |

Okuma hataları **düzeltilmiyor.** Model `ı` yerine `i` görürse öyle kalıyor —
yanlış düzeltme, yanlış okumadan beterdir. Onun yerine sonuç metni
düzenlenebilir bırakıldı.

## Doğrulama

```bash
flutter analyze   # temiz
flutter test      # 36 test
```

Kamera ve model test edilmiyor (ikisi de cihaza bağlı, orada bu projenin kodu
yok). Test edilen yer ikisinin arasındaki dönüşüm — `lib/ocr/okunan_metin.dart`
saf bir katman olduğu için eksiksiz test edilebiliyor.

## Paketler

`camera` · `google_mlkit_text_recognition` · `share_plus` ·
`permission_handler` · `image_picker`

İki not, ikisi de serinin "en fazla 3 paket" kuralından sapma:

- **`permission_handler`** eklendi çünkü `camera` paketi kalıcı reddi ayırt
  etmiyor; ayrım olmadan yukarıdaki izin akışı kurulamazdı.
  **`12.0.0`'da sabit** — 13.x'in Android tarafı derleme SDK 37 istiyor,
  bu kurulumda 36 var.
- **`image_picker`** eklendi çünkü galeriden seçme onaylı tasarımda vardı.

Panoya kopyalama Flutter'ın kendi `Clipboard`'ıyla yapılıyor, paket yok.

## Release derlemesi için ProGuard notu

`google_mlkit_text_recognition` eklentisi beş betiği de çağırabiliyor (Latin,
Çince, Devanagari, Japonca, Korece) ama biz yalnızca Latin modelini bağımlılık
olarak alıyoruz. Diğer dördünün sınıfları APK'da olmadığı için R8 release
derlemesini "eksik sınıf" diye durduruyordu. `android/app/proguard-rules.pro`
o dört paketi `-dontwarn` ile susturuyor — sınıfları eklemek her biri için
ayrı model, yani bir 27 MB daha demekti.

## Kurulum notu

Depoyu klonladıysan commit koruması için bir kez:

```bash
git config core.hooksPath .githooks
```
