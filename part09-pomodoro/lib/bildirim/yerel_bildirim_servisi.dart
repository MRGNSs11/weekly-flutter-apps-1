import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../alan/ayarlar.dart';
import '../alan/faz.dart';
import '../alan/pomodoro_durumu.dart';
import '../ui/tema.dart';
import 'bildirim_metinleri.dart';
import 'bildirim_servisi.dart';

const bildirimIkonu = 'ic_stat_pomodoro';
const _no = 1;
const _sayacKanali = 'sayac';
const _alarmKanali = 'alarm';

/// Android Notification.FLAG_INSISTENT: ses dokunulana kadar tekrar eder.
const _israrci = 4;

/// Bitiş anını eklentinin istediği zamana çevirir. `tz.UTC`, saat dilimi
/// verisi yüklenmeden de çalışır (PLAN K6.5, K2'de doğrulandı).
tz.TZDateTime utcZaman(DateTime an) => tz.TZDateTime.from(an.toUtc(), tz.UTC);

/// flutter_local_notifications ile PLAN K6.
class YerelBildirimServisi implements BildirimServisi {
  YerelBildirimServisi(this._eklenti);

  final FlutterLocalNotificationsPlugin _eklenti;
  static const _kanal = MethodChannel('pomodoro/alarm');

  AndroidFlutterLocalNotificationsPlugin? get _android => _eklenti
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Açılışta kanalları kurar (PLAN K6.1).
  static Future<void> kanallariKur(FlutterLocalNotificationsPlugin e) async {
    final android = e
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _sayacKanali,
        'Sayaç',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
    // K2 deneme kanalı: sesi bildirim sesiydi, panel açılınca kesiliyordu.
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
  }

  @override
  Future<void> esitle(PomodoroDurumu d, Ayarlar a) async {
    // Görünen bildirimi de bekleyen zamanlamayı da siler.
    await _eklenti.cancel(id: _no);
    switch (d.durum) {
      case Durum.calisiyor:
        await _eklenti.show(
          id: _no,
          title: fazEtiketi(d),
          body: sayacGovdesi(d),
          notificationDetails: NotificationDetails(android: _sayacDetay(d)),
        );
        await _zamanla(d, a);
      case Durum.duraklatildi:
        await _eklenti.show(
          id: _no,
          title: duraklatildiBasligi(d),
          body: duraklatildiGovdesi(d),
          notificationDetails: NotificationDetails(
            android: _duraklatildiDetay(d),
          ),
        );
      case Durum.bosta:
        break;
    }
  }

  Future<void> _zamanla(PomodoroDurumu d, Ayarlar a) async {
    final metin = bittiMetni(d);
    final kesin = await _android?.canScheduleExactNotifications() ?? false;
    Future<void> zamanla(AndroidScheduleMode mod) => _eklenti.zonedSchedule(
      id: _no,
      scheduledDate: utcZaman(d.bitis!),
      title: metin.baslik,
      body: metin.govde,
      androidScheduleMode: mod,
      notificationDetails: NotificationDetails(
        android: _alarmDetay(metin.siradaki, sessiz: !a.ses, tamEkran: true),
      ),
    );
    try {
      await zamanla(
        kesin
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException {
      // Kesin alarm izni arada geri alındıysa bir kez yaklaşık modla dene.
      await zamanla(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  static const _sayacEylemleri = [
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
  ];

  AndroidNotificationDetails _sayacDetay(PomodoroDurumu d) =>
      AndroidNotificationDetails(
        _sayacKanali,
        'Sayaç',
        icon: bildirimIkonu,
        color: Renk.faz(d.faz),
        importance: Importance.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        silent: true,
        showWhen: true,
        when: d.bitis!.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        category: AndroidNotificationCategory.progress,
        visibility: NotificationVisibility.public,
        actions: _sayacEylemleri,
      );

  AndroidNotificationDetails _duraklatildiDetay(PomodoroDurumu d) =>
      AndroidNotificationDetails(
        _sayacKanali,
        'Sayaç',
        icon: bildirimIkonu,
        color: Renk.faz(d.faz),
        importance: Importance.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        silent: true,
        showWhen: false,
        category: AndroidNotificationCategory.progress,
        visibility: NotificationVisibility.public,
        actions: const [
          AndroidNotificationAction(
            'devam',
            'Devam',
            cancelNotification: false,
          ),
          AndroidNotificationAction('bitir', 'Bitir'),
        ],
      );

  /// [sessiz] sürüm, uygulama alarmı fark edince konur: bildirim sesi
  /// susar, yerine uygulamanın zili çalar (PLAN K6.9).
  AndroidNotificationDetails _alarmDetay(
    Faz siradaki, {
    required bool sessiz,
    required bool tamEkran,
  }) => AndroidNotificationDetails(
    _alarmKanali,
    'Süre doldu',
    icon: bildirimIkonu,
    color: Renk.faz(siradaki),
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    fullScreenIntent: tamEkran,
    autoCancel: false,
    silent: sessiz,
    onlyAlertOnce: !tamEkran,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    additionalFlags: sessiz ? null : Int32List.fromList(const [_israrci]),
    actions: const [
      AndroidNotificationAction('baslat', 'Başlat'),
      AndroidNotificationAction('atla', 'Atla'),
    ],
  );

  @override
  Future<bool> alarmVar() async {
    final aktif = await _eklenti.getActiveNotifications();
    return aktif.any((n) => n.id == _no && n.channelId == _alarmKanali);
  }

  @override
  Future<void> alarmiSessizYap(PomodoroDurumu d, Ayarlar a, int bugun) async {
    // Sessiz sürümle değiştirmek ısrarcı sesi susturmuyor (K2): önce kapat.
    await _eklenti.cancel(id: _no);
    final metin = alarmMetni(d, bugun);
    await _eklenti.show(
      id: _no,
      title: metin.baslik,
      body: metin.govde,
      notificationDetails: NotificationDetails(
        android: _alarmDetay(metin.siradaki, sessiz: true, tamEkran: false),
      ),
    );
  }

  @override
  Future<void> alarmiKapat() => _eklenti.cancel(id: _no);

  @override
  Future<IzinDurumu> izinler() async {
    final android = _android;
    if (android == null) return IzinDurumu.hepsiVar;
    bool tamEkran;
    try {
      tamEkran = await _kanal.invokeMethod<bool>('tamEkranVar') ?? true;
    } on MissingPluginException {
      tamEkran = true;
    }
    return IzinDurumu(
      bildirim: await android.areNotificationsEnabled() ?? true,
      kesin: await android.canScheduleExactNotifications() ?? true,
      tamEkran: tamEkran,
    );
  }

  @override
  Future<bool> bildirimIzniIste() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<bool> kesinIzniIste() async =>
      await _android?.requestExactAlarmsPermission() ?? true;

  @override
  Future<bool> tamEkranIzniIste() async =>
      await _android?.requestFullScreenIntentPermission() ?? true;

  @override
  Future<void> bildirimAyarlariniAc() async =>
      _android?.openAppNotificationSettings();
}
