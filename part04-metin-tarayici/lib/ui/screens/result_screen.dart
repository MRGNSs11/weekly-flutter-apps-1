import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Çekilen kare ve ondan okunan metin.
///
/// ADIM 1'DE İSKELET: kare gösteriliyor, metin tanıma Adım 2'de bağlanacak.
/// Kopyala/Paylaş düğmeleri o zamana kadar kapalı — çalışmayan düğme
/// göstermek, düğmeyi hiç göstermemekten kötüdür.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.karePath});

  final String karePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UstCubuk(onYeniden: () => Navigator.of(context).pop()),
            SizedBox(
              height: AppSizes.sonucSerit,
              child: ColoredBox(
                color: AppColors.preview,
                child: Image.file(File(karePath), fit: BoxFit.cover),
              ),
            ),
            const Expanded(child: _MetinAlani()),
            const _Eylemler(),
          ],
        ),
      ),
    );
  }
}

class _UstCubuk extends StatelessWidget {
  const _UstCubuk({required this.onYeniden});

  final VoidCallback onYeniden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.kenar,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Okunan metin', style: Theme.of(context).textTheme.titleMedium),
          TextButton(
            onPressed: onYeniden,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Yeniden çek'),
          ),
        ],
      ),
    );
  }
}

class _MetinAlani extends StatelessWidget {
  const _MetinAlani();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.kenar),
      child: Text(
        'Metin tanıma bir sonraki adımda bağlanacak.',
        style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.muted),
      ),
    );
  }
}

class _Eylemler extends StatelessWidget {
  const _Eylemler();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.kenar,
        12,
        AppSizes.kenar,
        18,
      ),
      child: Row(
        children: [
          Expanded(child: FilledButton(onPressed: null, child: Text('Kopyala'))),
          SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: null, child: Text('Paylaş'))),
        ],
      ),
    );
  }
}
