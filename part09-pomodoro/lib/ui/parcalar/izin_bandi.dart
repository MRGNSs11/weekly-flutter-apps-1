import 'package:flutter/material.dart';

import '../../uygulama/pomodoro_kontrol.dart';
import '../tema.dart';

const _metinler = {
  Bant.bildirimKapali: ('Bildirimler kapalı', 'Ayarları aç'),
  Bant.kesinYok: ('Uyarı birkaç dakika gecikebilir', 'İzin ver'),
  Bant.tamEkranYok: ('Kilit ekranında alarm açılamaz', 'İzin ver'),
};

/// Üstten kayarak giren izin bandı (PLAN K6.7, B2.4: 300 ms).
class IzinBandi extends StatefulWidget {
  const IzinBandi({super.key, required this.bant, required this.onTap});

  final Bant? bant;
  final VoidCallback onTap;

  @override
  State<IzinBandi> createState() => _IzinBandiState();
}

class _IzinBandiState extends State<IzinBandi> {
  /// Kayarak çıkarken metin kaybolmasın.
  Bant? _son;

  @override
  Widget build(BuildContext context) {
    final azalt = MediaQuery.disableAnimationsOf(context);
    final acik = widget.bant != null;
    _son = widget.bant ?? _son;
    final m = _metinler[_son];
    final sure = azalt ? Duration.zero : Sure.bant;
    // Taslak: cubic-bezier(.2,.9,.3,1.2), hafif taşma.
    const egri = Cubic(0.2, 0.9, 0.3, 1.2);
    return IgnorePointer(
      ignoring: !acik,
      child: AnimatedSlide(
        offset: acik ? Offset.zero : const Offset(0, -1.6),
        duration: sure,
        curve: egri,
        child: AnimatedOpacity(
          opacity: acik ? 1 : 0,
          duration: sure,
          child: m == null
              ? const SizedBox.shrink()
              : GestureDetector(
                  key: const ValueKey('izinBandi'),
                  onTap: widget.onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Renk.yazi,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: Yazi.inter(12, 500, renk: Renk.bantYazi),
                        children: [
                          TextSpan(text: '${m.$1} · '),
                          TextSpan(
                            text: m.$2,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Renk.bantYazi,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
