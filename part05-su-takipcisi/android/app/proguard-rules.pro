# Glance, widget eylemlerini (ActionCallback) çalışma anında adından bulup
# boş kurucuyla oluşturuyor. R8 bunu göremediği için kurucuyu siliyordu:
# "NoSuchMethodException: ArtiBirEylemi.<init> []" → widget'taki +1 çalışmıyordu.
-keep class * implements androidx.glance.appwidget.action.ActionCallback {
    <init>();
}
