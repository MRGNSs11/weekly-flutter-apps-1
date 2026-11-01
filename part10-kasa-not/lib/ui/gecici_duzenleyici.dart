import 'package:flutter/material.dart';

import '../alan/not.dart';
import '../uygulama/kasa_kontrol.dart';
import '../uygulama/notlar_kontrol.dart';
import 'tema.dart';

/// K4 için geçici yazma ekranı: K5'te bölünmüş düzenleyiciyle değişir.
/// Geri tuşunda kaydeder; boş yeni not kaydedilmez.
class GeciciDuzenleyici extends StatefulWidget {
  const GeciciDuzenleyici({
    super.key,
    required this.not,
    required this.ilkMetin,
    required this.notlar,
    required this.kasa,
  });

  final Not? not;
  final String ilkMetin;
  final NotlarKontrol notlar;
  final KasaKontrol kasa;

  @override
  State<GeciciDuzenleyici> createState() => _GeciciDuzenleyiciState();
}

class _GeciciDuzenleyiciState extends State<GeciciDuzenleyici> {
  late final _metin = TextEditingController(text: widget.ilkMetin);

  Future<void> _kaydet() async {
    final m = _metin.text;
    final n = widget.not;
    if (n == null) {
      if (m.trim().isNotEmpty) await widget.notlar.depo.ekle(m);
    } else if (m != widget.ilkMetin) {
      n.kilitli
          ? await widget.kasa.kilitliKaydet(n.id, m)
          : await widget.notlar.depo.guncelle(n.id, m);
    }
  }

  @override
  void dispose() {
    _metin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    return PopScope(
      onPopInvokedWithResult: (_, _) => _kaydet(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Not (geçici ekran)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _metin,
            maxLines: null,
            expands: true,
            autofocus: widget.not == null,
            style: yazi(14, mono: true, renk: r.metin),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ),
    );
  }
}
