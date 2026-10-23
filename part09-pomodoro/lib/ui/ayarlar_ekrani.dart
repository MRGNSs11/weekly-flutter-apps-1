import 'package:flutter/material.dart';

import '../alan/ayarlar.dart';
import '../bildirim/bildirim_metinleri.dart';
import '../uygulama/pomodoro_kontrol.dart';
import 'parcalar/butonlar.dart';
import 'tema.dart';

/// 3 süre + ses (PLAN K5). Değer bırakınca kaydedilir. Çalışan faz
/// etkilenmez, yeni süre sonraki başlatmada geçerli olur.
class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key, required this.kontrol});

  final PomodoroKontrol kontrol;

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  late Ayarlar _a = widget.kontrol.ayarlar;

  void _kaydet(Ayarlar a) {
    setState(() => _a = a);
    widget.kontrol.ayarlariDegistir(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Renk.zemin,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            Row(
              children: [
                HapDugme(
                  etiket: 'Geri',
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Ayarlar', style: Yazi.inter(20, 600, renk: Renk.yazi)),
              ],
            ),
            const SizedBox(height: 24),
            _SureAyari(
              baslik: 'Çalışma',
              renk: Renk.vurgu,
              deger: _a.calismaSn,
              aralik: Ayarlar.calismaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(calismaSn: v)),
              bitti: (v) => _kaydet(_a.kopya(calismaSn: v)),
            ),
            _SureAyari(
              baslik: 'Kısa mola',
              renk: Renk.mola,
              deger: _a.kisaMolaSn,
              aralik: Ayarlar.kisaMolaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(kisaMolaSn: v)),
              bitti: (v) => _kaydet(_a.kopya(kisaMolaSn: v)),
            ),
            _SureAyari(
              baslik: 'Uzun mola',
              renk: Renk.mola,
              deger: _a.uzunMolaSn,
              aralik: Ayarlar.uzunMolaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(uzunMolaSn: v)),
              bitti: (v) => _kaydet(_a.kopya(uzunMolaSn: v)),
            ),
            const SizedBox(height: 8),
            _Kart(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.white,
                activeTrackColor: Renk.vurgu,
                title: Text(
                  'Süre dolunca alarm sesi',
                  style: Yazi.inter(15, 600, renk: Renk.yazi),
                ),
                subtitle: Text(
                  'Kapalıyken ekran yine açılır, ses çalmaz.',
                  style: Yazi.inter(
                    12,
                    500,
                    renk: Renk.yazi.withValues(alpha: 0.65),
                  ),
                ),
                value: _a.ses,
                onChanged: (v) => _kaydet(_a.kopya(ses: v)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yeni süreler bir sonraki başlatmada geçerli olur.',
              style: Yazi.inter(
                12,
                500,
                renk: Renk.yazi.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: BoxDecoration(
      color: Renk.hap,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

/// Bir süre: dakika kaydırıcısı + saniye kaydırıcısı (5'er sn).
class _SureAyari extends StatelessWidget {
  const _SureAyari({
    required this.baslik,
    required this.renk,
    required this.deger,
    required this.aralik,
    required this.degisti,
    required this.bitti,
  });

  final String baslik;
  final Color renk;

  /// Saniye.
  final int deger;
  final (int, int) aralik;
  final ValueChanged<int> degisti;
  final ValueChanged<int> bitti;

  int _sinirla(int sn) => sn.clamp(aralik.$1, aralik.$2);

  @override
  Widget build(BuildContext context) {
    final dk = deger ~/ 60;
    final sn = deger % 60;
    final enCokDk = aralik.$2 ~/ 60;
    return _Kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(baslik, style: Yazi.inter(15, 600, renk: Renk.yazi)),
              const Spacer(),
              Text(
                sureYazisi(deger),
                style: Yazi.inter(
                  15,
                  600,
                  renk: renk,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          _Satir(
            ad: 'dk',
            child: Slider(
              value: dk.toDouble(),
              max: enCokDk.toDouble(),
              divisions: enCokDk,
              activeColor: renk,
              label: '$dk dk',
              semanticFormatterCallback: (v) => '$baslik ${v.round()} dakika',
              onChanged: (v) => degisti(_sinirla(v.round() * 60 + sn)),
              onChangeEnd: (v) => bitti(_sinirla(v.round() * 60 + sn)),
            ),
          ),
          _Satir(
            ad: 'sn',
            child: Slider(
              value: sn.toDouble(),
              max: 55,
              divisions: 11,
              activeColor: renk,
              label: '$sn sn',
              semanticFormatterCallback: (v) => '$baslik ${v.round()} saniye',
              onChanged: (v) => degisti(_sinirla(dk * 60 + v.round())),
              onChangeEnd: (v) => bitti(_sinirla(dk * 60 + v.round())),
            ),
          ),
        ],
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.ad, required this.child});
  final String ad;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 22,
        child: Text(
          ad,
          style: Yazi.inter(12, 500, renk: Renk.yazi.withValues(alpha: 0.65)),
        ),
      ),
      Expanded(child: child),
    ],
  );
}
