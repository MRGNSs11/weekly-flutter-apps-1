import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'liste/liste_deposu.dart';
import 'ui/ekranlar/basla_ekrani.dart';
import 'ui/ekranlar/liste_ekrani.dart';
import 'ui/parcalar/kapi.dart';
import 'ui/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // firebase_options.dart depoda yok → lib/firebase_options.dart.ornek
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Kapı ekranın altına kadar uzansın; gezinme çubuğu siyah şerit olmasın.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const OrtakListe());
}

class OrtakListe extends StatelessWidget {
  const OrtakListe({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Ortak Liste',
        debugShowCheckedModeBanner: false,
        theme: tema(),
        home: const Giris(),
      ),
    );
  }
}

/// Açılış: anonim giriş → üyesi olduğum liste var mı? → Başla ya da Liste.
class Giris extends StatefulWidget {
  const Giris({super.key});

  @override
  State<Giris> createState() => _GirisState();
}

class _GirisState extends State<Giris> {
  final _depo = ListeDeposu();
  late Future<void> _oturum = _depo.oturumAc();
  Stream<Liste?>? _listem;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _oturum,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const _Bekle();
        if (s.hasError) {
          return _Sorun(
            onTekrar: () => setState(() => _oturum = _depo.oturumAc()),
          );
        }
        _listem ??= _depo.listemAkisi();
        return StreamBuilder<Liste?>(
          stream: _listem,
          builder: (context, l) {
            if (l.hasError) {
              return _Sorun(
                onTekrar: () => setState(() => _listem = _depo.listemAkisi()),
              );
            }
            if (!l.hasData && l.connectionState == ConnectionState.waiting) {
              return const _Bekle();
            }
            final liste = l.data;
            return liste == null
                ? BaslaEkrani(depo: _depo)
                : ListeEkrani(
                    key: ValueKey(liste.id),
                    depo: _depo,
                    liste: liste,
                  );
          },
        );
      },
    );
  }
}

class _Bekle extends StatelessWidget {
  const _Bekle();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Kapi(
        rozet: true,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Renk.kiraz),
          ),
        ),
      ),
    );
  }
}

class _Sorun extends StatelessWidget {
  const _Sorun({required this.onTekrar});

  final VoidCallback onTekrar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Kapi(
        rozet: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 30, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bağlanamadı.\nİnterneti kontrol edip tekrar dene.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Renk.murekkep),
                ),
                const SizedBox(height: 16),
                AnaDugme(yazi: 'Tekrar dene', onTap: onTekrar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
