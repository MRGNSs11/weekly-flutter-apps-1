import 'package:pomodoro/alan/ayarlar.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';
import 'package:pomodoro/bildirim/bildirim_servisi.dart';
import 'package:pomodoro/uygulama/zil.dart';
import 'package:pomodoro/veri/durum_deposu.dart';

class SahteDepo implements DurumDeposu {
  SahteDepo({PomodoroDurumu? durum, Ayarlar? ayarlar})
    : durum = durum ?? const PomodoroDurumu(),
      ayarlar = ayarlar ?? const Ayarlar();

  PomodoroDurumu durum;
  Ayarlar ayarlar;
  final bayraklar = <String, bool>{};
  int yazmaSayisi = 0;

  @override
  Future<PomodoroDurumu> durumOku() async => durum;

  @override
  Future<void> durumYaz(PomodoroDurumu d) async {
    durum = d;
    yazmaSayisi++;
  }

  @override
  Future<Ayarlar> ayarlarOku() async => ayarlar;

  @override
  Future<void> ayarlarYaz(Ayarlar a) async => ayarlar = a;

  @override
  Future<bool> bayrakOku(String ad) async => bayraklar[ad] ?? false;

  @override
  Future<void> bayrakYaz(String ad, bool deger) async => bayraklar[ad] = deger;
}

class SahteBildirim implements BildirimServisi {
  SahteBildirim({this.izin = IzinDurumu.hepsiVar});

  IzinDurumu izin;

  /// Bildirim izni istenince verilecek cevap.
  bool bildirimCevabi = true;
  bool alarm = false;
  final esitlenen = <PomodoroDurumu>[];
  final istenen = <String>[];

  @override
  Future<void> esitle(PomodoroDurumu d, Ayarlar a) async {
    esitlenen.add(d);
    alarm = false;
  }

  @override
  Future<bool> alarmVar() async => alarm;

  @override
  Future<void> alarmiSessizYap(PomodoroDurumu d, Ayarlar a, int bugun) async {
    istenen.add('sessiz');
  }

  @override
  Future<void> alarmiKapat() async => alarm = false;

  @override
  Future<IzinDurumu> izinler() async => izin;

  @override
  Future<bool> bildirimIzniIste() async {
    istenen.add('bildirim');
    izin = IzinDurumu(
      bildirim: bildirimCevabi,
      kesin: izin.kesin,
      tamEkran: izin.tamEkran,
    );
    return bildirimCevabi;
  }

  @override
  Future<bool> kesinIzniIste() async {
    istenen.add('kesin');
    return false;
  }

  @override
  Future<bool> tamEkranIzniIste() async {
    istenen.add('tamEkran');
    return false;
  }

  @override
  Future<void> bildirimAyarlariniAc() async => istenen.add('ayarlar');
}

class SahteZil implements Zil {
  bool caliyor = false;
  int calmaSayisi = 0;

  @override
  Future<void> cal() async {
    caliyor = true;
    calmaSayisi++;
  }

  @override
  Future<void> sustur() async => caliyor = false;
}
