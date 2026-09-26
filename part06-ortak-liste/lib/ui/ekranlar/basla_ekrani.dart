import 'package:flutter/material.dart';

import '../../liste/liste_deposu.dart';
import '../parcalar/kapi.dart';
import '../parcalar/karo.dart';
import '../parcalar/kod_girisi.dart';
import '../tema.dart';

/// Listesi olmayan kişinin gördüğü ekran: yeni liste aç ya da kodla katıl.
/// Başarılı olunca buradan bir yere gidilmiyor — `listemAkisi` yeni listeyi
/// görür, üstteki StreamBuilder Liste ekranına geçer.
class BaslaEkrani extends StatefulWidget {
  const BaslaEkrani({super.key, required this.depo});

  final ListeDeposu depo;

  @override
  State<BaslaEkrani> createState() => _BaslaEkraniState();
}

class _BaslaEkraniState extends State<BaslaEkrani> {
  final _kod = TextEditingController();
  bool _mesgul = false;
  String? _hata;

  @override
  void dispose() {
    _kod.dispose();
    super.dispose();
  }

  Future<void> _calistir(Future<void> Function() is_) async {
    if (_mesgul) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mesgul = true;
      _hata = null;
    });
    try {
      await is_();
    } on ListeHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Bir sorun çıktı. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _mesgul = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Kapi(
        rozet: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, kisit) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: kisit.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 30, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KaroSatiri('ortak', buyuk: true),
                          SizedBox(height: 6),
                          KaroSatiri('liste', buyuk: true),
                          SizedBox(height: 12),
                          Text(
                            'Aynı listeyi iki telefonda gör. Hesap yok.',
                            style: TextStyle(fontSize: 13, color: Renk.soluk),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      AnaDugme(
                        yazi: 'Yeni liste oluştur',
                        mesgul: _mesgul,
                        onTap: () => _calistir(widget.depo.olustur),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ya da koda katıl',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Renk.soluk),
                      ),
                      const SizedBox(height: 14),
                      KodGirisi(
                        denetleyici: _kod,
                        onTamam: () =>
                            _calistir(() => widget.depo.katil(_kod.text)),
                      ),
                      const SizedBox(height: 14),
                      _IkinciDugme(
                        yazi: 'Katıl',
                        onTap: _mesgul
                            ? null
                            : () =>
                                  _calistir(() => widget.depo.katil(_kod.text)),
                      ),
                      if (_hata != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _hata!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Renk.kiraz,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kiraz zemin, krem yazı, köşesiz (taslak .b-ana).
class AnaDugme extends StatelessWidget {
  const AnaDugme({
    super.key,
    required this.yazi,
    required this.onTap,
    this.mesgul = false,
  });

  final String yazi;
  final VoidCallback onTap;
  final bool mesgul;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x73000000), // .45
            offset: Offset(0, 6),
            blurRadius: 10,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Material(
        color: Renk.kiraz,
        child: InkWell(
          onTap: mesgul ? null : onTap,
          splashColor: Renk.kirazKoyu.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Text(
              mesgul ? '…' : yazi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Renk.krem,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IkinciDugme extends StatelessWidget {
  const _IkinciDugme({required this.yazi, required this.onTap});

  final String yazi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Renk.murekkep, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Text(
            yazi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Renk.murekkep,
            ),
          ),
        ),
      ),
    );
  }
}
