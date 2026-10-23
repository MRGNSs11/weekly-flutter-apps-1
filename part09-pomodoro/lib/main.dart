import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'bildirim/arka_plan.dart';
import 'bildirim/yerel_bildirim_servisi.dart';
import 'ui/alarm_ekrani.dart';
import 'ui/sayac_ekrani.dart';
import 'ui/tema.dart';
import 'uygulama/pomodoro_kontrol.dart';
import 'uygulama/zil.dart';
import 'veri/durum_deposu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final eklenti = FlutterLocalNotificationsPlugin();
  final kontrol = PomodoroKontrol(
    depo: PrefsDurumDeposu(),
    bildirim: YerelBildirimServisi(eklenti),
    zil: KanalZil(),
  );
  await eklenti.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(bildirimIkonu),
    ),
    // Ön planda gelen eylemler arka plandakiyle aynı yoldan geçer (K6.6).
    onDidReceiveNotificationResponse: (r) => kontrol.bildirimYaniti(r.actionId),
    onDidReceiveBackgroundNotificationResponse: bildirimArkaPlan,
  );
  await YerelBildirimServisi.kanallariKur(eklenti);
  runApp(PomodoroUygulamasi(kontrol: kontrol));
  await kontrol.yukle();
}

class PomodoroUygulamasi extends StatelessWidget {
  const PomodoroUygulamasi({super.key, required this.kontrol});

  final PomodoroKontrol kontrol;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: pomodoroTemasi(),
      home: ListenableBuilder(
        listenable: kontrol,
        builder: (_, _) => kontrol.yuklendi
            ? SayacEkrani(kontrol: kontrol)
            : const ColoredBox(color: Renk.zemin),
      ),
      // Alarm ekranı her sayfanın (ayarlar dahil) üstünde açılır.
      builder: (context, child) => ListenableBuilder(
        listenable: kontrol,
        builder: (_, _) => Stack(
          children: [
            child!,
            if (kontrol.alarmModu) AlarmEkrani(kontrol: kontrol),
          ],
        ),
      ),
    );
  }
}
