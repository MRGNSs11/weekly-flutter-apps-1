import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Buzlu cam: arkasındaki suyu bulanıklaştırır, üstüne yarı saydam beyaz
/// dolgu, 1 px çerçeve ve üst kenarda ince ışık çizgisi koyar.
///
/// `BackdropFilter.grouped`: aynı ekrandaki cam parçaları arka planı tek
/// seferde okur (ata widget'ta `BackdropGroup` olmalı). Her kutu ayrı ayrı
/// okusaydı hareketli suyun üstünde üç kat iş olurdu.
class CamKutu extends StatelessWidget {
  const CamKutu({
    super.key,
    required this.child,
    this.yaricap = Olcu.camYaricap,
    this.dolgu = Renk.camDolgu,
    this.icBosluk = EdgeInsets.zero,
  });

  final Widget child;
  final double yaricap;
  final Color dolgu;
  final EdgeInsets icBosluk;

  @override
  Widget build(BuildContext context) {
    final kose = BorderRadius.circular(yaricap);
    return ClipRRect(
      borderRadius: kose,
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: Olcu.camBlur, sigmaY: Olcu.camBlur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dolgu,
            borderRadius: kose,
            border: Border.all(color: Renk.camCerceve),
          ),
          child: Stack(
            children: [
              // CSS: box-shadow: inset 0 1px 0 rgba(255,255,255,.7)
              Positioned(
                top: 1,
                left: yaricap * .6,
                right: yaricap * .6,
                height: 1,
                child: const ColoredBox(color: Renk.camIsik),
              ),
              Padding(padding: icBosluk, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
