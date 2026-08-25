# LinkedIn gönderi taslağı — Part 01

> PLAN.md § Bölüm F formatına göre: problem → ne yaptım → ne öğrendim → repo linki.
> Bu bir taslak — gerçek paylaşım Ömer'in kararı. Repo linkini GitHub'a
> yükledikten sonra doldur.

---

**"Her hafta 1 uygulama" — Part 1: Alışkanlık Takipçisi 🌱**

Mezuniyete kadar her hafta sonu (48 saat), CV'me eklemek için küçük bir
Flutter uygulaması bitiriyorum. İlki: GitHub'ın katkı grafiğine benzer bir
ısı haritasıyla alışkanlık serilerini gösteren bir uygulama.

Ne öğrendim: Bu kadar küçük bir uygulamada bile "hangi yerel veritabanı"
kararı önemli. Hive gibi bir key-value deposuyla başlayabilirdim ama
"kaç gündür üst üste yapıyorum" sorusu aslında bir tarih aralığı sorgusu —
Drift (SQLite) ile bu tek bir SQL sorgusu, Hive'da tüm kayıtları belleğe
çekip Dart'ta filtrelemek gerekirdi.

Isı haritasını da hazır bir paket yerine `CustomPainter` ile elle çizdim —
365 günü widget ağacıyla çizmeye çalışsam performans düşerdi, tek bir
Canvas'a çizince akıcı kalıyor.

Kapsamı bilerek dar tuttum: bildirim yok, senkron yok, sadece çekirdek akış
— ekle, işaretle, seriyi gör. 48 saatte bitirilebilecek kadarı.

Kod: [repo linki buraya]

#Flutter #Dart #100DaysOfCode #Portfolio

---

## Notlar

- Repo public yapılıp GitHub'a yüklendikten sonra `[repo linki buraya]` doldurulacak.
- Ekran görüntüsü/video eklenirse (`screenshots/liste.png` veya kısa bir
  ekran kaydı) gönderinin etkileşimi artar.
- Format her hafta aynı kalacak — seri olduğu anlaşılsın diye (bkz.
  `PLAN_REHBERI.md` § Bölüm F).
