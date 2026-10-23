import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../alan/kurallar.dart';
import '../alan/pomodoro_durumu.dart';
import '../veri/durum_deposu.dart';
import 'bildirim_servisi.dart';
import 'yerel_bildirim_servisi.dart';

/// Uygulamanın dinlediği port: arka plandaki eylem ekranı tazeler.
const uiPortAdi = 'pomodoro_ui';

const _eylemler = {
  'baslat',
  'duraklat',
  'devam',
  'dakika_ekle',
  'bitir',
  'atla',
};

/// Bildirim butonu ister uygulama açıkken ister kapalıyken gelsin, bu tek
/// fonksiyondan geçer (PLAN K6.6). Bilinmeyen eylem hiçbir şey yapmaz.
Future<PomodoroDurumu?> eylemCalistir(
  String ad, {
  required DurumDeposu depo,
  required BildirimServisi bildirim,
  required DateTime simdi,
}) async {
  if (!_eylemler.contains(ad)) return null;
  final d = await depo.durumOku();
  final a = await depo.ayarlarOku();
  final yeni = eylem(ad, d, a, simdi);
  if (yeni != d) await depo.durumYaz(yeni);
  await bildirim.esitle(yeni, a);
  return yeni;
}

/// Uygulama kapalıyken bildirim butonuna basılınca ayrı bir isolate'te
/// çalışır. Arka planda sayaç tutulmaz: yalnız kayıt güncellenir ve panel
/// yeniden kurulur.
@pragma('vm:entry-point')
Future<void> bildirimArkaPlan(NotificationResponse r) async {
  final ad = r.actionId;
  if (ad == null || ad.isEmpty) return;
  DartPluginRegistrant.ensureInitialized();
  await eylemCalistir(
    ad,
    depo: PrefsDurumDeposu(),
    bildirim: YerelBildirimServisi(FlutterLocalNotificationsPlugin()),
    simdi: DateTime.now(),
  );
  IsolateNameServer.lookupPortByName(uiPortAdi)?.send('yenile');
}
