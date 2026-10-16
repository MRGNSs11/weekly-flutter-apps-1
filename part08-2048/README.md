# Part 08 — 2048

Klasik 2048 bulmacası, kil gibi kabarık karelerle. Aynı sayıları kaydırıp
birleştiriyorsun; geri al tuşu son 20 hamleye kadar gidiyor. İnternet yok,
izin yok, reklam yok. "Her hafta 1 uygulama" serisinin sekizinci parçası.

**Gösterilen yetenek:** Riverpod ile tek kaynaktan yönetilen, **hiç
değiştirilmeyen** oyun durumu. Kurallar Flutter'a dokunmayan saf Dart; geri al
bu tasarımın yan ürünü. Üç katman test: birim, widget, cihazda entegrasyon.

![Oyunun ortası](screenshots/01-oyun.png)
![2048 anı: kazanan kare kabarıyor, ötekiler sönüyor](screenshots/02-2048.png)
![Oyun sonu: kareler kurşunlaşıyor](screenshots/03-kursun.png)

## Çalıştırma

Anahtar, hesap ya da ayar dosyası gerekmiyor:

```bash
flutter pub get
flutter run
```

**Yalnız Android** (seri Windows'ta geliştiriliyor).

## Geri al neden bedava?

Oyunun bir anı `OyunDurumu` nesnesi ve bu nesne hiç değiştirilmiyor
([`lib/oyun/oyun_durumu.dart`](lib/oyun/oyun_durumu.dart)). Her hamle eskisine
dokunmadan yeni bir durum üretiyor
([`lib/oyun/kurallar.dart`](lib/oyun/kurallar.dart)). O zaman geçmiş, eski
durumların listesinden ibaret:

```
hamle  : geçmişe şimdiki durumu ekle, yenisine geç
geri al: geçmişin son elemanını geri koy
```

Geri al ayrıca hesaplanmıyor, kopyalanmıyor. Test bunu doğrudan sınıyor:
geri alınan durum, hamleden önceki durumla **aynı nesne**
([`test/oyun_notifier_test.dart`](test/oyun_notifier_test.dart)).

Rastgelelik de dışarıdan veriliyor (`Random`). Testte sabit tohumla "rastgele"
yeni kare her seferinde aynı yere düşüyor, bu yüzden kurallar telefonsuz,
saniyeler içinde sınanabiliyor.

## Neden `setState` değil Riverpod?

Tek ekranlık bir oyunda `setState` de çalışırdı. Ama durum ekranın içinde
yaşardı ve onu sınamak için ekranı kurmak gerekirdi. Riverpod'la oyun bir
`Notifier`'da duruyor ([`lib/oyun/oyun_notifier.dart`](lib/oyun/oyun_notifier.dart)):
`kaydir`, `geriAl`, `yeniOyun`, `devamEt`. Ekran yalnız okuyor. Notifier testleri
ekransız çalışıyor; widget testleri aynı Notifier'a hazır bir tahta vererek
(provider override) belirli anları kuruyor.

## Kil yüzey: tek sayı, beş animasyon

Her kare, düğme ve çukur aynı çizicinin işi
([`lib/ui/kil_yuzey.dart`](lib/ui/kil_yuzey.dart)). Tek girdisi bir
**yükseklik**: artı kabarık, sıfır düz, eksi içe basık. Animasyonların çoğu
bu sayının animasyonu:

| An | Animasyon | Yükseklik |
|---|---|---|
| Yeni kare | Çukurdan doğar | −3 → 0 → kabarık |
| Birleşme | Yoğrulur: önce basılır, sonra daha kabarık çıkar | +g → −4 → +g' |
| 2048 | Kazanan kare en çok kabarır, ötekiler düzleşip solar | → 9 / → 0 |
| Oyun sonu | Kareler satır satır içe çöker, rakamlar griye döner | → −3 |
| Geri al | Tahta bir an grileşir, kareler yavaş geri kayar | — |

Her hamlede tahta kaydırma yönüne 7° eğilip yaylanarak düzeliyor. Telefonda
"animasyonları kaldır" açıksa eğim ve süslemeler kapanıyor.

**Performans dersi.** Flutter'ın gölgelerinde "iç gölge" yok. İlk sürüm içe
basıklığı delikli bir şekli bulanıklaştırarak çiziyordu; bu, her seferinde
yüzeyin 9 katı alanı bulanıklaştırmak demekti ve gerçek telefonda oyun
takılıyordu. Şimdi iç gölge yalnız yuvarlak dikdörtgen bulanıklığıyla
çiziliyor; ekran kartı bunu hızlı yoldan çiziyor. Tahtanın zemini de ayrı bir
katmanda bir kez çiziliyor, kareler kayarken yeniden çizilmiyor.

## Veri ve izinler

| Konu | Durum |
|---|---|
| Tutulan | En iyi skor (bir sayı) + yarım kalan oyun (16 sayı, skor, hamle sayısı). Geri al geçmişi tutulmuyor |
| Nerede | `shared_preferences`, uygulamanın kendi klasörü. Başka uygulama okuyamaz |
| Silinme | Oyun bitince ve yeni oyunda yarım oyun kaydı silinir |
| Bozuk kayıt | Okurken her alan denetlenir (16 hücre, 2'nin kuvvetleri, skor sınırı). Tutarsızsa yeni oyun açılır, uygulama çökmez |
| İzin | **Yok.** İnternet izni bile yok |
| Dışarıya giden | Hiçbir şey |
| Yedek | `allowBackup` açık, bilerek: telefon değişince skor ve yarım oyun gelsin. İkisinde de kişisel bilgi yok |

Doğrulama:

```bash
# izinler, release derlemesinden sonra (çıktıda android.permission satırı yok;
# yalnız androidx'in uygulamaya özel iç izni görünür)
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
# diske yazılan (run-as yalnız debug derlemesinde çalışır): iki anahtar
adb shell run-as com.omergunes.oyun_2048 cat shared_prefs/FlutterSharedPreferences.xml
```

## Doğrulama

```bash
flutter analyze                 # temiz
flutter test                    # 72 test
flutter test integration_test   # cihaz ya da emülatör gerekir
```

| Dosya | Ne sınanıyor | Test |
|---|---|---|
| `kurallar_test.dart` | Dört yönde kayma, `[2,2,2,2]` → `[4,4]`, zincir birleşme olmaması, skor, yeni karenin %10 ihtimalle 4 olması, oyun sonu, 2048, kimliklerin korunması, durumun değişmezliği | 23 |
| `kayit_test.dart` | Kaydedip okuyunca aynı tahta + 17 farklı bozuk kayıt (yanlış sürüm, 15/17 hücre, 3 ya da negatif değer, ondalık skor…) | 21 |
| `oyun_notifier_test.dart` | Geri alın tam önceki nesneyi vermesi, 20 hamle sınırı, en iyi skor, katmanlar, yarım oyunun kaydı ve yeniden açılış | 15 |
| `oyun_ekrani_test.dart` | Kaydır → skor → geri al, 24 px eşiği, tahtanın eğilip düzelmesi, geri alda grileşme, 2048 katmanının zamanlaması, "animasyonları kaldır" | 8 |
| `kayit_deposu_test.dart` | Okuma, yazma, silme, yalnız iki anahtar | 5 |

Entegrasyon testi
([`integration_test/oyun_test.dart`](integration_test/oyun_test.dart)) gerçek
kaydırmalarla oynuyor, uygulamayı kapatıp açıyor ve yarım oyunun ve en iyi
skorun yerinde durduğunu kontrol ediyor. CI'da çalışmıyor (cihaz istiyor).

## Paketler

`flutter_riverpod` · `shared_preferences`

Animasyon paketi yok: hepsi Flutter'ın kendi `AnimationController`'larıyla.
Yazı tipi (Nunito) dosya olarak gömülü (`assets/fonts/`, OFL lisansı yanında).
İkon `tool/ikon_uret.py` ile üretiliyor.

## Bilinen sınırlar

- Tahta yalnız 4×4. Liderlik tablosu, tema seçici, istatistik ekranı yok.
- Geri al geçmişi uygulama kapanınca sıfırlanıyor (yarım oyun kalıyor).
- Ses ve titreşim yok.
- iOS derlemesi yok.
