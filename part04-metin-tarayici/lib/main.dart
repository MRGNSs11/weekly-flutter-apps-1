import 'package:flutter/material.dart';

import 'ui/screens/camera_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
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
