# Pomodoro
### Part 09 · Her Hafta 1 Uygulama

Odaklanmak isteyen biri için, telefon cebindeyken de doğru zamanda uyaran bir
pomodoro sayacı.

**Kod:** [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1/tree/main/part09-pomodoro) · **Yığın:** Flutter, flutter_local_notifications, shared_preferences, CustomPainter

---

## 01 — Ne yaptım

Başlat'a basıp telefonu cebine koyuyorsun. Panelde sayaç akıyor; oradan
duraklatıp bir dakika ekleyebiliyorsun. Süre dolunca telefon kilitliyse ekran
açılıyor, alarm sen durdurana kadar çalıyor. Ekranda çalışma sürdükçe ekran
alttan lacivertle doluyor, molada yeşille dolu başlayıp boşalıyor.

## 02 — Neyi YAPMADIM

- İstatistik ve geçmiş ekranı
- Görev listesi
- Ana ekran widget'ı
- Ön plan servisi
- Özel alarm sesi
- iOS

Bu hafta gösterilecek şey bildirimdi. İstatistik ve görev listesi başka bir
uygulamanın konusu; eklesem asıl işi gölgede bırakırdı.

## 03 — Bu hafta gösterdiğim teknik yetenek

**Yerel bildirim.** Seride ilk kez bildirim paneli ana yetenek. Panelde
Android'in kendi kronometresiyle akan geri sayım, uygulama kapalıyken ayrı bir
isolate'te (arka planda kısa süre çalışan ayrı bir Dart ortamı) çalışan
butonlar ve bitiş anına zamanlanmış bir alarm var. Panel adım adım
değiştirilmiyor: tek bir fonksiyon her seferinde durumdan baştan kuruyor
([`yerel_bildirim_servisi.dart`](lib/bildirim/yerel_bildirim_servisi.dart) →
`esitle`). Ekran da panel de aynı durumdan çiziliyor.

## 04 — Aldığım karar

**Neden ön plan servisi değil, kronometre?**

Klasik yol, sayaç sürerken arka planda bir servis çalıştırıp her saniye
bildirimi güncellemek. Bunun bedeli pil ve sürekli çalışan kod. Daha önemlisi,
Samsung gibi üreticiler arka plandaki uygulamaları kapatıyor; servis ölünce
sayaç da duruyor.

Ben sayacı hiç saymamayı seçtim. Uygulama yalnız bitiş anını kaydediyor.
Paneldeki saniyeleri Android ilerletiyor, "süre doldu" bildirimi de bitiş
anına zamanlanmış bekliyor. Uygulama tamamen kapansa da ikisi sistemde
yaşıyor. Uygulama açılınca durum bitiş anından yeniden hesaplanıyor
([`kurallar.dart`](lib/alan/kurallar.dart) → `ilerlet`): süre geçmişse faz o
an tamamlanıyor. Bedeli: panelde yalnız geri sayım var, canlı ilerleme çubuğu
yok.

## 05 — Nasıl doğruladım

50 test: kurallar (14), tamamlanma ve gece yarısı (8), kontrol katmanı ve
alarm (8), ekran ve animasyon (7), bildirim metinleri (6), panel butonları (4),
kayıt (3). Saat dışarıdan verildiği için testte sahte saat ilerletiliyor;
25 dakika saniyeler içinde geçiyor. Release derlemesinde internet izni yok.

Paneli, izin pencerelerini ve kilit ekranını testler göremiyor. Onları gerçek
telefonda (Samsung, Android 16) denedim.

## 06 — Ne öğrendim

**Bildirim sesi alarm değildir.** İlk sürümde süre dolunca kısa bir bildirim
sesi çalıyordu; telefonda fark edilmedi, panel açılınca da Android sesi
kesiyordu. Saat uygulamasının alarmı gibi çalışması için tam ekran bildirim,
alarm sesi ve uygulamanın kendi döngülü zili birlikte gerekti.

---
Bu, her hafta bir mobil uygulama bitirdiğim serinin 9. uygulaması.
Diğerleri: [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1)
