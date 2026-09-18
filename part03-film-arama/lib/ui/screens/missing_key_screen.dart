import 'package:flutter/material.dart';

/// Anahtarsız çalıştırıldığında açılan ekran.
///
/// Uygulama çökmüyor, "401" de demiyor: ne olduğunu ve ne yapılacağını
/// yazıyor. Depoyu klonlayan birinin ilk karşılaşacağı ekran burası.
class MissingKeyScreen extends StatelessWidget {
  const MissingKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.vpn_key_off_rounded,
                  size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('TMDB anahtarı gerekli',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Bu uygulama film verisini TMDB\'den çeker. Anahtar depoda '
                'saklanmaz; uygulamayı kendi anahtarınla çalıştırman gerekir.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              const _Step(
                number: '1',
                text: 'themoviedb.org → üye ol → Settings → API → '
                    'API Key (v3 auth)',
              ),
              const _Step(
                number: '2',
                text: 'flutter run --dart-define=TMDB_KEY=anahtarin',
              ),
              const SizedBox(height: 20),
              Text(
                'Ayrıntı: README.md',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
