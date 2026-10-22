// K2 deneme yardımcısı. K4'te bildirim katmanına taşınır.
import 'package:timezone/timezone.dart' as tz;

/// Bitiş anını eklentinin istediği TZDateTime'a çevirir.
/// `tz.UTC`, `initializeTimeZones()` çağrılmadan da çalışır (PLAN K6.5).
tz.TZDateTime utcZaman(DateTime an) => tz.TZDateTime.from(an.toUtc(), tz.UTC);
