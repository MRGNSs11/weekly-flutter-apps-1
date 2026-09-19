# ── ML Kit + R8 ──────────────────────────────────────────────────────
#
# Bu dosyanın ilk hâli yalnızca -dontwarn içeriyordu ve DERLEME GEÇTİ.
# Telefonda deneyince metin tanıma çalışmadı:
#
#   MethodChannel#google_mlkit_text_recognizer: Failed to handle method call
#   java.lang.NullPointerException: Attempt to invoke virtual method
#   'java.lang.Class java.lang.Object.getClass()' on a null object reference
#
# Ders: -dontwarn UYARIYI susturur, SEBEBİ çözmez. Derleme yeşile döndü,
# hata çalışma anına ertelendi. Debug derlemesinde hiç görünmedi çünkü
# R8 orada çalışmıyor.
#
# Sebep: ML Kit sınıflarını yansıma (reflection) ile çözüyor. R8 yansımayla
# ulaşılan sınıfı "kullanılmıyor" sanıp atıyor ya da adını değiştiriyor;
# geriye null kalıyor. Aşağıdaki keep kuralları bunu engelliyor.

-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Eklenti beş betiği de çağırabiliyor (Latin, Çince, Devanagari, Japonca,
# Korece); biz yalnızca Latin modelini bağımlılık olarak alıyoruz, diğer
# dördünün sınıfları APK'da YOK. Bunlar gerçekten yok ve hiç çağrılmıyor —
# burada susturmak doğru, çünkü kaldırılan bir şey değil, hiç var olmayan
# bir şey. (Dördünü de eklemek her biri için ayrı model, yani ~27 MB daha.)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
