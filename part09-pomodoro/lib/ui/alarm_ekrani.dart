import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bildirim/bildirim_metinleri.dart';
import '../uygulama/pomodoro_kontrol.dart';
import 'tema.dart';

/// "Süre doldu" (PLAN K6.9): sıradaki fazın rengiyle tam dolu ekran.
/// Telefon kilitliyse kilidin üstünde açılır.
class AlarmEkrani extends StatelessWidget {
  const AlarmEkrani({super.key, required this.kontrol});

  final PomodoroKontrol kontrol;

  @override
  Widget build(BuildContext context) {
    final d = kontrol.durum;
    final renk = Renk.faz(d.faz);
    final sure = sureYazisi(kontrol.ayarlar.sure(d.faz).inSeconds);
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Material(
        key: const ValueKey('alarmEkrani'),
        color: renk,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Süre doldu',
                  textAlign: TextAlign.center,
                  style: Yazi.rakam.copyWith(
                    fontSize: 56,
                    letterSpacing: -2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bittiBasligi[d.faz]!,
                  textAlign: TextAlign.center,
                  style: Yazi.inter(20, 600, renk: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sıradaki: ${fazAdi[d.faz]} · $sure · Bugün ${kontrol.bugun}',
                  textAlign: TextAlign.center,
                  style: Yazi.inter(15, 500, renk: Colors.white70),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: renk,
                    minimumSize: const Size.fromHeight(72),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    kontrol.eylemYap('baslat');
                  },
                  child: Text('Sıradakini başlat', style: Yazi.inter(20, 600)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(64),
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: kontrol.alarmiDurdur,
                  child: Text('Durdur', style: Yazi.inter(18, 600)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
