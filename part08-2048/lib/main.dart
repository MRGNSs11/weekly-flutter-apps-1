import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oyun/oyun_notifier.dart';
import 'oyun/kayit_deposu.dart';
import 'ui/oyun_ekrani.dart';
import 'ui/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [kayitDeposuProvider.overrideWithValue(KayitDeposu(prefs))],
      child: const Uygulama(),
    ),
  );
}

class Uygulama extends StatelessWidget {
  const Uygulama({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Renk.zemin,
    ),
    child: MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: temaKur(),
      home: const OyunEkrani(),
    ),
  );
}
