import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../alan/baslik.dart';
import '../tema.dart';

/// Izgaradaki not kartı. Kilitliyse üstünde buzlu cam durur; kasa açılınca
/// cam karttın ortasından daire olarak küçülür (D1 + K2).
class NotKarti extends StatefulWidget {
  const NotKarti({
    super.key,
    required this.metin,
    required this.kilitli,
    required this.onTap,
    required this.onLongPress,
    this.sabit = false,
  });

  /// Açık notta içerik; kilitli notta kasa açıksa çözülmüş metin, kapalıysa null.
  final String? metin;
  final bool kilitli;
  final bool sabit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<NotKarti> createState() => _NotKartiState();
}

class _NotKartiState extends State<NotKarti>
    with SingleTickerProviderStateMixin {
  // 0 = cam tam, 1 = cam yok
  late final _acilma = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: _gorunur ? 1 : 0,
  );

  bool get _gorunur => !widget.kilitli || widget.metin != null;

  @override
  void didUpdateWidget(NotKarti eski) {
    super.didUpdateWidget(eski);
    final once = !eski.kilitli || eski.metin != null;
    if (_gorunur && !once) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _acilma.value = 1;
      } else {
        _acilma.forward(from: 0);
      }
    } else if (!_gorunur) {
      _acilma.value = 0; // kapanış anında, içerik zaten gitti
    }
  }

  @override
  void dispose() {
    _acilma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final cerceve = widget.kilitli && widget.metin != null;
    return Semantics(
      button: true,
      label: widget.metin == null ? 'Kilitli not' : baslikCikar(widget.metin!),
      child: Material(
        color: r.kart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: cerceve
              ? BorderSide(color: r.vurgu, width: 2)
              : BorderSide(color: r.cizgi),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: _acilma,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(_acilma.value);
              return Stack(
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: (1 - t) * 6,
                      sigmaY: (1 - t) * 6,
                    ),
                    child: widget.metin == null
                        ? const _SahteCizgiler()
                        : _Icerik(metin: widget.metin!, sabit: widget.sabit),
                  ),
                  if (widget.kilitli && t < 1)
                    Positioned.fill(child: _Cam(oran: 1 - t)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Icerik extends StatelessWidget {
  const _Icerik({required this.metin, required this.sabit});
  final String metin;
  final bool sabit;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final ozet = ozetSatirlari(metin, enFazla: 6);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  baslikCikar(metin),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: yazi(14, kalinlik: FontWeight.w700, renk: r.metin),
                ),
              ),
              if (sabit) Icon(Icons.push_pin_rounded, size: 14, color: r.vurgu),
            ],
          ),
          const SizedBox(height: 2),
          for (final s in ozet) _satir(s, r),
        ],
      ),
    );
  }

  static final _gorev = RegExp(r'^[-*+]\s+\[([ xX])\]\s*');

  /// Görev satırı ikonla çizilir (DM Sans'ta ☑/☐ yok), diğerleri sade metin.
  Widget _satir(String s, Renkler r) {
    final stil = yazi(12, renk: r.soluk, satir: 1.45);
    final g = _gorev.firstMatch(s);
    if (g == null) {
      return Text(
        _sade(s),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: stil,
      );
    }
    final isaretli = g[1] != ' ';
    return Row(
      children: [
        Icon(
          isaretli
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 14,
          color: r.vurgu,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _sade(s.substring(g.end)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: stil.copyWith(
              decoration: isaretli ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Kart önizlemesinde Markdown işaretleri yerine sade karşılıklar.
  static String _sade(String s) => s
      .replaceFirst(RegExp(r'^[-*+]\s+'), '• ')
      .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
      .replaceAll(RegExp(r'\*\*|__|\*|`'), '');
}

/// Kasa kapalıyken camın arkasında gerçek metin yok: içerik şifreli,
/// çözülmedi. Yalnız bulanık çizgiler.
class _SahteCizgiler extends StatelessWidget {
  const _SahteCizgiler();

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    Widget cizgi(double oran) => FractionallySizedBox(
      widthFactor: oran,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: r.soluk.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [cizgi(.7), cizgi(1), cizgi(.5), const SizedBox(height: 14)],
      ),
    );
  }
}

class _Cam extends StatelessWidget {
  const _Cam({required this.oran});
  final double oran; // 1 = tam, 0 = yok

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    return ClipPath(
      clipper: _Daire(oran),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: ColoredBox(
          color: r.cam,
          child: Center(
            child: Opacity(
              opacity: oran.clamp(0, 1),
              child: Icon(Icons.lock_rounded, color: r.vurgu, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ortadan büyüyen/küçülen daire; oran 1'de kartın köşelerini de kaplar.
class _Daire extends CustomClipper<Path> {
  _Daire(this.oran);
  final double oran;

  @override
  Path getClip(Size s) {
    final yaricap = sqrt(s.width * s.width + s.height * s.height) / 2 * oran;
    return Path()..addOval(
      Rect.fromCircle(center: s.center(Offset.zero), radius: yaricap),
    );
  }

  @override
  bool shouldReclip(_Daire eski) => eski.oran != oran;
}
