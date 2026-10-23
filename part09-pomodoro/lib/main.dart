// K2 — iskelet ve risk denemesi. Bu ekran K5'te silinir.
// Sorulan: (a) panelde geri sayım akıyor mu (b) sıfırda "bitti" sayacın yerine
// geçiyor mu (c) ikon release'te doğru mu.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deneme_saat.dart';

const _vurgu = Color(0xFF1F3A93);
const _zemin = Color(0xFFE8EDF5);
const _yazi = Color(0xFF14213D);
const _ikon = 'ic_stat_pomodoro';
const _bildirimNo = 1;

/// Android Notification.FLAG_INSISTENT: ses, bildirime dokunulana ya da
/// panel açılana kadar tekrar eder. Sessiz moda uyar.
const _israrci = 4;

final _eklenti = FlutterLocalNotificationsPlugin();

/// Uygulama kapalıyken bildirim butonuna basılınca çalışır.
/// K2'de yalnız kayıtlı olması denenir, eylemler K4'te bağlanır.
@pragma('vm:entry-point')
void bildirimArkaPlan(NotificationResponse r) {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _eklenti.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(_ikon),
    ),
    onDidReceiveBackgroundNotificationResponse: bildirimArkaPlan,
  );
  final android = _eklenti
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'sayac',
      'Sayaç',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ),
  );
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'bitti',
      'Süre bitti',
      importance: Importance.high,
    ),
  );
  runApp(const DenemeUygulamasi());
}

class DenemeUygulamasi extends StatelessWidget {
  const DenemeUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _vurgu,
        scaffoldBackgroundColor: _zemin,
        fontFamily: 'Inter',
      ),
      home: const DenemeEkrani(),
    );
  }
}

class DenemeEkrani extends StatefulWidget {
  const DenemeEkrani({super.key});

  @override
  State<DenemeEkrani> createState() => _DenemeEkraniState();
}

class _DenemeEkraniState extends State<DenemeEkrani> {
  String _durum = 'Henüz denenmedi.';

  AndroidFlutterLocalNotificationsPlugin? get _android => _eklenti
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _dene() async {
    final android = _android;
    if (android == null) return;
    final bildirimIzni = await android.requestNotificationsPermission();
    var kesin = await android.canScheduleExactNotifications() ?? false;
    if (!kesin) {
      await android.requestExactAlarmsPermission();
      kesin = await android.canScheduleExactNotifications() ?? false;
    }

    final bitis = DateTime.now().add(const Duration(minutes: 1));
    await _eklenti.cancel(id: _bildirimNo);
    await _eklenti.show(
      id: _bildirimNo,
      title: 'Çalışma · 1/4',
      body: 'Bitiş ${_saat(bitis)}',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'sayac',
          'Sayaç',
          icon: _ikon,
          color: _vurgu,
          importance: Importance.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          showWhen: true,
          when: bitis.millisecondsSinceEpoch,
          usesChronometer: true,
          chronometerCountDown: true,
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          actions: const [
            AndroidNotificationAction(
              'duraklat',
              'Duraklat',
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              'dakika_ekle',
              '+1 dk',
              cancelNotification: false,
            ),
            AndroidNotificationAction('bitir', 'Bitir'),
          ],
        ),
      ),
    );

    var mod = kesin
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    String zamanlama;
    Future<void> zamanla() => _eklenti.zonedSchedule(
      id: _bildirimNo,
      scheduledDate: utcZaman(bitis),
      title: 'Mola zamanı',
      body: 'Bugün 1 pomodoro',
      androidScheduleMode: mod,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bitti',
          'Süre bitti',
          icon: _ikon,
          color: _vurgu,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          additionalFlags: Int32List.fromList(const [_israrci]),
          actions: const [
            AndroidNotificationAction('baslat', 'Başlat'),
            AndroidNotificationAction('atla', 'Atla'),
          ],
        ),
      ),
    );
    try {
      await zamanla();
      zamanlama = kesin ? 'kesin' : 'yaklaşık';
    } catch (e) {
      // Kesin alarm reddedildiyse bir kez yaklaşık modla yeniden dene (PLAN K6.5)
      mod = AndroidScheduleMode.inexactAllowWhileIdle;
      await zamanla();
      zamanlama = 'yaklaşık (kesin hata verdi: $e)';
    }

    setState(() {
      _durum =
          'Bildirim izni: ${bildirimIzni == true ? 'var' : 'yok'}\n'
          'Kesin alarm: ${kesin ? 'var' : 'yok'}\n'
          'Zamanlama: $zamanlama\n'
          'Bitiş: ${_saat(bitis)}\n\n'
          'Şimdi uygulamayı kapat ve paneli izle.';
    });
  }

  Future<void> _iptal() async {
    await _eklenti.cancel(id: _bildirimNo);
    setState(() => _durum = 'İptal edildi.');
  }

  static String _saat(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'K2 deneme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _yazi,
                ),
              ),
              const Spacer(),
              const Text(
                '01:00',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 86,
                  fontWeight: FontWeight.w700,
                  fontVariations: [FontVariation('wght', 700)],
                  letterSpacing: -4,
                  color: _yazi,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _durum,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _yazi),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _vurgu,
                  minimumSize: const Size.fromHeight(64),
                ),
                onPressed: _dene,
                child: const Text(
                  '1 dk sayaç göster + zamanla',
                  style: TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _iptal, child: const Text('İptal et')),
            ],
          ),
        ),
      ),
    );
  }
}
