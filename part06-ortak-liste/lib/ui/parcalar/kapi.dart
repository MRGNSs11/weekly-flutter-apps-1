import 'package:flutter/material.dart';

import '../tema.dart';

/// Buzdolabı kapısı: pastel gradyan zemin + sağda krom kulp.
/// `rozet`: yalnız Başla ekranında, sol altta "Ortak · 1956" (süs).
class Kapi extends StatelessWidget {
  const Kapi({super.key, required this.child, this.rozet = false});

  final Widget child;
  final bool rozet;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // CSS 100° ≈ soldan sağa, hafif aşağı eğik
        gradient: LinearGradient(
          begin: Alignment(-1, -0.18),
          end: Alignment(1, 0.18),
          colors: Renk.kapi,
          stops: Renk.kapiDuraklari,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(right: 10, top: 100, child: _Kulp()),
          if (rozet)
            const Positioned(
              left: 20,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: Text(
                  'Ortak · 1956',
                  style: TextStyle(
                    fontFamily: Yazi.serif,
                    fontStyle: FontStyle.italic,
                    fontVariations: [FontVariation('wght', 700)],
                    fontSize: 11,
                    letterSpacing: 0.9,
                    color: Renk.rozet,
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Kulp extends StatelessWidget {
  const _Kulp();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: Renk.kulp,
          stops: Renk.kulpDuraklari,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
