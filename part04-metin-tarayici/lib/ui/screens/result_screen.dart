import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../ocr/metin_tanima.dart';
import '../theme/app_theme.dart';

/// Çekilen kare ve ondan okunan metin.
///
/// Tanıma bu ekran açılır açılmaz başlıyor: kullanıcıya ayrıca "tara"
/// dedirtmenin bir anlamı yok, zaten bunun için çekti.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.karePath});

  final String karePath;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

enum _Durum { okunuyor, dolu, bos, hata }

class _ResultScreenState extends State<ResultScreen> {
  final MetinTanima _tanima = MetinTanima();
  final TextEditingController _metin = TextEditingController();

  _Durum _durum = _Durum.okunuyor;
  int _kelimeSayisi = 0;
  String _hata = '';

  @override
  void initState() {
    super.initState();
    _oku();
  }

  @override
  void dispose() {
    _metin.dispose();
    // Modeli serbest bırakmazsak her çekimde bellekte bir tanıyıcı birikir.
    _tanima.kapat();
    super.dispose();
  }

  Future<void> _oku() async {
    setState(() => _durum = _Durum.okunuyor);
    try {
      final sonuc = await _tanima.dosyadanOku(widget.karePath);
      if (!mounted) return;
      setState(() {
        _metin.text = sonuc.metin;
        _kelimeSayisi = sonuc.kelimeSayisi;
        _durum = sonuc.doluMu ? _Durum.dolu : _Durum.bos;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _durum = _Durum.hata;
        _hata = error.message ?? 'Metin tanıma çalıştırılamadı.';
      });
    }
  }

  Future<void> _kopyala() async {
    await Clipboard.setData(ClipboardData(text: _metin.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Metin panoya kopyalandı')));
  }

  Future<void> _paylas() async {
    // Paylaşılan şey metin; fotoğraf hiçbir yere gitmiyor.
    await SharePlus.instance.share(ShareParams(text: _metin.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UstCubuk(onYeniden: () => Navigator.of(context).pop()),
            _KareSeridi(karePath: widget.karePath),
            Expanded(child: _govde()),
            _Eylemler(
              etkin: _durum == _Durum.dolu,
              onKopyala: _kopyala,
              onPaylas: _paylas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _govde() {
    switch (_durum) {
      case _Durum.okunuyor:
        return const _Okunuyor();
      case _Durum.dolu:
        return _MetinAlani(kelimeSayisi: _kelimeSayisi, kontrol: _metin);
      case _Durum.bos:
        return const _Durumu(
          baslik: 'Metin bulunamadı',
          aciklama:
              'Yazı çerçevenin içinde ve net olsun. Işık az geliyorsa alt '
              'çubuktaki Işık düğmesi yardımcı olur.',
        );
      case _Durum.hata:
        return _Durumu(baslik: 'Okunamadı', aciklama: _hata, onTekrar: _oku);
    }
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

class _KareSeridi extends StatelessWidget {
  const _KareSeridi({required this.karePath});

  final String karePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.sonucSerit,
      child: ColoredBox(
        color: AppColors.preview,
        child: Image.file(File(karePath), fit: BoxFit.cover),
      ),
    );
  }
}

class _Okunuyor extends StatelessWidget {
  const _Okunuyor();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.kenar),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Okunuyor…',
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Okunan metin: sayaç + düzenlenebilir gövde.
///
/// Salt okunur `Text` yerine çerçevesiz bir alan: model `ı/İ` gibi harfleri
/// karıştırabiliyor, kullanıcının kopyalamadan önce düzeltebilmesi gerekiyor.
/// Taslaktaki sarı `<mark>` burada seçim rengi olarak karşılık buluyor.
class _MetinAlani extends StatelessWidget {
  const _MetinAlani({required this.kelimeSayisi, required this.kontrol});

  final int kelimeSayisi;
  final TextEditingController kontrol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.kenar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '$kelimeSayisi kelime okundu',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: kontrol,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Metni düzeltebilirsin',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Metin bulunamadı ve hata halleri — taslakta çizilmeyen iki ekran
/// (PLAN.md B2.4 / 4). Yeni renk veya biçim girmiyor.
class _Durumu extends StatelessWidget {
  const _Durumu({
    required this.baslik,
    required this.aciklama,
    this.onTekrar,
  });

  final String baslik;
  final String aciklama;
  final VoidCallback? onTekrar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.kenar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(width: 48, height: 12, color: AppColors.accent),
          const SizedBox(height: 20),
          Text(baslik, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            aciklama,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
          if (onTekrar != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onTekrar,
              child: const Text('Tekrar dene'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Eylemler extends StatelessWidget {
  const _Eylemler({
    required this.etkin,
    required this.onKopyala,
    required this.onPaylas,
  });

  final bool etkin;
  final VoidCallback onKopyala;
  final VoidCallback onPaylas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.kenar,
        12,
        AppSizes.kenar,
        18,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: etkin ? onKopyala : null,
              child: const Text('Kopyala'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: etkin ? onPaylas : null,
              child: const Text('Paylaş'),
            ),
          ),
        ],
      ),
    );
  }
}
