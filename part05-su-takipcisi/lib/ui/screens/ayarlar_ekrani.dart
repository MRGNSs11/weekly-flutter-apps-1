import 'package:flutter/material.dart';

import '../../su/gunluk_durum.dart';
import '../../su/su_deposu.dart';
import '../theme/app_theme.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  GunlukDurum? _durum;

  @override
  void initState() {
    super.initState();
    SuDeposu.oku().then((d) {
      if (mounted) setState(() => _durum = d);
    });
  }

  Future<void> _degistir(GunlukDurum Function(GunlukDurum) islem) async {
    final yeni = await SuDeposu.degistir(islem);
    if (mounted) setState(() => _durum = yeni);
  }

  @override
  Widget build(BuildContext context) {
    final durum = _durum;
    return Scaffold(
      backgroundColor: Renk.bgUst,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Text('Ayarlar', style: sora(15, kalinlik: 600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Kapat', style: sora(12, renk: Renk.muted)),
                  ),
                ],
              ),
            ),
            if (durum != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Satir(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Günlük hedef',
                                  style: sora(12.5, kalinlik: 600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kaç bardak içmek istiyorsun?',
                                  style: sora(11, renk: Renk.muted),
                                ),
                              ],
                            ),
                          ),
                          _AdimDugmesi(
                            simge: Icons.remove,
                            anlam: 'Hedefi azalt',
                            onTap: durum.hedef > GunlukDurum.enAzHedef
                                ? () => _degistir(
                                    (d) => d.hedefiDegistir(d.hedef - 1),
                                  )
                                : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${durum.hedef}',
                              textAlign: TextAlign.center,
                              style: sora(12.5, kalinlik: 700),
                            ),
                          ),
                          _AdimDugmesi(
                            simge: Icons.add,
                            anlam: 'Hedefi artır',
                            onTap: durum.hedef < GunlukDurum.enFazlaHedef
                                ? () => _degistir(
                                    (d) => d.hedefiDegistir(d.hedef + 1),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    _Satir(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bardak boyutu',
                            style: sora(12.5, kalinlik: 600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final ml in GunlukDurum.bardakSecenekleri)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                    ),
                                    child: _Hap(
                                      yazi: '$ml',
                                      secili: durum.bardakMl == ml,
                                      onTap: () => _degistir(
                                        (d) => d.bardagiDegistir(ml),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Widget eklemek için: ana ekrana basılı tut → '
                      "Widget'lar → Su Takipçisi. Sayım her gece 00:00'da sıfırlanır.",
                      style: sora(11, renk: Renk.muted, satir: 1.6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Renk.line)),
    ),
    child: child,
  );
}

class _AdimDugmesi extends StatelessWidget {
  const _AdimDugmesi({
    required this.simge,
    required this.anlam,
    required this.onTap,
  });

  final IconData simge;
  final String anlam;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Görünen daire 28, dokunma alanı 44.
    return Semantics(
      button: true,
      label: anlam,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Renk.line),
              ),
              child: Icon(
                simge,
                size: 16,
                color: onTap == null ? Renk.line : Renk.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hap extends StatelessWidget {
  const _Hap({required this.yazi, required this.secili, required this.onTap});

  final String yazi;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: secili,
      label: '$yazi mililitre',
      excludeSemantics: true,
      child: Material(
        color: secili ? Renk.accent : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: secili ? Renk.accent : Renk.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                yazi,
                style: sora(
                  11.5,
                  kalinlik: secili ? 600 : 400,
                  renk: secili ? Colors.white : Renk.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
