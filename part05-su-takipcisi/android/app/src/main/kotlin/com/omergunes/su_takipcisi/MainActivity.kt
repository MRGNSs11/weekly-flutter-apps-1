package com.omergunes.su_takipcisi

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private var sesler: DamlaSesleri? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val s = DamlaSesleri(this).also { sesler = it }
    // Dart tarafı: lib/ses/ses.dart → aynı kanal adı, aynı yöntem adları.
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "su_takipcisi/ses")
      .setMethodCallHandler { cagri, sonuc ->
        when (cagri.method) {
          "birak" -> { s.birak(); sonuc.success(null) }
          "carp" -> { s.carp(); sonuc.success(null) }
          else -> sonuc.notImplemented()
        }
      }
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    sesler?.kapat()
    sesler = null
    super.cleanUpFlutterEngine(flutterEngine)
  }
}

/**
 * İki kısa damla sesi. SoundPool: sesleri önceden belleğe yükler, çalma
 * gecikmesi birkaç milisaniye → ses damlanın suya değdiği kareyle aynı anda.
 * Paket eklenmedi: bu iş için bir ses paketi hem boyut hem izin getirir.
 *
 * USAGE_GAME: medya sesine bağlı (telefon sessizdeyken de medya sesi açıksa
 * çalar). Kapatmak isteyen için uygulamada Ayarlar → Ses anahtarı var.
 */
private class DamlaSesleri(activity: FlutterActivity) {
  private val havuz = SoundPool.Builder()
    .setMaxStreams(4)
    .setAudioAttributes(
      AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    )
    .build()

  private val birakId = havuz.load(activity, R.raw.damla_birak, 1)
  private val carpId = havuz.load(activity, R.raw.damla_carp, 1)

  // Yüklenmemiş sesi çalmak sessizce hiçbir şey yapmaz; hata yok.
  fun birak() { havuz.play(birakId, 1f, 1f, 1, 0, 1f) }
  fun carp() { havuz.play(carpId, 1f, 1f, 1, 0, 1f) }

  fun kapat() = havuz.release()
}
