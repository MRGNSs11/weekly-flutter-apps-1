import 'package:home_widget/home_widget.dart';

import 'gunluk_durum.dart';

/// Uygulama ile widget'ın ortak deposu.
///
/// `home_widget` veriyi Android'in SharedPreferences dosyasına yazar;
/// Kotlin'deki widget aynı dosyadan aynı anahtarlarla okur; widget'taki
/// "+1" de Flutter'ı uyandırmadan doğrudan Kotlin'de yazar (`SuWidget.kt` →
/// `SuVerisi`). Anahtar adları ve türleri iki tarafta birebir aynı olmalı.
class SuDeposu {
  const SuDeposu._();

  static const widgetAlicisi = 'com.omergunes.su_takipcisi.SuWidgetReceiver';

  static const anahtarSayi = 'sayi';
  static const anahtarHedef = 'hedef';
  static const anahtarBardakMl = 'bardakMl';
  static const anahtarTarih = 'tarih';

  /// Kaydı okur ve bugüne göre düzeltir (gün değiştiyse sayı 0).
  static Future<GunlukDurum> oku({DateTime? simdi}) async {
    final an = simdi ?? DateTime.now();
    final ilk = GunlukDurum.ilk(an);
    final kayit = GunlukDurum(
      sayi: await HomeWidget.getWidgetData<int>(anahtarSayi) ?? ilk.sayi,
      hedef: await HomeWidget.getWidgetData<int>(anahtarHedef) ?? ilk.hedef,
      bardakMl:
          await HomeWidget.getWidgetData<int>(anahtarBardakMl) ?? ilk.bardakMl,
      tarih: await HomeWidget.getWidgetData<String>(anahtarTarih) ?? ilk.tarih,
    );
    return kayit.bugunIcin(an);
  }

  /// Yazar ve widget'a yeniden çizilmesini söyler.
  static Future<void> yaz(GunlukDurum durum) async {
    await HomeWidget.saveWidgetData<int>(anahtarSayi, durum.sayi);
    await HomeWidget.saveWidgetData<int>(anahtarHedef, durum.hedef);
    await HomeWidget.saveWidgetData<int>(anahtarBardakMl, durum.bardakMl);
    await HomeWidget.saveWidgetData<String>(anahtarTarih, durum.tarih);
    await HomeWidget.updateWidget(qualifiedAndroidName: widgetAlicisi);
  }

  /// Oku → değiştir → yaz.
  static Future<GunlukDurum> degistir(
    GunlukDurum Function(GunlukDurum) islem,
  ) async {
    final yeni = islem(await oku());
    await yaz(yeni);
    return yeni;
  }
}
