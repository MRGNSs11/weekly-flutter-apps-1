package com.omergunes.pomodoro

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * "Süre doldu" ekranı açıkken alarm sesini döngüyle çalar.
 * Bildirim sesi panel açılınca Android tarafından kesilir; bu ses yalnız
 * Durdur'a basılınca (ya da ekran kapanınca) susar.
 */
class MainActivity : FlutterActivity() {
    private var zil: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pomodoro/alarm")
            .setMethodCallHandler { cagri, sonuc ->
                when (cagri.method) {
                    "cal" -> { cal(); sonuc.success(null) }
                    "sustur" -> { sustur(); sonuc.success(null) }
                    else -> sonuc.notImplemented()
                }
            }
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
    }

    override fun onDestroy() {
        sustur()
        super.onDestroy()
    }
}
