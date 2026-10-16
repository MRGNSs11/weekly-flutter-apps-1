import 'package:flutter/material.dart';

import '../oyun/oyun_notifier.dart';
import 'parcalar.dart';
import 'tema.dart';

/// Tahtanın üstüne açılan "2048!" ya da "Hamle kalmadı" katmanı.
class OyunKatmani extends StatelessWidget {
  const OyunKatmani({
    super.key,
    required this.tur,
    required this.skor,
    required this.devamEt,
    required this.geriAl,
    required this.yeniOyun,
  });

  final Katman tur;
  final int skor;
  final VoidCallback devamEt;
  final VoidCallback geriAl;
  final VoidCallback yeniOyun;

  @override
  Widget build(BuildContext context) {
    final kazandi = tur == Katman.kazandi;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(
        color: Renk.zemin.withValues(alpha: 0.86),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kazandi ? '2048!' : 'Hamle kalmadı',
                  textAlign: TextAlign.center,
                  style: kazandi ? Yazi.katmanBaslik : Yazi.katmanBitti,
                ),
                const SizedBox(height: 10),
                Text(
                  kazandi
                      ? 'Başardın. İstersen devam et.'
                      : 'Skor ${binlik(skor)}',
                  style: Yazi.katmanMetin,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    kazandi
                        ? KilDugme(
                            yazi: 'Devam et',
                            onTap: devamEt,
                            genis: false,
                          )
                        : KilDugme(
                            yazi: 'Geri al',
                            ikon: Icons.undo_rounded,
                            onTap: geriAl,
                            genis: false,
                          ),
                    const SizedBox(width: 14),
                    KilDugme(
                      yazi: 'Yeni oyun',
                      onTap: yeniOyun,
                      vurgulu: true,
                      genis: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
