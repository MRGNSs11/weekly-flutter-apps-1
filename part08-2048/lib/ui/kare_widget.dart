import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'kil_yuzey.dart';
import 'tema.dart';

/// Karenin sahnedeki hâli (PLAN B2.4).
enum KareModu {
  normal,

  /// 2048 sahnesinde kazanmayan kareler: düzleşip solar.
  sonuk,

  /// 2048 sahnesinde kazanan kare: en çok kabarır, vurgu rengi, nefes alır.
  zirve,

  /// Oyun bitince: içe çöker, rakam soluklaşır.
  kursun,
}

enum _Olay { yok, dogma, yogurma }

/// Tek kare. Konumunu tahta verir; burada yalnız yüzeyin animasyonları var.
/// Hepsi aynı sayının, [KilYuzey] yüksekliğinin animasyonu.
class KareWidget extends StatefulWidget {
  const KareWidget({
    super.key,
    required this.deger,
    this.dogdu = false,
    this.yogurma = 0,
    this.mod = KareModu.normal,
    this.modGecikmesi = Duration.zero,
    this.azHareket = false,
  });

  final int deger;

  /// İlk çizimde çukurdan doğarak çıksın mı?
  final bool dogdu;

  /// Her birleşmede bir artar; artınca yoğurma oynar.
  final int yogurma;
  final KareModu mod;
  final Duration modGecikmesi;

  /// Telefonda "animasyonları kaldır" açıksa: doğma, yoğurma ve nefes yok,
  /// mod geçişleri anında.
  final bool azHareket;

  @override
  State<KareWidget> createState() => _KareWidgetState();
}

class _KareWidgetState extends State<KareWidget> with TickerProviderStateMixin {
  late final AnimationController _olay = AnimationController(vsync: this);
  late final AnimationController _mod = AnimationController(vsync: this);
  late final AnimationController _nefes = AnimationController(
    vsync: this,
    duration: Sure.nefes ~/ 2,
  );
  late final Listenable _hepsi = Listenable.merge([_olay, _mod, _nefes]);

  _Olay _olayTuru = _Olay.yok;
  double _yogurmaBaslangici = 0;
  KareModu _gosterilenMod = KareModu.normal;
  Timer? _modZamani;

  @override
  void initState() {
    super.initState();
    if (widget.dogdu && !widget.azHareket) _oyna(_Olay.dogma, Sure.dogma);
    _modaGec(widget.mod);
  }

  @override
  void didUpdateWidget(KareWidget eski) {
    super.didUpdateWidget(eski);
    if (widget.yogurma != eski.yogurma && !widget.azHareket) {
      _yogurmaBaslangici = Olcu.kabarma(eski.deger);
      _oyna(_Olay.yogurma, Sure.yogurma);
    }
    if (widget.mod != eski.mod) _modaGec(widget.mod);
  }

  void _oyna(_Olay tur, Duration sure) {
    _olayTuru = tur;
    _olay
      ..duration = sure
      ..forward(from: 0);
  }

  void _modaGec(KareModu mod) {
    _modZamani?.cancel();
    if (mod == KareModu.normal) {
      _gosterilenMod = KareModu.normal;
      _mod.value = 0;
      _nefes
        ..stop()
        ..value = 0;
      return;
    }
    _gosterilenMod = mod;
    _mod
      ..value = 0
      ..duration = switch (mod) {
        KareModu.kursun => Sure.kursun,
        _ => Sure.sonme,
      };
    void basla() {
      if (!mounted) return;
      if (widget.azHareket) {
        _mod.value = 1;
        return;
      }
      _mod.forward(from: 0);
      if (mod == KareModu.zirve) _nefes.repeat(reverse: true);
    }

    if (widget.modGecikmesi == Duration.zero || widget.azHareket) {
      basla();
    } else {
      _modZamani = Timer(widget.modGecikmesi, basla);
    }
  }

  @override
  void dispose() {
    _modZamani?.cancel();
    _olay.dispose();
    _mod.dispose();
    _nefes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hepsi,
      builder: (context, _) {
        final hedef = Olcu.kabarma(widget.deger);
        var yuk = hedef;
        var olcek = 1.0;
        var rakamGorunur = 1.0;

        if (_olay.isAnimating) {
          final t = _olay.value;
          switch (_olayTuru) {
            case _Olay.dogma:
              // Çukur → düz (%55), sonra düz → kabarık; rakam ikinci yarıda.
              if (t < 0.55) {
                yuk = lerpDouble(Olcu.cukur, 0, t / 0.55)!;
                rakamGorunur = 0;
              } else {
                final u = (t - 0.55) / 0.45;
                yuk = lerpDouble(0, hedef, Curves.easeOut.transform(u))!;
                rakamGorunur = u;
              }
            case _Olay.yogurma:
              // %35'te içe basılır ve küçülür, sonra yaylanarak kabarır.
              if (t < 0.35) {
                final u = Curves.easeOut.transform(t / 0.35);
                yuk = lerpDouble(_yogurmaBaslangici, -4, u)!;
                olcek = lerpDouble(1, 0.9, u)!;
              } else {
                final u = Curves.easeOutBack.transform((t - 0.35) / 0.65);
                yuk = lerpDouble(-4, hedef, u)!;
                olcek = lerpDouble(0.9, 1, u)!;
              }
            case _Olay.yok:
          }
        }

        final m = Curves.easeOut.transform(_mod.value);
        var rakamRengi = Renk.rakam(widget.deger);
        var opaklik = 1.0;
        switch (_gosterilenMod) {
          case KareModu.normal:
            break;
          case KareModu.sonuk:
            yuk = lerpDouble(yuk, 0, m)!;
            opaklik = lerpDouble(1, 0.4, m)!;
          case KareModu.zirve:
            yuk = lerpDouble(yuk, Olcu.zirve, m)!;
            rakamRengi = Color.lerp(rakamRengi, Renk.vurgu, m)!;
            // Nefes: 1,2 sn'de 1 → 1,07 → 1 (taslak `@keyframes zirve`).
            olcek *= 1 + 0.07 * Curves.easeInOut.transform(_nefes.value);
          case KareModu.kursun:
            yuk = lerpDouble(yuk, Olcu.cukur, m)!;
            rakamRengi = Color.lerp(rakamRengi, Renk.soluk, m)!;
        }

        return Opacity(
          opacity: opaklik,
          child: Transform.scale(
            scale: olcek,
            child: KilYuzey(
              yukseklik: yuk,
              child: Center(
                child: Text(
                  '${widget.deger}',
                  style: Yazi.rakam(
                    widget.deger,
                    renk: rakamRengi.withValues(alpha: rakamGorunur),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
