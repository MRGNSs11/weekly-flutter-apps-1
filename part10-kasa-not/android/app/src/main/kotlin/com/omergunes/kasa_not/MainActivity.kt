package com.omergunes.kasa_not

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth ve secure_storage'ın parmak izi penceresi FragmentActivity ister.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Kasa açıkken son uygulamalar ekranında önizleme alınmasın.
        // FLAG_SECURE değil: ekran görüntüsü serbest kalsın (Android 13+).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kasanot/gizlilik")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "onizlemeyiGizle" -> {
                        val gizle = call.arguments as Boolean
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            setRecentsScreenshotEnabled(!gizle)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
