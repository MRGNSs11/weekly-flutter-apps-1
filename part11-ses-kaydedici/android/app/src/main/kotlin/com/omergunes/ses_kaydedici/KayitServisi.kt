package com.omergunes.ses_kaydedici

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

// Kaydı record paketi yapar. Bu servis yalnız "Kaydediliyor" bildirimini tutar:
// mikrofon tipi ön plan servisi açıkken Android, ekran kapalıyken de
// uygulamanın mikrofonu kullanmasına izin verir.
class KayitServisi : Service() {
    private var uyanik: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val yonetici = getSystemService(NotificationManager::class.java)
        yonetici.createNotificationChannel(
            NotificationChannel(KANAL, "Kayıt", NotificationManager.IMPORTANCE_LOW)
        )
        val ac = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val bildirim = Notification.Builder(this, KANAL)
            .setContentTitle("Kaydediliyor")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(ac)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(BILDIRIM_NO, bildirim, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(BILDIRIM_NO, bildirim)
        }

        // Ekran kapanınca işlemci uyumasın; kayıt durunca bırakılır.
        if (uyanik == null) {
            uyanik = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SesKaydedici:kayit")
                .apply { acquire(3 * 60 * 60 * 1000L) }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        uyanik?.let { if (it.isHeld) it.release() }
        uyanik = null
        super.onDestroy()
    }

    companion object {
        const val KANAL = "kayit"
        const val BILDIRIM_NO = 1
    }
}
