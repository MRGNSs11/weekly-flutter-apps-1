# Part 09 — Pomodoro

Telefon cebindeyken de doğru zamanda uyaran bir pomodoro sayacı. Çalışma
sürdükçe ekran alttan lacivertle doluyor, molada yeşille dolu başlayıp
boşalıyor. Sayaç bildirim panelinde de akıyor. Süre dolunca telefon
kilitliyse ekran açılıyor ve alarm, sen durdurana kadar çalıyor. İnternet yok,
reklam yok. "Her hafta 1 uygulama" serisinin dokuzuncu parçası.

**Gösterilen yetenek:** Yerel bildirim. Panelde kendi kendine akan geri sayım,
uygulama kapalıyken çalışan bildirim butonları ve tam zamanında gelen,
kilit ekranında açılan bir alarm.

## Çalıştırma

Anahtar, hesap ya da ayar dosyası gerekmiyor:

```bash
flutter pub get
flutter run
```

**Yalnız Android** (seri Windows'ta geliştiriliyor). Bildirim, kesin alarm ve
tam ekran izinleri ilk **Başlat**'ta sırayla soruluyor.

## Uygulama kapalıyken sayacı kim sayıyor?

Kimse. Arka planda çalışan Dart kodu yok. Uygulama yalnız **bitiş anını**
kaydediyor ve iki şeyi Android'e bırakıyor:

1. Paneldeki geri sayım, Android'in kendi kronometresi
   (`usesChronometer` + `chronometerCountDown`). Bildirimi bir kez koyuyorum,
   saniyeleri Android ilerletiyor.
2. "Süre doldu" bildirimi bitiş anına **zamanlanmış** olarak bekliyor. Aynı
   numarayı kullandığı için düştüğü an sayacın yerine geçiyor; geri sayım
   eksiye inmiyor.

Uygulama açılınca durum bitiş anından yeniden hesaplanıyor
([`lib/alan/kurallar.dart`](lib/alan/kurallar.dart) → `ilerlet`). Süre
geçmişse faz o an tamamlanıyor: çalışmaysa sayılıyor, sıradaki faz hazır
bekliyor. Saatlerce kapalı kalsa da yalnız bir faz tamamlanıyor; 23:50'de
biten pomodoro ertesi gün açılınca doğru güne yazılıyor.

## Neden ön plan servisi değil?

Klasik yol, sayaç sürerken bir ön plan servisi çalıştırıp her saniye bildirimi
güncellemek. Bunun bedeli pil, sürekli çalışan kod ve en önemlisi Samsung gibi
üreticilerin arka plandaki uygulamaları kapatması: servis ölünce sayaç durur.

Kronometre + zamanlanmış bildirimle uygulama tamamen kapansa da sayaç ve alarm
yaşıyor, çünkü ikisi de sistemde. Bedeli: panelde dakika bazlı ilerleme
çubuğu gibi canlı ayrıntılar yok, yalnız geri sayım var.

## Bildirim, durumdan türetiliyor

Paneli adım adım değiştirmiyorum. Tek fonksiyon var:
`esitle(durum, ayarlar)`
([`lib/bildirim/yerel_bildirim_servisi.dart`](lib/bildirim/yerel_bildirim_servisi.dart)).
Her seferinde bildirimi siliyor ve duruma göre baştan kuruyor: çalışıyorsa
sayaç + zamanlanmış alarm, duraklatıldıysa "Kalan 12:34", boştaysa hiçbir şey.
Flutter'ın `build`'i gibi: ekran da panel de aynı durumdan çiziliyor.

Panel butonları (Duraklat · +1 dk · Bitir · Devam · Başlat · Atla) uygulama
kapalıyken ayrı bir isolate'te çalışıyor
([`lib/bildirim/arka_plan.dart`](lib/bildirim/arka_plan.dart)): kaydı okuyor,
eylemi uyguluyor, yazıyor, `esitle` çağırıyor. Uygulama açıksa aynı fonksiyondan
geçiyor ve ekran bir port mesajıyla tazeleniyor. İki isolate aynı kaydı
yazdığı için önbelleksiz `SharedPreferencesAsync` kullanılıyor.

## Süre doldu: alarm

Bildirim sesi panel çekilince Android tarafından kesiliyor. Bu yüzden alarm
iki parçalı:

1. Zamanlanmış bildirim **tam ekran bildirimi** olarak düşüyor: telefon
   kilitliyse ekran açılıyor, uygulama "Süre doldu" ekranıyla geliyor. Sesi
   alarm sesi ve ısrarcı (dokunulana kadar tekrar ediyor).
2. Uygulama alarmı fark edince bildirimi sessiz sürümüyle değiştiriyor ve
   kendi zilini çalıyor ([`MainActivity.kt`](android/app/src/main/kotlin/com/omergunes/pomodoro/MainActivity.kt)).
   Zil yalnız **Durdur**, **Sıradakini başlat** ya da bildirim kapanınca
   susuyor.

Uygulama kilidin üstünde yalnız panelde gerçekten bir "süre doldu" bildirimi
varken görünüyor; zil susunca bu geri alınıyor. Ayarlardan ses kapatılırsa
ekran yine açılıyor, zil çalmıyor.

## Ekran: dolan ekran

Rakam aynı yazıyla iki kez çiziliyor; üstteki kat dolgunun şekliyle kırpılıyor,
bu yüzden rakamın dolguya giren kısmı beyaza dönüyor
([`lib/ui/parcalar/dolgu_boyaci.dart`](lib/ui/parcalar/dolgu_boyaci.dart)).
Dolgunun üst kenarı kıvrımlı bir sinüs.

| An | Animasyon |
|---|---|
| Çalışma | Ekran alttan doluyor, kenar kıvrılıyor |
| Mola | Ekran dolu başlıyor, boşalıyor; renk 600 ms'de yeşile dönüyor |
| Duraklatıldı | Rakam yavaşça nefes alıyor |
| +1 dk | "+1" yukarı uçup sönüyor |
| Pomodoro bitti | Döngü noktası doluyor, parçacıklar; 4/4'te konfeti |
| Sürükleme | Boştayken ekranı yukarı-aşağı sürükleyince çalışma süresi 1–90 dk |

Dolgu ekranın tepesine kadar çıkabildiği için ekranda kalan her şey ya beyaz
bir hapın içinde ya da rengini dolguya göre değiştiriyor; durum çubuğunun
ikonları da dolgu tepeye ulaşınca açık renge dönüyor. Telefonda
"animasyonları kaldır" açıksa kenar duruyor, geçişler anında, dolgu saniye
adımlı.

## Veri ve izinler

| Konu | Durum |
|---|---|
| Tutulan | Ayarlar (3 süre + ses) ve sayaç durumu (faz, bitiş anı, bugünkü sayı, döngü sayacı). Kişisel bilgi yok |
| Nerede | `SharedPreferencesAsync`, uygulamanın kendi klasörü |
| Bozuk kayıt | Her alan denetlenir. Tutarsızsa (örneğin "çalışıyor" ama bitiş anı yok) boş sayaca düşer, uygulama çökmez |
| İzinler | `POST_NOTIFICATIONS` (bildirim) · `VIBRATE` (titreşim) · `SCHEDULE_EXACT_ALARM` (tam zamanında uyarı) · `RECEIVE_BOOT_COMPLETED` (yeniden başlatınca zamanlamayı geri kurmak) · `USE_FULL_SCREEN_INTENT` (kilit ekranında alarm) |
| İnternet | **Yok.** `INTERNET` izni bile yok |
| Dışarıya giden | Hiçbir şey |
| Yedek | `allowBackup` açık: kişisel bilgi yok, yalnız ayar ve sayaç |

İzin reddedilirse uygulama durmuyor: sayaç çalışıyor, üstte bir bant çıkıyor
("Bildirimler kapalı · Ayarları aç", "Uyarı birkaç dakika gecikebilir · İzin
ver"). Kesin alarm izni yoksa uyarı yaklaşık modda zamanlanıyor.

Doğrulama:

```bash
# izinler, release derlemesinden sonra (yukarıdaki beş izin + androidx'in
# uygulamaya özel iç izni; INTERNET yok)
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

## Doğrulama

```bash
flutter analyze   # temiz
flutter test      # 50 test
```

| Dosya | Ne sınanıyor | Test |
|---|---|---|
| `kurallar_test.dart` | Her eylem (başlat, duraklat, devam, +1 dk, bitir, atla), geçersiz eylemin durumu değiştirmemesi, 4 çalışma → uzun mola → sayaç 0, ayar sınırları | 14 |
| `ilerlet_test.dart` | Bitişten önce değişmeme, bitişte tamamlanma, molanın sayılmaması, gece yarısı, saatlerce kapalı kalınca tek faz | 8 |
| `pomodoro_kontrol_test.dart` | Açılışta alarm → zil, sessizde zil yok, Durdur ve Sıradakini başlat, izinlerin bir kez sorulması ve bantlar, sürükleme | 8 |
| `sayac_ekrani_test.dart` | Başlat → duraklat, izin bandı, sahte saatle geri sayım, dolgu %100'de noktaların görünmesi, alarm ekranı, "animasyonları kaldır", nefes | 7 |
| `bildirim_metinleri_test.dart` | Başlıklar, `2/4`, `Bitiş HH:mm`, `Kalan mm:ss`, "süre doldu" metni, saat dilimi | 6 |
| `eylem_calistir_test.dart` | Panel butonu: kayıt + panelin eşitlenmesi, bilinmeyen eylemin hiçbir şey yapmaması | 4 |
| `durum_json_test.dart` | Kaydedip okuma, bozuk ve eksik kayıt | 3 |

Saat dışarıdan veriliyor (`Saat` fonksiyonu); testte sahte saat ilerletilerek
25 dakika saniyeler içinde geçiyor. Bildirim, kayıt ve zil sahte sürümlerle
değiştirilebiliyor. Paneli, izin pencerelerini ve kilit ekranını testler
göremiyor; onları gerçek telefonda (Samsung, Android 16) denedim.

## Paketler

`flutter_local_notifications` · `timezone` · `shared_preferences`

Durum yönetimi `ChangeNotifier`, animasyonlar Flutter'ın kendi araçlarıyla.
Yazı tipleri (Space Grotesk, Inter) dosya olarak gömülü (`assets/fonts/`, OFL
lisansları yanında).

## Bilinen sınırlar

- Telefon yeniden başlarsa "süre doldu" zamanlaması geri kuruluyor, ama
  paneldeki sayaç bildirimi uygulama açılana kadar gelmiyor.
- **Canlı Güncelleme** (Android 16'nın durum çubuğu çipi) denendi; Samsung
  One UI bu sürümde göstermediği için eklenmedi.
- İstatistik, geçmiş, görev listesi ve ana ekran widget'ı yok.
- iOS derlemesi yok.
