import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup_service.dart';
import '../../domain/app_settings.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/paper_background.dart';
import 'categories_screen.dart';

/// Ayarlar: tema, yazı boyutu, kategoriler, yedek.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.repositoryOf(context);
    final settings = AppScope.settingsOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: PaperBackground(
        showMargin: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _SettingRow(
              title: 'Tema',
              subtitle: 'Gündüz açık, akşam koyu',
              trailing: _Segmented(
                labels: const ['Açık', 'Koyu'],
                selectedIndex: settings.themeMode == ThemeMode.dark ? 1 : 0,
                onSelected: (index) => repository.setPreference(
                  AppSettings.themeKey,
                  AppSettings.themeToString(
                    index == 1 ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ),
            ),
            _SettingRow(
              title: 'Yazı boyutu',
              subtitle: AppSettings.textSizeLabels[settings.textSizeStep],
              trailing: _Segmented(
                labels: const ['A', 'A', 'A'],
                labelSizes: const [14, 17, 21],
                selectedIndex: settings.textSizeStep,
                onSelected: (index) =>
                    repository.setPreference(AppSettings.textSizeKey, '$index'),
              ),
            ),
            _SettingRow(
              title: 'Kategoriler',
              subtitle: 'Ekle, adını değiştir, sırala',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ),
              ),
            ),
            _SettingRow(
              title: 'Yedek al',
              subtitle: 'Bütün tarifleri tek dosyaya kaydet',
              onTap: () => _exportBackup(context),
            ),
            const SizedBox(height: 20),
            FutureBuilder<int>(
              future: repository.recipeCount(),
              builder: (context, snapshot) {
                final count = snapshot.data;
                if (count == null) return const SizedBox.shrink();
                return Text(
                  'Defterde $count tarif var.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final repository = AppScope.repositoryOf(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final path = await writeBackupFile(await repository.exportBackup());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/json')],
          subject: 'Tarif Defteri yedeği',
          text: 'Tarif Defteri yedeği',
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Yedek alınamadı. Biraz sonra tekrar dene.'),
        ),
      );
    }
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            ?trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right, color: colors.inkSoft, size: 26),
          ],
        ),
      ),
    );
  }
}

/// İki ya da üç seçenekli düğme grubu.
///
/// Material'ın `SegmentedButton`'ı yerine elle yazıldı: onunki seçili öğeye
/// tik işareti koyuyor ve yazı boyutu satırında üç tane "A" nın yanına gelen
/// tikler satırı taşırıyordu.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.labelSizes,
  });

  final List<String> labels;
  final List<double>? labelSizes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(kCornerRadius)),
        border: Border.all(color: colors.rule, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            InkWell(
              onTap: () => onSelected(i),
              child: Container(
                constraints: const BoxConstraints(minWidth: 46, minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: i == selectedIndex ? colors.accent : Colors.transparent,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: labelSizes?[i] ?? 15,
                    fontWeight: FontWeight.w600,
                    color: i == selectedIndex ? colors.onAccent : colors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
