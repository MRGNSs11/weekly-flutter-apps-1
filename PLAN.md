# Part 01 — Alışkanlık Takipçisi (ısı haritalı)

> `herhafta1\PLAN_REHBERI.md` şablonuna göre dolduruldu.
> Doldurma tarihi: 2026-08-25 · Hedef hafta sonu: 29-30 Ağustos 2026

---

## BÖLÜM A — Fikir onayı

**A1. Tek cümle:** Bu uygulama *alışkanlık edinmeye çalışan biri* için
*"kaç gündür üst üste yapıyorum?" sorusunu tek bakışta görememe* problemini çözer.

**A2. Gösterilecek teknik yetenek (TEK):**
**Yerel veritabanı (Drift) + CustomPainter ile özel çizim.**
Seride ilk kez gösteriliyor. Sonraki haftalarda tekrar edilmeyecek.

**A3. Vitrin Karnesi — 5/5**
- [x] **Yeni yetenek** — Drift + CustomPainter, seride ilk
- [x] **Görsel an var** — yıllık ısı haritası ekranda çiziliyor
- [x] **Anlatılacak karar var** — "Neden Hive değil Drift?"
- [x] **Backend yok** — tamamen çevrimdışı, API yok
- [x] **48 saatte biter** — izin/kamera/servis yok, platform riski sıfır

**A4. Hafta numarası ve başlık:** Part 01 — "Alışkanlık Takipçisi"

**A5. Anlatım açısı:**
> "Bir yıllık veriyi 365 kutuya çizerken ListView kullanırsan uygulama takılır.
> CustomPainter ile tek seferde çizince akıcı oluyor. Neden?"

Yan hikâye: *"Bu kadar basit bir uygulamada neden Hive değil de Drift seçtim?"*
→ Cevap: streak hesabı bir tarih aralığı sorgusu. Hive'da tüm kayıtları belleğe
alıp Dart'ta filtrelemek gerekir; Drift'te tek SQL sorgusu. Veri büyüdükçe fark açılır.

---

## BÖLÜM B — Çekirdek (DONDURULDU)

**B1. ÇEKİRDEK AKIŞ:**
Alışkanlık ekle → günü işaretle → ısı haritasında seriyi gör

**B2. Platform / stil:** Flutter, Android öncelik
Görsel stil: **05 — Organik / Toprak** (Ömer seçti, 2026-08-25)

> Seçilen taslak SPESİFİKASYONDUR. `tasarimlar.html` içindeki `.organik` bloğu
> birebir uygulanır. Aşağıdaki tablo o CSS'ten çıkarıldı.

### B2.1 — Renk tokenları (`.organik` CSS'inden birebir)

| Token | Değer | Nerede |
|---|---|---|
| `bg` | `#F5F3EC` | Ekran zemini |
| `surface` | `#FFFEFA` | Kart, satır, istatistik kutusu, harita kartı |
| `text` | `#2B3226` | Başlık ve satır adı |
| `muted` | `#8D9483` | Tarih, alt metin, etiket, ay isimleri |
| `accent` | `#5C8A4A` | İşaret dolgusu, FAB, istatistik sayısı, seri çubukları |
| `onAccent` | `#FFFFFF` | Accent üstündeki ✓ ve + |
| `border` | `#E6E5DA` | 1px kart çerçevesi |
| `sparkOff` | `#E4E6DC` | Seri çubuğunun boş hali |

**Isı haritası 5 seviye:**
`L0 #E7E8DE` · `L1 #C8DCBC` · `L2 #96BD83` · `L3 #5C8A4A` · `L4 #37592C`

### B2.2 — Tipografi

| Rol | Spec |
|---|---|
| Ekran başlığı (h1) | **Serif**, w600, 25px, satır 1.2, harf aralığı −0.02em |
| İstatistik sayısı | **Serif**, w600, 26px, satır 1.15, harf aralığı −0.03em, renk `accent` |
| Satır adı | **Sans**, w500, 15px, satır 1.3, harf aralığı −0.01em |
| Satır alt metni | Sans, w400, 11.5px, renk `muted` |
| Tarih üst yazısı | Sans, 11.5px, BÜYÜK HARF, harf aralığı +0.09em, renk `muted` |
| İstatistik etiketi | Sans, 10px, BÜYÜK HARF, harf aralığı +0.05em, renk `muted` |
| Kart başlığı (h4) | Sans, 11px, BÜYÜK HARF, harf aralığı +0.08em, renk `muted` |
| Ay etiketleri / açıklama | Sans, 9.5px, renk `muted` |

### B2.3 — Ölçü ve biçim

| Öğe | Spec |
|---|---|
| Kart köşe yarıçapı | 14 |
| Kart çerçevesi | 1px `border` |
| Satırlar arası boşluk | 9 |
| Satır iç boşluğu | dikey 14, yatay 15 |
| Yatay ekran kenar boşluğu | 18 |
| İşaret kutusu | 26×26, **tam yuvarlak**, 2px `accent` çerçeve; işaretliyken dolu + beyaz ✓ |
| Seri çubukları | 7 adet, 5×15, köşe 1.5, dolu `accent` / boş `sparkOff` |
| FAB | 54×54 tam yuvarlak, `accent`, `+` 25px w300, gölge `rgba(92,138,74,.32)` 0/7/20 |
| Renk noktası (detay başlığı) | 11×11, köşe **3** (yuvarlak değil) |
| Isı haritası hücresi | 8×8, **tam yuvarlak**, aralarında 2 boşluk |
| İstatistik kartı | 3 eşit sütun, aralarında 9, ortalanmış metin |

### B2.4 — Taslaktan sapmalar (kod yazmadan ÖNCE bildirilir)

Üç noktada taslağı birebir uygulayamıyorum. Gerekçeler:

1. **Serif yazı tipi.** Taslakta `Iowan Old Style / Georgia` var — ikisi de
   Android'de YOK. Android'in kendi serif'i (Noto Serif) taslaktaki sıcak,
   eski-stil karakteri vermiyor.
   → **Çözüm:** `Lora` (Google Fonts, açık lisans) TTF olarak `assets/fonts/`
   içine gömülecek. Paket eklenmiyor, sadece 2 dosya (Regular + SemiBold).
   Lora eski-stil serif ailesinden, Iowan'a en yakın ücretsiz karşılık.

2. **Isı haritası 6 ay gösteriyor, Must listesi "yıllık" diyor.**
   Taslakta ekrana 26 hafta sığmış. Bir yıl (53 hafta) 300px'e sığmaz.
   → **Çözüm:** Harita yatay kaydırılabilir olacak, açılışta **son 6 ay**
   görünecek (taslaktaki hal), sola kaydırınca 1 yıl geriye gidiyor.
   Görsel olarak taslakla birebir aynı, sadece kaydırma ekleniyor.

3. **Ay etiketleri.** Taslakta 6 etiket eşit aralıklı (40px). Gerçekte aylar
   4-5 hafta arası değişiyor, etiketler eşit aralıklı olmayacak.
   → **Çözüm:** Her ay etiketi, o ayın başladığı haftanın üstüne hizalanacak.
   Taslaktan tek farkı budur; alternatifi tarihleri yanlış göstermek olurdu.

Bunlar dışında taslak birebir uygulanacak.

**B3. Ekran listesi (3):**
1. **Alışkanlık listesi** — bugünün işaretleme ekranı, her satırda mini seri göstergesi
2. **Alışkanlık detayı** — yıllık ısı haritası + mevcut seri + en uzun seri + toplam
3. **Ekle / düzenle** — isim, renk, ikon seçimi

**B4. Paket listesi (2 dış paket):**
- `drift` (+ `drift_flutter`, `sqlite3_flutter_libs`) — yerel veritabanı
- `path_provider` — veritabanı dosya yolu

Geliştirme bağımlılıkları: `drift_dev`, `build_runner`, `flutter_lints`

> Isı haritası **paket kullanmadan**, elle `CustomPainter` ile çizilecek.
> Hazır takvim paketi kullanmak A2'deki yeteneği gösterme amacını yok eder.

---

## BÖLÜM C — Özellik listesi (MoSCoW)

| Özellik | Etiket | Efor |
|---|---|---|
| Alışkanlık ekle / sil | **Must** | S |
| Bugünü işaretle / işareti kaldır | **Must** | S |
| Mevcut seri + en uzun seri hesabı | **Must** | M |
| Yıllık ısı haritası (CustomPainter) | **Must** | M |
| Yerel kalıcılık (Drift) | **Must** | M |
| Geçmiş bir günü işaretleme (haritaya dokunarak) | **Must** | S |
| Alışkanlık rengi seçimi | **Must** | S |
| Alışkanlık düzenleme | Should | S |
| Boş durum / ilk açılış ekranı | **Must** | S |
| Bildirim / hatırlatıcı | **Won't** | — |
| Haftalık hedef ("haftada 3 gün") | **Won't** | — |
| Kategori / etiket | **Won't** | — |
| İstatistik grafikleri | **Won't** | — |
| Bulut senkron / hesap | **Won't** | — |
| Ana ekran widget'ı | **Won't** | — |
| Açık/koyu tema seçici | **Won't** | — |
| Veri dışa aktarma | **Won't** | — |

**L efor yok.** Tüm Must'lar S veya M.

---

## BÖLÜM D — 48 saatlik plan

| Zaman | İş |
|---|---|
| **Cuma akşamı** | Bu belge + tasarım seçimi. Kapsam DONDU. Repo açıldı. |
| **Cmt 10:00-13:00** | Adım 1: proje kurulumu, Drift şema, repository, birim testler |
| **Cmt 14:00-18:00** | Adım 2: tasarım sistemi + alışkanlık listesi ekranı |
| **Cmt akşamı** | *Ara kontrol:* alışkanlık eklenip işaretlenebiliyor mu? |
| **Paz 10:00-14:00** | Adım 3: detay ekranı + ısı haritası + streak |
| **Paz 14:00-16:00** | Adım 4: ekle/düzenle + cilalama + README + ekran görüntüleri |
| **Paz 16:00-18:00** | Video / LinkedIn gönderisi |
| **Paz akşamı** | Yayın. Bitti. |

**D1. Teknik risk:**
- `drift` kod üretimi (`build_runner`) ilk kurulumda takılabilir → **Cuma akşamı
  15 dakikada boş bir projede doğrulanacak.** Cumartesi öğrenilmeyecek.
- CustomPainter'da 365 kutunun düzeni (hafta sütunları, ay etiketleri) ilk denemede
  tutmayabilir → grid matematiği ayrı bir saf fonksiyonda, birim testli.

**D2. Cumartesi akşamı kararı:** ☐ Yolunda ☐ Kapsam kesildi → kesilen: _______

---

## BÖLÜM E — Teknoloji ve araç ayarı

### Dil / çatı
- **Flutter** (stable), **Dart**
- Android öncelik; iOS derlenir ama test edilmez

### Durum yönetimi
**Kararı: `ValueNotifier` + `ListenableBuilder` (Flutter'ın kendi araçları).**
Riverpod/Provider **kullanılmayacak.** Gerekçe: 3 ekranlık bir uygulamada dış
paket eklemek gereksiz; Flutter'ın yerleşik araçlarını bildiğini göstermek
daha değerli. Bu da videoda anlatılacak bir karar.

> Not: İşverenlerin Riverpod aradığı doğru — ama o, seride başka bir haftanın
> A2 yeteneği olacak. Aynı şeyi iki kez göstermiyoruz.

### Veri
- **Drift** — SQLite üzerine tip güvenli sorgular
- İki tablo: `habits` (id, ad, renk, oluşturma tarihi) ve
  `completions` (habitId, tarih) — tarih `DateTime` değil **gün anahtarı (int)**
  olarak tutulacak: `yyyymmdd`. Saat dilimi ve yaz saati hatalarını baştan keser.

### Test
- Sadece **saf mantık** birim testleri (widget testi yok, vakit yetmez):
  - streak hesabı (boş, tek gün, kesintili, bugün dahil/hariç)
  - ısı haritası grid yerleşimi (hangi gün hangi satır-sütuna düşüyor)
  - gün anahtarı dönüşümleri
- Hedef: ~15 test. README'de test sayısı gösterilecek.

### Kod kalitesi
- `flutter analyze` temiz olacak
- `dart format` uygulanacak
- Klasör yapısı:
  ```
  lib/
    data/        # drift şema, veritabanı, repository
    domain/      # streak hesabı, grid mantığı (saf Dart, testli)
    ui/
      theme/     # seçilen tasarımın renk + tipografi tokenları
      screens/
      widgets/   # heatmap painter, habit card
    main.dart
  ```

### Claude Code araç kutusu (bu proje için)
| Araç | Durum | Neden |
|---|---|---|
| **dart MCP** (`analyze_files`, `hot_reload`, `pub`) | **Açık** | Her adım sonunda analyze + hot reload |
| **context7** | **Açık** | Drift API'si sık değişiyor, güncel doküman şart |
| **frontend-design** skill | **Açık** | Tasarım taslakları ve tema tokenları |
| firebase / serena / semgrep | **Kapalı** | Backend yok, proje küçük, hassas veri yok |
| github MCP | **Kapalı** | Repo açılınca değerlendirilir |

### Yayın
- GitHub public: `haftalik-01-aliskanlik-takipcisi` (MIT lisans)
- LinkedIn gönderisi: Part 01
- Video: opsiyonel

---

## BÖLÜM F — Kodlama adımları (abonelik limiti için bölünmüş)

Ömer'in isteği: 4 adım. Her adım kendi başına çalışır durumda bitiyor.

| Adım | İçerik | Biterken elde ne var |
|---|---|---|
| **1** | Proje kurulumu, Drift şema + repository, saf mantık (streak + grid) **ve testleri** | Arayüz yok ama tüm mantık çalışıyor ve testli |
| **2** | Tasarım sistemi (seçilen taslaktan tema tokenları) + alışkanlık listesi ekranı + ekle/sil | Uygulama açılıyor, alışkanlık eklenip işaretlenebiliyor |
| **3** | Detay ekranı + ısı haritası (CustomPainter) + streak göstergeleri + geçmiş gün işaretleme | Çekirdek akış tamamlandı, uygulama "bitmiş" görünüyor |
| **4** | Ekle/düzenle ekranı cilası, boş durumlar, animasyon, README + ekran görüntüleri | Yayına hazır |

**Her adım sonunda:** `dart format` → `flutter analyze` → `flutter test`
**Adım aralarında:** Ömer onaylar, sonra devam edilir.

---

## Bu haftanın notları
- 2026-08-25: Tasarım seçildi → **05 Organik / Toprak**. Spec B2'ye işlendi.
- Taslaktan 3 sapma bildirildi (serif font, harita kaydırma, ay etiketleri) → bkz. B2.4
- `assets/fonts/Lora-Regular.ttf` + `Lora-SemiBold.ttf` indirilecek (Adım 2'de)
- **2026-08-25 — Adım 1 BİTTİ:** proje kuruldu, Drift şeması (habits+completions),
  repository, saf mantık (streak.dart + heatmap_grid.dart) ve 25 birim testi
  yazıldı. `flutter analyze` temiz, tüm testler yeşil.
  - Karar: `sqlite3_flutter_libs` eklenmedi — Drift 2.32+ SQLite'ı otomatik
    gömüyor, paket artık EOL (kullanımdan kaldırılmış).
  - Karar: ısı haritası 5 seviyesi, o günü kapsayan serinin o anki uzunluğuna
    göre koyulaşıyor (1-2/3-6/7-13/14+ gün). Tek alışkanlık günlük olarak
    ikili (yapıldı/yapılmadı) olduğu için 5 seviyeye anlam katmanın yolu buydu.
    Bu, videoda anlatılacak ikinci karar oldu (Hive/Drift'in yanına).
- **2026-08-25 — Adım 2 BİTTİ:** Lora fontu (variable font olarak indirildi,
  Google Fonts artık Lora'yı statik değil tek `.ttf` variable dosya olarak
  dağıtıyor), tema tokenları (`app_theme.dart`), `main.dart`, alışkanlık
  listesi ekranı (tarih başlığı + satırlar + FAB + boş durum), ekle/düzenle
  ekranı (isim + 8 renkli palet + sil). `flutter analyze` temiz, 25 test yeşil.
  - Karar: satır tıklaması şimdilik Ekle/Düzenle ekranını açıyor (detay ekranı
    henüz yok). **Adım 3'te bu davranış değişecek:** satır tıklaması Detay
    ekranına gidecek, düzenleme oraya taşınan bir kalem ikonundan erişilecek.
  - Karar: Türkçe büyük harf dönüşümü (`toUpperCase()`) 'i' harfini yanlış
    çeviriyor (noktasız I yapıyor) — `turkish_date.dart`'ta elle düzeltildi.
  - Doğrulama: `sqlite3_flutter_libs` yokken Drift'in native platformlarda
    (Windows/Android) çalıştığını görmek için canlı çalıştırma denendi.
    Windows masaüstü, Visual Studio C++ araçları kurulu olmadığı için
    derlenemedi (proje hedefi zaten Android — bu eksik önemsiz). Android
    emülatörü (novastore_test, başka bir projeden kalma) başlatılıp üzerinde
    doğrulandı.
- **2026-08-25 — Adım 3 BİTTİ:** Detay ekranı (renk noktası + isim + düzenle
  kalemi + 3 istatistik kartı + ısı haritası kartı), `HeatmapView`
  (`CustomPainter`, yatay kaydırılabilir, 1 yıllık pencere açılışta son 6 aya
  kaydırılmış), `repository.watchHabit()` (düzenleme/silme sonrası detay
  ekranını canlı tutuyor). Çekirdek akış artık uçtan uca tamam: ekle →
  işaretle → detayda seri + ısı haritasını gör → geçmiş güne haritadan
  dokunup işaretle. `flutter analyze` temiz, 25 test yeşil.
  - Karar (önceden bildirilmişti, şimdi uygulandı): satır tıklaması artık
    Detay ekranına gidiyor, düzenleme oradaki kalem ikonundan.
  - Karar: ısı haritası kartı başlığı taslaktaki sabit "Son 6 ay" yerine
    "SON 1 YIL" oldu — harita artık kaydırılabilir 1 yıllık bir pencere
    olduğu için (sapma #2'nin doğal sonucu), sabit "6 ay" etiketi yanıltıcı
    olurdu.
