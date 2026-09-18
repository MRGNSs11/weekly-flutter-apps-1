import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kadraj nişangahı: dört köşe parçası.
///
/// Taslaktaki sarı, beyaz kâğıdın üstünde kaybolabiliyor (taslağın kendi risk
/// notu). Renk aynı kaldı, altına ince koyu gölge eklendi — PLAN.md B2.4 / 3.
class Viewfinder extends StatelessWidget {
  const Viewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Stack(
          children: const [
            Positioned(top: 0, left: 0, child: _Kose(ust: true, sol: true)),
            Positioned(top: 0, right: 0, child: _Kose(ust: true, sol: false)),
            Positioned(bottom: 0, left: 0, child: _Kose(ust: false, sol: true)),
            Positioned(
              bottom: 0,
              right: 0,
              child: _Kose(ust: false, sol: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kose extends StatelessWidget {
  const _Kose({required this.ust, required this.sol});

  final bool ust;
  final bool sol;

  @override
  Widget build(BuildContext context) {
    const kenar = BorderSide(
      color: AppColors.accent,
      width: AppSizes.nisanKalinlik,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: Container(
        width: AppSizes.nisanKose,
        height: AppSizes.nisanKose,
        decoration: BoxDecoration(
          border: Border(
            top: ust ? kenar : BorderSide.none,
            bottom: ust ? BorderSide.none : kenar,
            left: sol ? kenar : BorderSide.none,
            right: sol ? BorderSide.none : kenar,
          ),
        ),
      ),
    );
  }
}
