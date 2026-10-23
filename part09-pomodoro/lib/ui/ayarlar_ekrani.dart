import 'package:flutter/material.dart';

import '../alan/ayarlar.dart';
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
              deger: _a.calismaDk,
              aralik: Ayarlar.calismaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(calismaDk: v)),
              bitti: (v) => _kaydet(_a.kopya(calismaDk: v)),
            ),
            _SureAyari(
              baslik: 'Kısa mola',
              renk: Renk.mola,
              deger: _a.kisaMolaDk,
              aralik: Ayarlar.kisaMolaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(kisaMolaDk: v)),
              bitti: (v) => _kaydet(_a.kopya(kisaMolaDk: v)),
            ),
            _SureAyari(
              baslik: 'Uzun mola',
              renk: Renk.mola,
              deger: _a.uzunMolaDk,
              aralik: Ayarlar.uzunMolaAralik,
              degisti: (v) => setState(() => _a = _a.kopya(uzunMolaDk: v)),
              bitti: (v) => _kaydet(_a.kopya(uzunMolaDk: v)),
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
  final int deger;
  final (int, int) aralik;
  final ValueChanged<int> degisti;
  final ValueChanged<int> bitti;

  @override
  Widget build(BuildContext context) => _Kart(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(baslik, style: Yazi.inter(15, 600, renk: Renk.yazi)),
            const Spacer(),
            Text(
              '$deger dk',
              style: Yazi.inter(
                15,
                600,
                renk: renk,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        Slider(
          value: deger.toDouble(),
          min: aralik.$1.toDouble(),
          max: aralik.$2.toDouble(),
          divisions: aralik.$2 - aralik.$1,
          activeColor: renk,
          label: '$deger dk',
          semanticFormatterCallback: (v) => '$baslik ${v.round()} dakika',
          onChanged: (v) => degisti(v.round()),
          onChangeEnd: (v) => bitti(v.round()),
        ),
      ],
    ),
  );
}
