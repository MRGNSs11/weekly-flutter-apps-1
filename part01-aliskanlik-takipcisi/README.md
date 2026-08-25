# Alışkanlık Takipçisi — Her Hafta 1 Uygulama, Part 01

Alışkanlık edinmeye çalışan biri için "kaç gündür üst üste yapıyorum?" sorusunu
tek bakışta cevaplayan, GitHub'ın katkı ısı haritasına benzer bir görselle
seriyi gösteren bir Flutter uygulaması.

Bu proje, CV/portföy için hafta sonlarında (48 saat) baştan sona bitirilen bir
uygulama serisinin ilk halkası. Serinin tamamı:
[weekly-flutter-apps](https://github.com/MRGNSs11/weekly-flutter-apps).

**Vaka incelemesi:** [VAKA.md](VAKA.md) — neyi neden öyle yaptığımı anlattığım kısa yazı.

| Liste | Detay + ısı haritası |
|---|---|
| ![Liste ekranı](screenshots/liste.png) | ![Detay ekranı](screenshots/detay.png) |

## Çekirdek akış

Alışkanlık ekle → günü işaretle → ısı haritasında seriyi gör.
Geçmiş bir günü de doğrudan ısı haritasından dokunarak işaretleyebilirsin.

## Bu haftanın gösterdiği teknik yetenek

**Yerel veritabanı (Drift) + elle yazılmış `CustomPainter` ile ısı haritası
çizimi.** 365+ günlük bir veriyi widget ağacıyla (ör. `GridView` içinde
365 `Container`) çizmeye çalışırsan performans düşer; tek bir `CustomPainter`
ile tüm ızgara bir seferde, tek bir `Canvas` üzerine çizilir.

Isı haritasının 5 rengi, bir alışkanlık günlük olarak zaten ikili
(yapıldı/yapılmadı) olduğu için, o günü kapsayan serinin **o andaki
uzunluğuna** göre koyulaşacak şekilde tasarlandı — harita ne kadar koyuysa,
o gün canlı olan seri o kadar uzundu.

## Neden Hive değil Drift?

Bu kadar küçük bir uygulamada akla ilk gelen yerel depolama paketi genelde
Hive olur. Ama "mevcut seri" ve "en uzun seri" hesabı özünde bir **tarih
aralığı sorgusu**. Hive gibi bir key-value deposunda bunu yapmak için tüm
kayıtları belleğe çekip Dart tarafında filtrelemek/sıralamak gerekir.
Drift'te (SQLite üzerine tip güvenli bir katman) bu tek bir SQL sorgusu.
Veri büyüdükçe (yıllar süren kullanım) bu fark iyice açılır.

## Kullanılan paketler

- [`drift`](https://pub.dev/packages/drift) + [`drift_flutter`](https://pub.dev/packages/drift_flutter) — yerel veritabanı
- [`path_provider`](https://pub.dev/packages/path_provider) — veritabanı dosya yolu

Durum yönetimi için Riverpod/Provider **kullanılmadı** — 3 ekranlık bir
uygulamada dış paket eklemek yerine Flutter'ın kendi `StreamBuilder` /
`ValueNotifier` araçları tercih edildi. Isı haritası da hazır bir takvim
paketi yerine elle `CustomPainter` ile çizildi; amaç zaten o yeteneği
göstermekti.

## Çalıştırma

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Testler

Sadece saf mantık (streak hesabı, ısı haritası ızgara yerleşimi, tarih
dönüşümleri) test edildi — widget testi yok, 48 saatlik kapsama girmedi.

```
flutter test
```

25 test, hepsi domain katmanında (`lib/domain/`).

## Bu sürümde bilerek olmayanlar

Kapsamı 48 saate sığdırmak için bilinçli olarak dışarıda bırakıldı:

- Bildirim / hatırlatıcı
- Haftalık hedef (ör. "haftada 3 gün")
- Kategori / etiket
- İstatistik grafikleri
- Bulut senkronizasyonu / hesap sistemi
- Ana ekran widget'ı
- Açık/koyu tema seçici
- Veri dışa aktarma

## Tasarım

"Organik / Toprak" yönü — toprak ve yeşil tonlar, serif başlıklar (Lora),
yuvarlak ısı haritası noktaları. Altı taslak arasından seçildi; taslak
görselleri ve seçim gerekçesi `PLAN.md` içinde.

## Lisans

MIT — bkz. [LICENSE](LICENSE).
