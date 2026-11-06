package com.omergunes.ses_kaydedici

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "seskaydedici/servis")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Servis yalnız uygulama ekrandayken başlatılabilir (Android 12+).
                    "baslat" -> {
                        startForegroundService(Intent(this, KayitServisi::class.java))
                        result.success(true)
                    }
                    "durdur" -> {
                        stopService(Intent(this, KayitServisi::class.java))
                        result.success(true)
                    }
                    "bildirimIzniVar" -> result.success(bildirimIzniVar())
                    "bildirimIzniIste" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !bildirimIzniVar()) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
                        }
                        result.success(null)
                    }
                    // Mikrofon izni kalıcı reddedilince tek yol: uygulamanın ayar sayfası.
                    "ayarlariAc" -> {
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null)),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun bildirimIzniVar(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
}
