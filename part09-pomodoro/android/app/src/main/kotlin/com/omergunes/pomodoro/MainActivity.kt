package com.omergunes.pomodoro

import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * "Süre doldu" alarmı (PLAN K6.9).
 * - Zil: alarm sesi döngüyle çalar. Bildirim sesi panel açılınca Android
 *   tarafından kesilir; bu ses yalnız Durdur/Başlat/Atla ile susar.
 * - Kilit üstü yalnız alarmda: uygulama bildirimden açılınca kilidin üstünde
 *   görünür ve ekranı açar, zil susunca bu geri alınır.
 */
class MainActivity : FlutterActivity() {
    private var zil: Ringtone? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        kilitUstu(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        kilitUstu(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pomodoro/alarm")
            .setMethodCallHandler { cagri, sonuc ->
                when (cagri.method) {
                    "cal" -> { cal(); sonuc.success(null) }
                    "sustur" -> { sustur(); sonuc.success(null) }
                    "tamEkranVar" -> sonuc.success(tamEkranVar())
                    else -> sonuc.notImplemented()
                }
            }
    }

    /** flutter_local_notifications bildirimden açılışta bu eylemi kullanır. */
    private fun kilitUstu(intent: Intent?) {
        if (intent?.action == "SELECT_NOTIFICATION") kilitUstuAyarla(true)
    }

    private fun kilitUstuAyarla(acik: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(acik)
            setTurnScreenOn(acik)
        }
    }

    private fun tamEkranVar(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        return getSystemService(NotificationManager::class.java).canUseFullScreenIntent()
    }

    private fun cal() {
        if (zil?.isPlaying == true) return
        val adres = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        zil = RingtoneManager.getRingtone(this, adres)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
            play()
        }
    }

    private fun sustur() {
        zil?.stop()
        zil = null
        kilitUstuAyarla(false)
    }

    override fun onDestroy() {
        zil?.stop()
        zil = null
        super.onDestroy()
    }
}
