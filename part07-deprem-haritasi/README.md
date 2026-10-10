# Part 07 — Deprem Haritası

Son 7 günün depremlerini bir sismograf kâğıdına çeviren uygulama. Her deprem
kâğıtta büyüklüğüyle orantılı bir tepe. Kâğıdı parmakla geri çekince harita
o saatin son 24 saatine döner. Veri AFAD'ın açık deprem servisinden geliyor.
"Her hafta 1 uygulama" serisinin yedinci parçası.

**Gösterilen yetenek:** Harita, canlı veri ve veriden çizilen, sürüklenebilir
bir sismogram. Dalga `CustomPainter` ile elle çiziliyor, genlik hesabı saf
Dart ve testli.

![Açılış: şerit "şimdi"de](screenshots/01-simdi.png)
![Haritada bir depreme dokunulmuş hâli](screenshots/02-secim.png)

## Çalıştırma

Anahtar, hesap ya da ayar dosyası gerekmiyor:

```bash
flutter pub get
flutter run
```

**Yalnız Android** (seri Windows'ta geliştiriliyor).

## Ekran

Tek ekran, yukarıdan aşağı:

| Bölüm | Ne yapar |
|---|---|
| Üst | "Sismogram" başlığı ve son güncelleme saati. Saate dokun: yenile |
| Kayan bant | Son 14 deprem: büyüklük, yer, saat |
| Harita | Kırmızı çizginin gösterdiği anın son 24 saati. Eski depremler solar, 3 ve üstü kırmızı. Bir noktaya dokun: şerit o ana atlar |
| Bilgi şeridi | Çizginin ±1,5 saat yakınındaki en büyük deprem: büyüklük, yer, saat, derinlik |
| Sismogram | Son 7 gün. Sürükle: zamanda gez. Bırakınca 2,5 sn sonra yine "şimdi"ye akar |

## Sismogram nasıl çiziliyor?

Her piksel bir zaman anı (7 dp = 1 saat). O andaki genlik, yakındaki
depremlerin katkılarının toplamı
([`lib/deprem/sismogram.dart`](lib/deprem/sismogram.dart)):

```
genlik(t) = 1,6 + Σ m^2,15 × 2,1 × e^−((t − tₑ) / 17 dk)²
```

- `m^2,15`: büyüklük ölçeği logaritmik. 4'lük deprem 2'likten çok daha büyük
  bir tepe çiziyor, ama ekrandan taşmıyor.
- `e^−(...)²`: tepe deprem anında en yüksek, 17 dakikada belirgin şekilde
  sönüyor. 1,2 saatten uzak depremler hiç hesaba katılmıyor.
- Dalganın yukarı mı aşağı mı çizileceği piksel zamanından türetiliyor. Şerit
  kayınca dalga titremiyor, aynı an hep aynı şekilde çiziliyor.

Yakın depremler ikili aramayla bulunuyor. Telefonda (Samsung A56, profile)
sürüklerken bir kare ortalama 3,8 ms.

## Veri: AFAD

```
https://servisnet.afad.gov.tr/apigateway/deprem/apiv2/event/filter?start=...&end=...
```

İstemci: [`lib/deprem/afad_istemcisi.dart`](lib/deprem/afad_istemcisi.dart).
Anahtar gerekmiyor. Servis hakkında yazılı olmayan üç şey:

| Konu | Ne oluyor | Uygulamada |
|---|---|---|
| `limit` | Sıralamadan **önce** kesiyor. `limit=100` en yeni 100 depremi vermiyor | `limit` yok. 7 günün tamamı çekiliyor (~700 kayıt, ~220 KB), sıralama uygulamada |
| Saat | UTC geliyor ama sonunda `Z` yok | `Z` eklenip UTC okunuyor, ekranda yerel saat. USGS kayıtlarıyla karşılaştırılarak doğrulandı |
| Sayılar | Enlem, boylam, derinlik, büyüklük metin olarak geliyor | Güvenli ayrıştırma, bozuk kayıt atlanıyor |

## Harita: neden Google Maps değil flutter_map + OpenStreetMap?

Google Maps anahtar ve faturalandırma hesabı istiyor. flutter_map açık kaynak,
karoları OpenStreetMap'ten anahtarsız alıyor. Karşılığında OSM'nin kurallarına
uyuluyor: uygulama kendini tanıtıyor (`userAgentPackageName`), atıf ekranda
görünüyor, karolar önbelleğe alınıyor. Gri ton, karo katmanına bir renk
matrisiyle veriliyor; noktalar renkli kalıyor.

Denenip elenenler: CARTO artık anahtar istiyor. Esri anahtarsız çalışıyor ama
lisansı hesapsız kullanımı açıkça kapsamıyor.

## Veri ve izinler

| Konu | Durum |
|---|---|
| Kullanıcı verisi | Yok. Hesap, konum, ayar tutulmuyor |
| Deprem verisi | Yalnız bellekte. Uygulama kapanınca gider |
| Diske yazılan | Harita karoları: `cache/fm_cache`, en fazla 50 MB |
| İzin | Yalnız `INTERNET`. **Konum izni yok** |
| Dışarıya giden | AFAD isteği ve harita karo istekleri |
| Yedek | `allowBackup` kapalı: yedeklenecek kullanıcı verisi yok |

Doğrulama:

```bash
# izinler, release derlemesinden sonra
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
# diske yazılanlar (run-as yalnız debug derlemesinde çalışır)
adb shell run-as com.omergunes.deprem_haritasi ls cache
```

## Doğrulama

```bash
flutter analyze   # temiz
flutter test      # 42 test
```

| Dosya | Ne sınanıyor | Test |
|---|---|---|
| `sismogram_test.dart` | Taban genlik, tepe yüksekliği, 17 dk sönme, 1,2 saat sınırı, işaretin sabitliği, ±1,5 saatte en büyük deprem, 7 günlük sınır | 11 |
| `afad_istemcisi_test.dart` | URL'de `limit` yok, sıralama, bozuk kayıt, Türkçe karakter, sunucu hatası, zaman aşımı | 10 |
| `deprem_test.dart` | Metin sayılar, UTC çevirisi, yer adı kısaltma | 9 |
| `zaman_metni_test.dart` | Ay kısaltmaları, "45 dk önce" / "3 saat önce" sınırları | 8 |
| `kumele_test.dart` | Izgara kümeleme | 4 |

Gerçek telefonda elle denendi: açılış akışı, sürükleme, haritaya dokunma,
yenileme, uçak modunda hata metni.

## Paketler

`flutter_map` · `latlong2` (flutter_map'in zorunlu eşi) · `http`

Riverpod yok: tek ekran, durum `ValueNotifier` + `Ticker`. Kayan bant paketsiz
yazıldı. Tarih biçimi için `intl` yok, ay kısaltmaları elle. Yazı tipi
(Bricolage Grotesque) dosya olarak gömülü (`assets/fonts/`, OFL lisansı yanında).

## Bilinen sınırlar

- Uygulama açılışta ve elle yenilemede veri çekiyor. Arka planda takip ve
  bildirim yok.
- Filtre ve liste ekranı yok; tek kaynak AFAD.
- Harita etiketleri yerel dilde (OSM'nin varsayılanı): komşu ülkelerde Rusça,
  Arapça, Yunanca yer adları görünüyor.
- Kümeleme kodu var ama kapalı: sayılı daireler haritayı ağırlaştırdı.
- iOS derlemesi yok.
