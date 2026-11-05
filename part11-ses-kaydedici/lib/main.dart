// K1 risk denemesi: tek ekran. Telefonda D1 risklerini ölçmek için.
// K4'te silinir.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

void main() => runApp(const DenemeUygulamasi());

class DenemeUygulamasi extends StatelessWidget {
  const DenemeUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ses Kaydedici',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const DenemeEkrani(),
    );
  }
}

class DenemeEkrani extends StatefulWidget {
  const DenemeEkrani({super.key});

  @override
  State<DenemeEkrani> createState() => _DenemeEkraniState();
}

class _DenemeEkraniState extends State<DenemeEkrani> {
  static const _servis = MethodChannel('seskaydedici/servis');
  static const _aralik = Duration(milliseconds: 50);

  final _kaydedici = AudioRecorder();
  final _calar = AudioPlayer();
  final _sure = Stopwatch();
  final List<double> _cubuklar = [];
  final List<String> _kayit = [];

  late final AppLifecycleListener _yasam;
  StreamSubscription<Amplitude>? _genlikAbone;
  StreamSubscription<RecordState>? _durumAbone;
  Timer? _saat;

  RecordState _durum = RecordState.stop;
  bool _onde = true;
  int _genlikToplam = 0;
  int _genlikArkada = 0;
  double _sonDb = -160;
  String? _dosya;
  String _dosyaBilgi = '';
  Duration? _calarSure;
  double _hiz = 1;

  @override
  void initState() {
    super.initState();
    _yasam = AppLifecycleListener(
      onStateChange: (s) {
        _onde = s == AppLifecycleState.resumed;
        _yaz('yaşam: ${s.name}');
      },
    );
    _durumAbone = _kaydedici.onStateChanged().listen((s) {
      _durum = s;
      s == RecordState.record ? _sure.start() : _sure.stop();
      _yaz('kayıt durumu: ${s.name}');
    });
  }

  @override
  void dispose() {
    _yasam.dispose();
    _genlikAbone?.cancel();
    _durumAbone?.cancel();
    _saat?.cancel();
    _kaydedici.dispose();
    _calar.dispose();
    super.dispose();
  }

  void _yaz(String olay) {
    final t = DateTime.now();
    String iki(int n) => n.toString().padLeft(2, '0');
    final saat = '${iki(t.hour)}:${iki(t.minute)}:${iki(t.second)}';
    if (!mounted) return;
    setState(() => _kayit.insert(0, '$saat  $olay'));
  }

  Future<void> _kaydet() async {
    if (!await _kaydedici.hasPermission()) {
      _yaz('mikrofon izni YOK');
      return;
    }
    await _servis.invokeMethod('bildirimIzniIste');
    final bildirim = await _servis.invokeMethod<bool>('bildirimIzniVar');
    _yaz('bildirim izni: $bildirim');

    final klasor = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/kayitlar',
    );
    await klasor.create(recursive: true);
    final yol =
        '${klasor.path}/deneme_${DateTime.now().millisecondsSinceEpoch}.ogg';

    await _calar.stop();
    await _servis.invokeMethod('baslat');
    _cubuklar.clear();
    _genlikToplam = 0;
    _genlikArkada = 0;
    _sure.reset();
    await _kaydedici.start(
      const RecordConfig(
        encoder: AudioEncoder.opus,
        bitRate: 32000,
        sampleRate: 48000,
        numChannels: 1,
      ),
      path: yol,
    );
    _genlikAbone = _kaydedici.onAmplitudeChanged(_aralik).listen((g) {
      _genlikToplam++;
      if (!_onde) _genlikArkada++;
      _sonDb = g.current;
      // -60 dBFS sessizlik, 0 dBFS en yüksek.
      _cubuklar.add(((g.current + 60) / 60).clamp(0.0, 1.0));
      if (_cubuklar.length > 120) _cubuklar.removeAt(0);
      if (_onde) setState(() {});
    });
    _saat = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _yaz('kayıt başladı');
  }

  Future<void> _durdur() async {
    final yol = await _kaydedici.stop();
    await _genlikAbone?.cancel();
    _saat?.cancel();
    await _servis.invokeMethod('durdur');
    if (yol == null) {
      _yaz('stop() yol vermedi');
      return;
    }
    final bayt = await File(yol).length();
    final dk = _sure.elapsedMilliseconds / 60000;
    _dosya = yol;
    _calarSure = await _calar.setFilePath(yol);
    await _calar.setSpeed(_hiz);
    _dosyaBilgi =
        '${(bayt / 1024).toStringAsFixed(0)} KB · '
        '${dk > 0 ? (bayt / 1024 / dk).toStringAsFixed(0) : '-'} KB/dk\n'
        'bizim süre: ${_bicim(_sure.elapsed)} · çalar süresi: '
        '${_calarSure == null ? 'bilinmiyor' : _bicim(_calarSure!)}\n'
        'genlik olayı: $_genlikToplam (beklenen ~${_sure.elapsedMilliseconds ~/ 50}), '
        'arka planda: $_genlikArkada';
    _yaz('kayıt bitti');
  }

  String _bicim(Duration d) {
    final dk = d.inMinutes.toString().padLeft(2, '0');
    final sn = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$dk:$sn';
  }

  @override
  Widget build(BuildContext context) {
    final kayitta = _durum != RecordState.stop;
    return Scaffold(
      appBar: AppBar(title: const Text('K1 — Risk denemesi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_bicim(_sure.elapsed)}  ·  ${_sonDb.toStringAsFixed(1)} dBFS  ·  ${_durum.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _Cubuklar(
                _cubuklar,
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: kayitta ? null : _kaydet,
                child: const Text('Kaydet'),
              ),
              OutlinedButton(
                onPressed: _durum == RecordState.record
                    ? _kaydedici.pause
                    : null,
                child: const Text('Duraklat'),
              ),
              OutlinedButton(
                onPressed: _durum == RecordState.pause
                    ? _kaydedici.resume
                    : null,
                child: const Text('Devam'),
              ),
              FilledButton.tonal(
                onPressed: kayitta ? _durdur : null,
                child: const Text('Durdur'),
              ),
            ],
          ),
          const Divider(height: 32),
          if (_dosya != null) ...[
            Text(_dosyaBilgi),
            StreamBuilder<Duration>(
              stream: _calar.positionStream,
              builder: (context, an) {
                final konum = an.data ?? Duration.zero;
                final toplam = _calarSure ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      value: konum.inMilliseconds
                          .clamp(0, toplam.inMilliseconds)
                          .toDouble(),
                      max: toplam.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      onChanged: (v) =>
                          _calar.seek(Duration(milliseconds: v.round())),
                    ),
                    Text('${_bicim(konum)} / ${_bicim(toplam)}'),
                  ],
                );
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                StreamBuilder<bool>(
                  stream: _calar.playingStream,
                  builder: (context, an) => FilledButton(
                    onPressed: () =>
                        an.data == true ? _calar.pause() : _calar.play(),
                    child: Text(an.data == true ? 'Duraklat' : 'Çal'),
                  ),
                ),
                for (final h in const [1.0, 1.5, 2.0])
                  ChoiceChip(
                    label: Text('${h}x'),
                    selected: _hiz == h,
                    onSelected: (_) {
                      setState(() => _hiz = h);
                      _calar.setSpeed(h);
                    },
                  ),
              ],
            ),
            const Divider(height: 32),
          ],
          Text('Olay kaydı', style: Theme.of(context).textTheme.titleSmall),
          for (final satir in _kayit.take(40))
            Text(
              satir,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _Cubuklar extends CustomPainter {
  _Cubuklar(this.degerler, this.renk);

  final List<double> degerler;
  final Color renk;

  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()..color = renk;
    const genislik = 3.0;
    var x = size.width - genislik;
    for (final d in degerler.reversed) {
      final h = (d * size.height).clamp(2.0, size.height);
      canvas.drawRect(
        Rect.fromLTWH(x, (size.height - h) / 2, genislik - 1, h),
        boya,
      );
      x -= genislik;
      if (x < 0) break;
    }
  }

  @override
  bool shouldRepaint(_Cubuklar eski) => true;
}
