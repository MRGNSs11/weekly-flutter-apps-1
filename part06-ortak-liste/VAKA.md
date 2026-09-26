# Ortak Liste
### Part 06 · Her Hafta 1 Uygulama

Aynı evde yaşayan iki kişi için, "markete giden ne alacağını bilmiyor, liste
öbürünün telefonunda" problemini çözen bir Android uygulaması. Bir telefonda
yazılan ürün, öbüründe anında not olarak beliriyor.

**Kod:** [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1/tree/main/part06-ortak-liste) · **Yığın:** Flutter, Firebase Auth (anonim), Cloud Firestore, güvenlik kuralları

![Liste](screenshots/02-liste.png)
![İki cihaz aynı listede](screenshots/03-iki-cihaz.png)

---

## 01 — Ne yaptım

Liste bir buzdolabı kapısı. Her ürün krem bir not, tepesinde ürünün baş harfi
bir karo mıknatıs. Hesap açmak yok: listeyi açan 6 haneli bir kod görüyor,
öbürü o kodu yazıp katılıyor. Birinin eklediği not öbürünün ekranına yukarıdan
düşüyor. Alınan not soluyor, üstü çiziliyor, alta iniyor. İnternet yokken de
ekleniyor, bağlantı gelince eşitleniyor.

## 02 — Neyi YAPMADIM

- Google ile giriş (anonim giriş yetiyor, kurulumu yarım gün yerdi)
- Birden çok liste
- Paylaşım linki ya da QR ile katılma
- Bildirim
- Kaba kuvvete özel koruma (App Check) — README'de sınırlılık olarak yazılı

Uygulamanın tek işi iki telefonu aynı listede tutmak. Gerisi bu işi kanıtlamaktan
vakit çalardı.

## 03 — Bu hafta gösterdiğim teknik yetenek

**Firebase: anonim giriş, Firestore'da gerçek zamanlı veri ve güvenlik
kuralları.** Seride ilk kez bulut ve ilk kez birden çok kullanıcı var.
Firebase'e dokunan tek dosya
[`liste_deposu.dart`](lib/liste/liste_deposu.dart), veritabanını koruyan tek
dosya [`firestore.rules`](firestore.rules). Kuralları emülatörde (bilgisayarda
çalışan sahte Firestore) 21 testle sınadım.

## 04 — Aldığım karar

**Katılma kodunu neden istemci değil sunucu doğruluyor?**

İlk tasarım basitti: kodu yazan kişi `kodlar` koleksiyonundan listenin
kimliğini öğrenir, kendini üyelere ekler. Kural da "yalnız kendini
ekleyebilirsin" der. Kâğıt üstünde yeterli görünüyordu.

Ama bu tasarımda kodun kendisi hiç doğrulanmıyor. Kural yalnız "kendini mi
ekliyorsun" diye bakıyor. Liste kimliği bir yolla sızarsa, örneğin bir hata
mesajında ya da bir ekran görüntüsünde, kodu bilmeyen biri de katılabilir.

Şimdi katılma tek toplu yazma: kendini üyelere eklersin ve aynı anda bir
"katılım" belgesine kodu yazarsın. Kural, o belgedeki kodun listenin koduyla
aynı olup olmadığına bakıyor. Bunu test 6 kanıtlıyor: liste kimliğini bilen
ama kodu yanlış yazan kişi reddediliyor.

Bedeli, bir belge ve kuralda iki satır daha. Karşılığında "kodu bilmeyen
katılamaz" cümlesi bir umut olmaktan çıkıp kanıta dönüştü.

## 05 — Nasıl doğruladım

21 kural testi ve 19 birim testi. Kural testleri README'deki her güvenlik
cümlesine karşılık geliyor. Birim testleri saf mantıkta: kod üretme, Türkçe
baş harf, sıralama.

Sonra iki cihazda denedim: telefon ve emülatör. Oluştur, kodla katıl, iki
yönlü ekle, işaretle, sil, uçak modunda ekleyip bağlantı gelince eşitle. İki
hatayı yalnız telefon gösterdi. Ağ durumu iznini kaldırınca uygulama açılışta
çöktü. Yeni liste sunucu onaylamadan ekrana düştüğü için ürünler kurala
takıldı.

## 06 — Ne öğrendim

Firebase anahtarı gizli bir şey değil. Uygulamayı açan herkes görür. Güvenliği
anahtarı saklamak değil, kuralları yazmak ve test etmek sağlıyor.

Bir de: "gereksiz izni kaldırdım" demek için önce kaldırıp denemek gerekiyor.
`ACCESS_NETWORK_STATE`'i kaldırdım, uygulama açılmadı. İzin geri geldi,
gerekçesi manifest'e yazıldı. Bir iddiayı cihazda doğrulamadan yazmamak,
bu seride yine işe yaradı.

---
Bu, her hafta bir mobil uygulama bitirdiğim serinin 6. uygulaması.
Diğerleri: [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1)
