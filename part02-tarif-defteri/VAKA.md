# Tarif Defteri
### Part 02 · Her Hafta 1 Uygulama

Annemin el yazısı tarif defterini telefona taşıyan, tamamen çevrimdışı çalışan
bir Android uygulaması. Tek bir kişinin, tek bir telefonda kullanması için
yapıldı.

**Kod:** [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1/tree/main/part02-tarif-defteri) · **Yığın:** Flutter, Drift, wakelock_plus, share_plus

![Ana ekran](screenshots/01-ana-ekran.png)
![Tarif okuma](screenshots/03-tarif.png)
![Adım adım pişirme](screenshots/04-adim-adim.png)

---

## 01 — Ne yaptım

Kategoriyi seçiyorsun veya arıyorsun, tarifi açıyorsun, malzemeleri tek tek
tikliyorsun, sonra adım adım pişiriyorsun. Tarif ekleme ve düzenleme uygulamanın
içinde; tarifler telefonda duruyor, yedek tek bir JSON dosyası olarak dışarı
aktarılabiliyor.

Altı ekran, hesap yok, internet yok.

---

## 02 — Neyi YAPMADIM

- Fotoğraf
- Bulut yedekleme ve senkronizasyon
- Hesap sistemi
- Tarif paylaşma
- Alışveriş listesi
- Mutfak zamanlayıcısı
- Porsiyon hesaplama
- iOS

Bu uygulamanın kullanıcısı bir kişi ve o kişiyi tanıyorum. Yukarıdaki
maddelerin hiçbirini istemiyor. Fotoğraf en çok istenen özellik gibi görünüyor
ama tarifleri ben elle geçiriyorum — fotoğraf, benim iş yüküm ve onun telefon
depolaması demekti, karşılığında defterde zaten olmayan bir şey.

**Ekleme:** Bu uygulamada seri kurallarını bilerek esnettim. Diğer haftalarda
öncelik portföy; burada öncelik uygulamanın gerçekten kullanılması. Kapsamı
"neyi göstermek istiyorum" değil, "o ne kullanacak" belirledi.

---

## 03 — Bu hafta gösterdiğim teknik yetenek

**Türkçe'ye özgü metin normalizasyonu ve arama.**

Annem "çorba" yazmak zorunda kalmamalı; "corba" da aynı sonucu vermeli. Bunun
için tarif adı ve malzemeler, sadeleştirilmiş ayrı bir metin sütununda da
saklanıyor; arama orada yapılıyor.

Dart'ın hazır metotları bu işi tek başına yapamıyor, çünkü ikisi de Türkçe'de
yanlış sonuç veriyor:

| Girdi | Dart | Doğrusu |
|---|---|---|
| `'I'.toLowerCase()` | `'i'` | `'ı'` |
| `'İ'.toLowerCase()` | `'i'` + U+0307 (iki kod birimi) | `'i'` |
| `'tarifin'.toUpperCase()` | `'TARIFIN'` | `'TARİFİN'` |

İkinci satır sinsi olanı: sonuç ekranda "i" gibi görünür ama arkasında görünmez
bir birleşen nokta taşır, bu yüzden `'i'` ile karşılaştırıldığında eşleşmez.
Arama çalışıyor görünür, bazı tarifler hiç bulunamaz — ve bu, kullanıcının asla
bildirmeyeceği türden bir hatadır, çünkü "yok" ile "bulunamadı" ekranda aynı
görünür.

Çözüm, harfleri `toLowerCase()` çağrılmadan **önce** elle eşlemek. Üçüncü satır
aynı hatanın tersi ve arayüzde görünen hâli — düzeltilmeden önce ekranda
"TARIFIN ADI" yazıyordu.

→ [lib/domain/turkish_text.dart](lib/domain/turkish_text.dart)
→ [test/domain/turkish_text_test.dart](test/domain/turkish_text_test.dart)

---

## 04 — Aldığım karar

**Gerçek tarifler public bir depoya nasıl girmez?**

Bu uygulamanın en önemli kararı kod mimarisinde değil, deponun içeriğinde.
Kod açık olacak, ama annemin tarifleri aile malı — GitHub'a girmemeli.

Akla ilk gelen çözüm, tarifleri koda gömüp depoyu özel yapmak. O zaman da
serinin amacı gidiyor: kimse kodu göremiyor.

Seçtiğim yol, veriyi iki dosyaya ayırmak:

```
depo (public)                             telefon
├─ lib/                    kod           ├─ uygulama veritabanı
├─ assets/demo_recipes.json  uydurma  ←──┤ ilk açılışta yüklenir
└─ assets/recipes.json     .gitignore ───┘ (yalnızca benim derlememde)
```

Uygulama açılışta önce `assets/recipes.json` dosyasına bakar, yoksa
`demo_recipes.json` yüklenir. Kod ikisini de aynı şekilde okur; gizlilik kod
akışıyla değil, **hangi dosyanın depoya girdiğiyle** sağlanıyor. Depodaki ekran
görüntüleri de uydurma demo tariflerle çekildi.

Bir ayrıntı: dosya adı `pubspec.yaml`'da tek tek yazılsaydı, dosya yokken
derleme hata verirdi. Bu yüzden `assets/` klasörünün tamamı veriliyor — var olan
paketleniyor, olmayan sorun çıkarmıyor.

→ [lib/data/seed_loader.dart](lib/data/seed_loader.dart)

**İkinci karar: malzemeler neden ayrı tabloda değil?** Malzemeler yalnızca kendi
tarifiyle birlikte okunuyor, tek başına sorgulanmıyor ve sıralı bir liste. Ayrı
tablo her tarif açılışında bir birleştirme ve bir sıra sütunu getirir,
karşılığında hiçbir şey kazandırmazdı. Tek metin sütunu + `TypeConverter`
yeterli.

**Üçüncü karar: neden FTS5 değil?** Defterde birkaç yüz tarif var.
Sadeleştirilmiş sütun üzerinde `LIKE` bu boyutta anında sonuç veriyor; tam metin
arama indeksi kurmanın karşılığı yok.

**Dördüncü karar: neden Riverpod/Provider yok?** Paylaşılan şey iki nesne (depo
ve ayarlar) ve altı ekran. `InheritedWidget` yetiyor. Part 01'de de durum
buydu — aynı gerekçe, aynı sonuç.

---

## 05 — Nasıl doğruladım

34 birim testi: Türkçe metin dönüşümleri, yedek dosyasının okunup yazılması,
arama, silme ve geri alma, ilk yükleme davranışı. `flutter analyze` temiz.

Sonra uygulamayı emülatörde elle gezdim ve **testlerin yakalamadığı iki hata**
oradan çıktı:

- Ekranda "TARIFIN ADI" yazıyordu — yukarıdaki `toUpperCase()` hatası. Test
  yazdığım fonksiyon doğruydu, arayüzde çağrılan Dart'ın kendi metoduydu.
- Ana ekrandaki favori şeridi hiç çizilmiyordu: `Row`, dikey listenin içinde
  ölçüsüz kalıp kartları çizmiyor, iki bölüm başlığı üst üste biniyordu.

İkisi de "mantık doğru, ekran yanlış" kategorisinde. Birim testi bu kategoriyi
görmez; gözle bakmanın yerini tutan bir test yok.

---

## 06 — Ne öğrendim

**Yerelleştirme, dili çevirmekten ibaret değil.** Part 01'de `toUpperCase()`'in
Türkçe'de bozulduğunu görmüştüm. Bu hafta aynı sorunun `toLowerCase()`
tarafını da yaşadım — ve ikisi simetrik değil: küçük harfe çevirmedeki hata
ekranda görünmüyor, sessizce arama sonuçlarını bozuyor.

**Kullanıcıyı tanımak kapsamı küçültüyor.** Bilmediğim bir kitle için
yazsaydım fotoğraf, etiket, porsiyon hesabı eklemek zorunda hissederdim.
Kullanıcının kim olduğunu bilince özellik listesi kısaldı, uygulama bitti.

**Erişilebilirlik bir onay kutusu değil, tasarım kısıtı.** El yazısı font
başlıkta güzel, üç satırlık pişirme talimatında okunmuyor. Yazı boyutu ayarı
telefonun sistem ayarını bilerek yok sayıyor — sistem yazısı küçük olabilir ama
tarif okurken büyük olmalı. Tarif açıkken ekran kapanmıyor, çünkü eller
hamurlu. Bunların hiçbiri sonradan eklenebilecek şeyler değildi.

---

Bu, her hafta bir mobil uygulama bitirdiğim serinin 2. uygulaması.
Diğerleri: [github.com/MRGNSs11/weekly-flutter-apps-1](https://github.com/MRGNSs11/weekly-flutter-apps-1)
