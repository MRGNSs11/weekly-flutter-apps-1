import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/database.dart';
import '../theme/app_theme.dart';

/// Adım adım pişirme.
///
/// Ekranda tek bir adım var. Ocağın başında liste içinde "kaçıncı satırdaydım"
/// diye aramak, uygulamayı hiç açmamaktan daha kötü.
///
/// Adım metni el yazısı fontla DEĞİL, gövde fontuyla yazılır: el yazısı
/// başlıkta hoş duruyor, üç satırlık talimatta okunmuyor.
class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final steps = widget.recipe.steps;
    final isLast = _index == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Pişirmeyi bitir',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.recipe.name),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (_index + 1) / steps.length,
                minHeight: 8,
                backgroundColor: colors.rule,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ADIM ${_index + 1} / ${steps.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    steps[_index],
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 26,
                      height: 1.42,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _index == 0
                        ? null
                        : () => setState(() => _index--),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink,
                      side: BorderSide(color: colors.rule, width: 2),
                      minimumSize: const Size.fromHeight(56),
                      textStyle: _buttonTextStyle,
                      shape: _buttonShape,
                    ),
                    child: const Text('Önceki'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (isLast) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _index++);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      minimumSize: const Size.fromHeight(56),
                      textStyle: _buttonTextStyle,
                      shape: _buttonShape,
                    ),
                    child: Text(isLast ? 'Bitti' : 'Sonraki'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _buttonTextStyle = TextStyle(
    fontFamily: kBodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(kCornerRadius)),
  );
}
