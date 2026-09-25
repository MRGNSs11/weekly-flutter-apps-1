package com.omergunes.su_takipcisi

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.ImageProvider
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Ana ekran widget'ı: bugünkü sayı, ml, doluluk çubuğu ve "+1".
 *
 * Veriyi Flutter'daki `SuDeposu` ile aynı SharedPreferences dosyasından,
 * aynı anahtarlarla okur. Widget canlı çizim yapamaz; dalga uygulamada,
 * burada yalnız yerli parçalar (yazı, çubuk, düğme) var.
 */
class SuWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { Icerik(context, currentState()) }
  }

  @Composable
  private fun Icerik(context: Context, state: HomeWidgetGlanceState) {
    val prefs = state.preferences
    val hedef = prefs.getInt(SuVerisi.HEDEF, 8).coerceAtLeast(1)
    val bardakMl = prefs.getInt(SuVerisi.BARDAK_ML, 250)
    val sayi = SuVerisi.bugunkuSayi(prefs)
    val ml = NumberFormat.getIntegerInstance(Locale("tr", "TR")).format(sayi * bardakMl)

    Box(
      modifier = GlanceModifier
        .fillMaxSize()
        .background(ImageProvider(R.drawable.cam_zemin))
        .clickable(actionStartActivity<MainActivity>(context)),
      contentAlignment = Alignment.Center,
    ) {
      Row(
        modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
      ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
          Text(
            text = "$sayi/$hedef",
            style = TextStyle(color = ColorProvider(Color.White), fontSize = 30.sp),
          )
          Text(
            text = "$ml ml",
            style = TextStyle(color = ColorProvider(Color(0xCCFFFFFF)), fontSize = 11.sp),
          )
          Spacer(GlanceModifier.height(8.dp))
          LinearProgressIndicator(
            progress = (sayi.toFloat() / hedef).coerceIn(0f, 1f),
            modifier = GlanceModifier.fillMaxWidth().height(6.dp),
            color = ColorProvider(Color.White),
            backgroundColor = ColorProvider(Color(0x4DFFFFFF)),
          )
        }
        Spacer(GlanceModifier.width(12.dp))
        Box(
          modifier = GlanceModifier
            .size(48.dp)
            .background(ImageProvider(R.drawable.cam_dugme))
            .clickable(actionRunCallback<ArtiBirEylemi>())
            .semantics { contentDescription = "Bir bardak ekle" },
          contentAlignment = Alignment.Center,
        ) {
          Text(
            text = "+1",
            style = TextStyle(
              color = ColorProvider(Color.White),
              fontSize = 15.sp,
              fontWeight = FontWeight.Bold,
            ),
          )
        }
      }
    }
  }
}

/**
 * "+1": sayıyı doğrudan burada, Kotlin'de artırır.
 *
 * İlk sürüm Dart'ı arka planda uyandırıyordu (home_widget'ın geri çağrısı).
 * O yol her dokunuşta sıfırdan bir Flutter motoru açıyor (1-3 sn) ve iş
 * kuyruğu Dart'ın bitmesini beklemeden "tamam" diyordu; Android işlemi bu
 * arada kapatınca +1 sessizce kayboluyordu (2026-09-25, cihazda görüldü).
 * Glance bu eylemi Android'in beklediği süre içinde bitirir; motor yok.
 */
class ArtiBirEylemi : ActionCallback {
  override suspend fun onAction(
    context: Context,
    glanceId: GlanceId,
    parameters: ActionParameters,
  ) {
    withContext(Dispatchers.IO) { SuVerisi.ekle(context) }
    // home_widget'ın kendi alıcısıyla aynı sıra: önce durumu yenile, sonra çiz.
    val widget = SuWidget()
    GlanceAppWidgetManager(context).getGlanceIds(SuWidget::class.java).forEach { id ->
      updateAppWidgetState(context, widget.stateDefinition, id) { it }
      widget.update(context, id)
    }
  }
}

/**
 * Flutter'daki `SuDeposu` ile AYNI dosya, AYNI anahtarlar, AYNI türler
 * (sayı Int, tarih "yyyy-MM-dd" String). Gün sıfırlama kuralı da Dart'taki
 * `GunlukDurum.bugunIcin` ile aynı: kayıt başka güne aitse sayı 0.
 */
internal object SuVerisi {
  const val SAYI = "sayi"
  const val HEDEF = "hedef"
  const val BARDAK_ML = "bardakMl"
  const val TARIH = "tarih"

  fun bugun(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

  fun bugunkuSayi(prefs: SharedPreferences): Int =
    if (prefs.getString(TARIH, null) == bugun()) prefs.getInt(SAYI, 0) else 0

  // Hızlı iki dokunuş iki eylemi aynı anda çalıştırabilir; "oku → +1 → yaz"
  // üst üste binerse bir dokunuş kaybolur. Kilit, sırayla çalışmalarını sağlar.
  @Synchronized
  fun ekle(context: Context) {
    val prefs = HomeWidgetPlugin.getData(context)
    // commit (apply değil): eylem bitmeden diske yazılmış olsun.
    prefs.edit()
      .putInt(SAYI, bugunkuSayi(prefs) + 1)
      .putString(TARIH, bugun())
      .commit()
  }
}

class SuWidgetReceiver : HomeWidgetGlanceWidgetReceiver<SuWidget>() {
  override val glanceAppWidget = SuWidget()
}
