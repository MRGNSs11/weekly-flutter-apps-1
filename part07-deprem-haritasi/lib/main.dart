import 'package:flutter/material.dart';

import 'ui/ana_ekran.dart';
import 'ui/tema.dart';

void main() => runApp(const DepremUygulamasi());

class DepremUygulamasi extends StatelessWidget {
  const DepremUygulamasi({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Deprem',
    debugShowCheckedModeBanner: false,
    theme: temaKur(),
    home: const AnaEkran(),
  );
}
