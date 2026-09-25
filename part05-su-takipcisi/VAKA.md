# Su Takipçisi
### Part 05 · Her Hafta 1 Uygulama

Gün içinde su içmeyi unutan biri için, "kaydetmek için uygulamayı açmaya
üşenme" problemini çözen bir Android uygulaması. Asıl işi ana ekrandaki widget
yapıyor: "+1"e basınca uygulama açılmadan bir bardak ekleniyor.

**Kod:** [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1/tree/main/part05-su-takipcisi) · **Yığın:** Flutter, Kotlin, Jetpack Glance, home_widget, sensors_plus

![Ana ekran](screenshots/01-ana-ekran.png)
![Widget](screenshots/04-widget.png)

---

## 01 — Ne yaptım

Ekranın kendisi bir bardak. Su içtikçe su yükseliyor. "+1"e basınca yukarıdan
bir damla düşüyor, suya değdiği anda sıçrıyor ve ses çıkarıyor. Telefonu
eğince su da eğiliyor. Ana ekrandaki widget aynı sayıyı gösteriyor ve
uygulamayı açmadan sayabiliyor. Sayı her gece sıfırlanıyor.

## 02 — Neyi YAPMADIM

- Geçmiş, grafik, istatistik
- Hatırlatma bildirimi
- Adım sayacı (ayrı bir sensör, izin ve arka plan servisi ister)
- iOS widget'ı (Windows'ta geliştirilemiyor)
- Widget'ta canlı dalga (Android widget'ı canlı çizim yapamıyor)

Uygulamanın tek işi bugünü saymak. Geçmişi göstermeye başladığım an veritabanı,
grafik ve boş durum ekranları geliyordu; hepsi başka bir uygulamanın işi.

## 03 — Bu hafta gösterdiğim teknik yetenek

**Android ana ekran widget'ı ve Flutter ile Kotlin'in aynı veriyi paylaşması.**
Widget Kotlin'de, Jetpack Glance ile yazıldı (Glance: widget'ları Compose
tarzında, az kodla yazmayı sağlayan Android kütüphanesi). Flutter tarafı ile
widget aynı ayar dosyasını aynı anahtarlarla okuyup yazıyor:
[`SuWidget.kt`](android/app/src/main/kotlin/com/omergunes/su_takipcisi/SuWidget.kt) ve
[`su_deposu.dart`](lib/su/su_deposu.dart).

Yanında dört ilk daha: kendi platform kanalım (Flutter'dan Kotlin'e "ses çal"
çağrısı), dokunulan yerde suyu büken bir GPU shader'ı
([`halka.frag`](shaders/halka.frag)), ivmeölçerle eğilen su ve matematikle
ürettiğim damla sesleri.

## 04 — Aldığım karar

**Neden widget'taki "+1" Dart'ta değil de Kotlin'de sayılıyor?**

İlk sürümde Dart'taydı. `home_widget` paketi widget'a dokununca arka planda bir
Flutter motoru başlatıp Dart kodumu çalıştırıyordu. Tek dil, tek mantık;
kâğıt üstünde doğru görünüyordu.

Telefonda "+1" ara ara kayboldu. Paketin kodunu satır satır okudum. Arka plan
işi motoru başlatıp Dart'ın bitmesini beklemeden "tamamlandı" diyordu. Motorun
açılması 1–3 saniye sürüyor; Android bu arada işlemi kapatırsa dokunuş
kayboluyordu.

Şimdi dokunuş doğrudan Kotlin'de işleniyor: bir artır, diske yaz, widget'ı
yeniden çiz. Sayı anında değişiyor, kaybolmuyor. Bir yan kazanç da oldu: artık
gerekmeyen, korumasız, dışa açık bir bileşen kalktı.

Bedeli, "gece yarısı sıfırla" kuralının iki dilde durması. Bunu iki tarafın
aynı anahtarları ve aynı tarih biçimini kullanmasıyla, README'de bir tabloyla
yönetiyorum. Bir sayıyı artırmak için bir Flutter motoru uyandırmak, yanlış
araçtı.

## 05 — Nasıl doğruladım

25 birim testi, hepsi saf mantıkta: gece yarısı sıfırlama, geri alma sınırı,
su fiziği (damla çarpınca tek halka; 60 ve 120 Hz'de aynı sonuç), eğim hesabı.

Kotlin widget'ı, shader ve ses cihaza bağlı olduğu için testli değil. Onları
gerçek telefonda elle denedim: uygulama zorla durdurulmuşken art arda beş
"+1", tarihi ertesi güne alıp sıfırlama, eğim yönü. İki hatayı yalnız
telefon gösterdi. Biri yukarıdaki kaybolan dokunuş, diğeri release
derlemesinde R8'in (kod küçültücü) Glance'in adından bulduğu bir sınıfın
kurucusunu silmesi.

## 06 — Ne öğrendim

Bir paketin arka plan özelliğini kullanmadan önce "iş ne zaman bitmiş
sayılıyor" sorusunu sormak gerekiyor. Paket çalışıyor, ama "çalışıyor" ile
"her seferinde çalışıyor" arasındaki fark, ancak zorla durdurulmuş bir
uygulamada ortaya çıktı.

Bir de: release derlemesinde tek izin var, `WAKE_LOCK`. Kaldırmak istedim ama
kaldıramadım, çünkü Glance widget'ı çizmek için onu kullanıyor. Bir izni
kaldırmadan önce kimin kullandığını bulmak gerekiyor.

---
Bu, her hafta bir mobil uygulama bitirdiğim serinin 5. uygulaması.
Diğerleri: [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1)
