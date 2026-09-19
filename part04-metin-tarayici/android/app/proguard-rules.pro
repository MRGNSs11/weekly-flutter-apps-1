# google_mlkit_text_recognition eklentisi beş betiği de çağırabiliyor:
# Latin, Çince, Devanagari, Japonca, Korece. Biz yalnızca Latin modelini
# bağımlılık olarak alıyoruz (uygulamada `TextRecognitionScript.latin`),
# diğer dördünün sınıfları APK'da yok — R8 bunları "eksik sınıf" sayıp
# release derlemesini durduruyor.
#
# Sınıfları eklemiyoruz: dördü de ayrı model demek, APK bir 27 MB daha
# şişerdi. Uyarıyı susturuyoruz; o kod yolları hiç çağrılmıyor.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
