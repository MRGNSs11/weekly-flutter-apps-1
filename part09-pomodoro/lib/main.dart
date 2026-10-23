// K2 — iskelet ve risk denemesi. Bu ekran K5'te silinir.
// Sorulan: (a) panelde geri sayım akıyor mu (b) sıfırda "bitti" sayacın yerine
// geçiyor mu (c) ikon release'te doğru mu (e) süre dolunca alarm ekranı
// kilit ekranında açılıyor mu, ses Durdur'a kadar sürüyor mu.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deneme_saat.dart';

const _vurgu = Color(0xFF1F3A93);
const _zemin = Color(0xFFE8EDF5);
const _yazi = Color(0xFF14213D);
const _ikon = 'ic_stat_pomodoro';
const _bildirimNo = 1;
const _alarmKanali = 'alarm';

/// Android Notification.FLAG_INSISTENT: bildirim sesi tekrar eder.
const _israrci = 4;

/// "Süre doldu" ekranı açıkken döngüyle çalan alarm sesi (MainActivity.kt).
const _zil = MethodChannel('pomodoro/alarm');

final _eklenti = FlutterLocalNotificationsPlugin();

/// Bildirime dokunulunca ya da tam ekran bildirim açılınca ekran tazelenir.
final _bildirimTetik = ValueNotifier<int>(0);

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
    onDidReceiveNotificationResponse: (_) => _bildirimTetik.value++,
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
  // Eski deneme kanalı: sesi bildirim sesiydi, panel açılınca kesiliyordu.
  await android?.deleteNotificationChannel(channelId: 'bitti');
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      _alarmKanali,
      'Süre doldu',
      importance: Importance.max,
      sound: UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      ),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
  );
  runApp(const DenemeUygulamasi());
}

/// Süre dolunca giden bildirim. [sessiz] sürüm, alarm ekranı açıldığında
/// aynı bildirimin yerine konur: bildirim sesi susar, ekrandaki zil çalar.
AndroidNotificationDetails _alarmDetay({required bool sessiz}) =>
    AndroidNotificationDetails(
      _alarmKanali,
      'Süre doldu',
      icon: _ikon,
      color: _vurgu,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: !sessiz,
      autoCancel: false,
      silent: sessiz,
      onlyAlertOnce: sessiz,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: sessiz ? null : Int32List.fromList(const [_israrci]),
      actions: const [AndroidNotificationAction('durdur', 'Durdur')],
    );

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

class _DenemeEkraniState extends State<DenemeEkrani>
    with WidgetsBindingObserver {
  String _durum = 'Henüz denenmedi.';
  DateTime? _bitis;
  bool _alarm = false;
  Timer? _saniye;

  AndroidFlutterLocalNotificationsPlugin? get _android => _eklenti
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bildirimTetik.addListener(_alarmKontrol);
    _saniye = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
    _alarmKontrol();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bildirimTetik.removeListener(_alarmKontrol);
    _saniye?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _alarmKontrol();
  }

  void _tik() {
    if (_alarm) {
      // Bildirimdeki Durdur'a basıldıysa bildirim gitmiştir: zili de sustur.
      _alarmKontrol();
    } else if (_bitis != null) {
      if (DateTime.now().isAfter(_bitis!)) _alarmKontrol();
      setState(() {});
    }
  }

  /// Panelde alarm bildirimi duruyorsa "Süre doldu" ekranını aç ve zili çal.
  Future<void> _alarmKontrol() async {
    final aktif = await _eklenti.getActiveNotifications();
    final alarmVar = aktif.any(
      (n) => n.id == _bildirimNo && n.channelId == _alarmKanali,
    );
    if (!mounted) return;
    if (alarmVar && !_alarm) {
      setState(() {
        _alarm = true;
        _bitis = null;
      });
      await _eklenti.show(
        id: _bildirimNo,
        title: 'Süre doldu',
        body: 'Mola zamanı',
        notificationDetails: NotificationDetails(
          android: _alarmDetay(sessiz: true),
        ),
      );
      await _zil.invokeMethod<void>('cal');
      unawaited(HapticFeedback.mediumImpact());
    } else if (!alarmVar && _alarm) {
      await _zil.invokeMethod<void>('sustur');
      setState(() => _alarm = false);
    }
  }

  Future<void> _durdur() async {
    await _zil.invokeMethod<void>('sustur');
    await _eklenti.cancel(id: _bildirimNo);
    setState(() {
      _alarm = false;
      _durum = 'Alarm durduruldu.';
    });
  }

  Future<void> _dene() async {
    final android = _android;
    if (android == null) return;
    final bildirimIzni = await android.requestNotificationsPermission();
    var kesin = await android.canScheduleExactNotifications() ?? false;
    if (!kesin) {
      await android.requestExactAlarmsPermission();
      kesin = await android.canScheduleExactNotifications() ?? false;
    }
    final tamEkran = await android.requestFullScreenIntentPermission();

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
      title: 'Süre doldu',
      body: 'Mola zamanı',
      androidScheduleMode: mod,
      notificationDetails: NotificationDetails(
        android: _alarmDetay(sessiz: false),
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
      _bitis = bitis;
      _durum =
          'Bildirim izni: ${bildirimIzni == true ? 'var' : 'yok'}\n'
          'Kesin alarm: ${kesin ? 'var' : 'yok'}\n'
          'Tam ekran izni: ${tamEkran == true ? 'var' : 'yok'}\n'
          'Zamanlama: $zamanlama · Bitiş ${_saat(bitis)}\n\n'
          'Şimdi ekranı kilitle ve bekle.';
    });
  }

  Future<void> _iptal() async {
    await _eklenti.cancel(id: _bildirimNo);
    setState(() {
      _bitis = null;
      _durum = 'İptal edildi.';
    });
  }

  static String _saat(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _kalan {
    final b = _bitis;
    if (b == null) return '01:00';
    final sn = b.difference(DateTime.now()).inMilliseconds / 1000;
    final s = sn <= 0 ? 0 : sn.ceil();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_alarm) return _AlarmEkrani(onDurdur: _durdur);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'K2 deneme · alarm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _yazi,
                ),
              ),
              const Spacer(),
              Text(
                _kalan,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

/// Süre dolunca açılan tam ekran: lacivert dolgu, büyük Durdur.
class _AlarmEkrani extends StatelessWidget {
  const _AlarmEkrani({required this.onDurdur});

  final VoidCallback onDurdur;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _vurgu,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Süre doldu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  fontVariations: [FontVariation('wght', 700)],
                  letterSpacing: -2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mola zamanı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _vurgu,
                  minimumSize: const Size.fromHeight(72),
                ),
                onPressed: onDurdur,
                child: const Text(
                  'Durdur',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
