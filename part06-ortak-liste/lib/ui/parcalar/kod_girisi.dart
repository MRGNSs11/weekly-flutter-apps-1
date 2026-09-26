import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../liste/kod.dart';
import '../tema.dart';

/// 6 kutulu kod girişi. Taslakta 6 ayrı kutu var; burada tek gizli
/// TextField'ın üstüne 6 kutu çiziliyor (PLAN.md B2.5 sapma 1) — böylece
/// yapıştırma, geri silme ve klavye tek alanda doğal çalışıyor.
class KodGirisi extends StatefulWidget {
  const KodGirisi({super.key, required this.denetleyici, this.onTamam});

  final TextEditingController denetleyici;
  final VoidCallback? onTamam;

  @override
  State<KodGirisi> createState() => _KodGirisiState();
}

class _KodGirisiState extends State<KodGirisi> {
  final _odak = FocusNode();

  @override
  void dispose() {
    _odak.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Liste kodu, 6 hane',
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([widget.denetleyici, _odak]),
            builder: (context, _) {
              final metin = widget.denetleyici.text;
              final aktif = metin.length.clamp(0, Kod.uzunluk - 1);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < Kod.uzunluk; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    _Kutu(
                      harf: i < metin.length ? metin[i] : '',
                      secili: _odak.hasFocus && i == aktif,
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: TextField(
              controller: widget.denetleyici,
              focusNode: _odak,
              showCursor: false,
              enableInteractiveSelection: false,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => widget.onTamam?.call(),
              onChanged: (m) {
                if (m.length == Kod.uzunluk) widget.onTamam?.call();
              },
              inputFormatters: [
                TextInputFormatter.withFunction((eski, yeni) {
                  final s = Kod.suz(yeni.text);
                  return TextEditingValue(
                    text: s,
                    selection: TextSelection.collapsed(offset: s.length),
                  );
                }),
              ],
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kutu extends StatelessWidget {
  const _Kutu({required this.harf, required this.secili});

  final String harf;
  final bool secili;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Renk.krem,
        border: Border.all(
          color: secili ? Renk.kiraz : Renk.girdiKenar,
          width: secili ? 2 : 1.5,
        ),
      ),
      child: Text(
        harf,
        style: const TextStyle(
          fontFamily: Yazi.karo,
          fontSize: 18,
          color: Renk.murekkep,
        ),
      ),
    );
  }
}
