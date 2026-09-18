import 'package:flutter/material.dart';

import '../../camera/camera_permission.dart';
import '../theme/app_theme.dart';

/// İzin verilmediğinde açılan ekran.
///
/// Taslakta çizilmemişti; aynı dille kuruldu (PLAN.md B2.4 / 4).
/// İki hâli var ve ikisi farklı şey söylüyor:
///   denied  → sistem diyaloğu hâlâ açılabilir, "İzin ver" sor.
///   blocked → diyalog bir daha açılmaz, tek çıkış ayarlar.
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({
    super.key,
    required this.access,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final CameraAccess access;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  bool get _blocked => access == CameraAccess.blocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AccentIsaret(),
              const SizedBox(height: 28),
              Text(
                _blocked
                    ? 'Kamera izni kapalı'
                    : 'Uygulamanın kameraya erişmesi gerekiyor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _blocked
                    ? 'İzin "bir daha sorma" olarak işaretlenmiş, bu yüzden '
                        'sistem penceresi artık açılmıyor. Ayarlardan '
                        'Kamera iznini açman gerekiyor.'
                    : 'Yazıyı okuyabilmek için kamerayı açıyoruz. Görüntü '
                        'telefondan çıkmıyor, hiçbir yere gönderilmiyor.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 28),
              if (_blocked)
                FilledButton(
                  onPressed: onOpenSettings,
                  child: const Text('Ayarları aç'),
                )
              else
                FilledButton(
                  onPressed: onRequest,
                  child: const Text('İzin ver'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayfanın tek renkli öğesi: fosforlu vurgu şeridi.
class _AccentIsaret extends StatelessWidget {
  const _AccentIsaret();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 14,
      color: AppColors.accent,
    );
  }
}
