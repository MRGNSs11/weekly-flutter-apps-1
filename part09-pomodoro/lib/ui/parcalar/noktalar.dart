import 'package:flutter/material.dart';

import '../tema.dart';

/// 4 döngü noktası beyaz hapın içinde (PLAN B2.5): dolgu ne kadar yükselirse
/// yükselsin görünür kalır.
class DonguNoktalari extends StatefulWidget {
  const DonguNoktalari({
    super.key,
    required this.dolu,
    required this.aktif,
    required this.renk,
  });

  /// Tamamlanan çalışma sayısı (0–4).
  final int dolu;

  /// Nabız atan nokta (sürmekte olan çalışma), yoksa `null`.
  final int? aktif;
  final Color renk;

  @override
  State<DonguNoktalari> createState() => DonguNoktalariState();
}

class DonguNoktalariState extends State<DonguNoktalari>
    with TickerProviderStateMixin {
  final _anahtarlar = List.generate(4, (_) => GlobalKey());
  late final _nabiz = AnimationController(
    vsync: this,
    duration: Sure.noktaAktif,
  );
  late final _pop = AnimationController(vsync: this, duration: Sure.noktaPop);
  int? _popNokta;

  /// Kutlamada noktanın ekrandaki merkezi (parçacık kaynağı).
  Offset? merkez(int i, RenderBox kok) {
    final kutu = _anahtarlar[i].currentContext?.findRenderObject();
    if (kutu is! RenderBox) return null;
    return kutu.localToGlobal(kutu.size.center(Offset.zero), ancestor: kok);
  }

  /// Nokta dolar: 0,4 → 1,7 → 1 (taslak `noktaPop`).
  void pop(int i) {
    setState(() => _popNokta = i);
    _pop.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nabziAyarla();
  }

  @override
  void didUpdateWidget(DonguNoktalari oldWidget) {
    super.didUpdateWidget(oldWidget);
    _nabziAyarla();
  }

  void _nabziAyarla() {
    final calissin =
        widget.aktif != null && !MediaQuery.disableAnimationsOf(context);
    if (calissin && !_nabiz.isAnimating) {
      _nabiz.repeat();
    } else if (!calissin && _nabiz.isAnimating) {
      _nabiz
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _nabiz.dispose();
    _pop.dispose();
    super.dispose();
  }

  /// %60'a kadar 0,4 → 1,7, sonra 1,7 → 1.
  static double _popOlcek(double t) => t < 0.6
      ? 0.4 + 1.3 * Curves.easeOut.transform(t / 0.6)
      : 1.7 - 0.7 * Curves.easeOut.transform((t - 0.6) / 0.4);

  @override
  Widget build(BuildContext context) {
    final azalt = MediaQuery.disableAnimationsOf(context);
    return Container(
      key: const ValueKey('noktaHapi'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Renk.hap,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            AnimatedBuilder(
              animation: Listenable.merge([_nabiz, _pop]),
              builder: (_, child) {
                var olcek = 1.0;
                if (i == widget.aktif) {
                  // %50'de 1,35 (taslak `noktaAktif`).
                  final t = _nabiz.value;
                  olcek =
                      1 +
                      0.35 *
                          Curves.easeInOut.transform(
                            t < 0.5 ? t * 2 : 2 - t * 2,
                          );
                }
                if (i == _popNokta && _pop.isAnimating) {
                  olcek = _popOlcek(_pop.value);
                }
                return Transform.scale(scale: olcek, child: child);
              },
              child: AnimatedContainer(
                key: _anahtarlar[i],
                duration: azalt
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < widget.dolu ? widget.renk : Colors.transparent,
                  border: Border.all(color: widget.renk, width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
