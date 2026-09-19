import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/camera_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  // Dikey kilit. Cihazda bulundu: telefon yan çevrilince önizleme ince bir
  // şeride sıkışıyor, nişangah köşeleri anlamsız yerlere düşüyordu.
  // Onaylı taslak (tasarimlar.html) baştan sona dikey telefon maketi;
  // yatay düzen hiç tasarlanmadı, o yüzden tasarlanmamış bir düzeni
  // göstermek yerine kapatıyoruz.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MetinTarayiciApp());
}

class MetinTarayiciApp extends StatelessWidget {
  const MetinTarayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metin Tarayıcı',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const CameraScreen(),
    );
  }
}
