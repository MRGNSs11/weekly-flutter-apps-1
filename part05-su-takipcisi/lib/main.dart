import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/ana_ekran.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SuTakipcisi());
}

class SuTakipcisi extends StatelessWidget {
  const SuTakipcisi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Su Takipçisi',
      debugShowCheckedModeBanner: false,
      theme: uygulamaTemasi(),
      home: const AnaEkran(),
    );
  }
}
