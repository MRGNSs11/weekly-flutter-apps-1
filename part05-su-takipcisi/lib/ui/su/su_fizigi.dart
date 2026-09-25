import 'dart:math' as math;

/// Su sahnesinin hareket durumu: seviye, dalga fazı, damlalar, sıçrama,
/// halkalar, kabarcıklar ve eğim.
///
/// Saf Dart; çizimden ayrı olduğu için testle sınanabiliyor. Sabitler
/// `tasarimlar.html`'deki `efektIlerlet`ten birebir alındı (PLAN.md B2.4).
/// Taslak kare başına yazılmıştı (60 fps); burada `f = dt · 60` ile
/// çarpılıyor, böylece 90/120 Hz ekranda da aynı hızda akıyor.
class SuFizigi {
  SuFizigi({math.Random? rastgele}) : _rnd = rastgele ?? math.Random() {
    kabarciklar = List.generate(
      18,
      (_) => Kabarcik(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        r: 1 + _rnd.nextDouble() * 3,
        hiz: .0015 + _rnd.nextDouble() * .003,
      ),
    );
  }

  final math.Random _rnd;

  // ── Ölçü: sahne boyutu (LayoutBuilder'dan gelir) ──
  double genislik = 0;
  double yukseklik = 0;

  /// Suyun dipten en az bu kadar yüksek olması (px). Düğmeler hep suyun
  /// içinde kalsın diye ana ekran verir.
  double enAzPx = 0;

  /// Suyun en fazla çıkabileceği oran (ekran yüksekliğine göre).
  double enFazlaOran = .8;

  /// Hareket azaltma açıksa her şey anında yerine oturur, dalga durur.
  bool hareketAzaltilmis = false;

  // ── Durum ──
  /// 0–1: hedefe oran (`GunlukDurum.oran`).
  double hedefOran = 0;
  double _gosterilenOran = 0;
  double faz = 0;
  double gecenMs = 0;
  double sallanma = 0;
  double egim = 0;
  double egimHizi = 0;
  double egimHedef = 0;

  final List<Damla> damlalar = [];
  final List<Parca> sicrama = [];
  final List<Halka> halkalar = [];
  late final List<Kabarcik> kabarciklar;

  /// Şu an ekranda gösterilen doluluk oranı (hedefe doğru yumuşak ilerler).
  double get gosterilenOran => _gosterilenOran;

  /// Su yüzeyinin dalgasız, eğimsiz y konumu.
  double get taban {
    final enAz = math.min(enAzPx, yukseklik);
    final enFazla = math.max(yukseklik * enFazlaOran, enAz);
    final suBoyu = enAz + (enFazla - enAz) * _gosterilenOran;
    return yukseklik - suBoyu + math.sin(gecenMs * .012) * sallanma * 4;
  }

  void damlaBirak() {
    if (hareketAzaltilmis || genislik == 0) return;
    damlalar.add(Damla(x: genislik * (.42 + _rnd.nextDouble() * .16), y: -12));
  }

  void dokun(double x, double y) {
    if (hareketAzaltilmis) return;
    halkalar.add(Halka(x: x, y: y, yuzey: false));
  }

  void sallan() => sallanma = 1;

  /// Yüzeyin `px` noktasındaki yüksekliği: iki sinüs + eğim + damla halkaları.
  double yuzeyY(double px, double y, double genlik, double boy, double f) {
    var v =
        y +
        math.sin(px / boy * math.pi * 2 + f) * genlik +
        math.sin(px * .013 + f * .6) * genlik * .45;
    v += (px - genislik / 2) * egim;
    for (final h in halkalar) {
      if (!h.yuzey) continue;
      final d = (px - h.x).abs() - h.r;
      v -= 7 * h.a * math.cos(d / 7) * math.exp(-d * d / 260);
    }
    return v;
  }

  /// Bir kare ilerlet. `dt` saniye.
  void ilerle(double dt) {
    if (hareketAzaltilmis) {
      _gosterilenOran = hedefOran;
      damlalar.clear();
      sicrama.clear();
      halkalar.clear();
      sallanma = 0;
      egim = 0;
      return;
    }
    final f = dt * 60;
    gecenMs += dt * 1000;
    faz += dt * 1.6; // taslak: 0.0016 rad/ms

    _gosterilenOran += (hedefOran - _gosterilenOran) * (1 - math.pow(.94, f));
    sallanma *= math.pow(.96, f);

    egimHizi += (egimHedef - egim) * .03 * f;
    egimHizi *= math.pow(.9, f);
    egim += egimHizi * f;
    sallanma = math.max(sallanma, math.min(1, egimHizi.abs() * 25));

    final t = taban;
    for (final d in damlalar) {
      d.vy += .45 * f;
      d.y += d.vy * f;
      final yuzeyHizasi = t + (d.x - genislik / 2) * egim;
      if (d.y >= yuzeyHizasi) {
        d.bitti = true;
        sallanma = 1;
        halkalar.add(Halka(x: d.x, y: yuzeyHizasi, yuzey: true));
        for (var i = 0; i < 8; i++) {
          sicrama.add(
            Parca(
              x: d.x,
              y: yuzeyHizasi,
              vx: (_rnd.nextDouble() - .5) * 4,
              vy: -2 - _rnd.nextDouble() * 3,
            ),
          );
        }
      }
    }
    damlalar.removeWhere((d) => d.bitti);

    for (final p in sicrama) {
      p.vy += .25 * f;
      p.x += p.vx * f;
      p.y += p.vy * f;
      p.omur -= .035 * f;
    }
    sicrama.removeWhere((p) => p.omur <= 0);

    final sonum = math.pow(.965, f).toDouble();
    for (final h in halkalar) {
      h.r += (h.yuzey ? 2.2 : 1.6) * f;
      h.a *= sonum;
    }
    halkalar.removeWhere((h) => h.a <= .04);

    for (final b in kabarciklar) {
      b.y -= b.hiz * f;
      if (b.y < 0) b.y = 1;
    }
  }
}

class Damla {
  Damla({required this.x, required this.y});
  double x;
  double y;
  double vy = 0;
  bool bitti = false;
}

class Parca {
  Parca({required this.x, required this.y, required this.vx, required this.vy});
  double x;
  double y;
  double vx;
  double vy;
  double omur = 1;
}

class Halka {
  Halka({required this.x, required this.y, required this.yuzey});
  final double x;
  final double y;

  /// true: damlanın yüzeyde açtığı halka (yüzeyi büker).
  /// false: dokunulan yerde su içinde yayılan halka (yalnız çizilir).
  final bool yuzey;
  double r = 0;
  double a = 1;
}

class Kabarcik {
  Kabarcik({
    required this.x,
    required this.y,
    required this.r,
    required this.hiz,
  });

  /// 0–1, sahne genişliğine göre.
  final double x;

  /// 0 = yüzey, 1 = dip.
  double y;
  final double r;
  final double hiz;
}
