import 'package:flutter/material.dart';

import '../../domain/heatmap_grid.dart';
import '../theme/app_theme.dart';

const _cellSize = 8.0;
const _cellGap = AppSpacing.heatmapCellGap;
const _cellStep = _cellSize + _cellGap;
const _monthLabelHeight = 16.0;

/// Yatay kaydırılabilir ısı haritası. Tam pencere her zaman 1 yıldır
/// (53 hafta); açılışta en sağa (bugüne) kaydırılmış halde gösterilir, bu da
/// görsel olarak taslaktaki "son 6 ay" görünümüyle birebir eşleşir — sola
/// kaydırınca geçmiş yıla doğru genişler (bkz. PLAN.md § B2.4.2).
class HeatmapView extends StatefulWidget {
  const HeatmapView({
    super.key,
    required this.completedDayKeys,
    required this.todayKey,
    required this.onDayTap,
  });

  final Set<int> completedDayKeys;
  final int todayKey;

  /// Bir hücreye dokunulduğunda çağrılır. `wasDone` o günün önceki
  /// durumudur — çağıran taraf tersini yazar (işaretle/kaldır).
  final void Function(int dayKey, bool wasDone) onDayTap;

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<HeatmapView> {
  final _scrollController = ScrollController();
  bool _scrolledToEnd = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEndOnce() {
    if (_scrolledToEnd || !_scrollController.hasClients) return;
    _scrolledToEnd = true;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final grid = buildHeatmapGrid(
      completedDayKeys: widget.completedDayKeys,
      todayKey: widget.todayKey,
      windowWeeks: heatmapWindowOneYear,
    );

    final width = grid.weeks.length * _cellStep - _cellGap;
    const height = _monthLabelHeight + 7 * _cellStep - _cellGap;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEndOnce());

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, grid),
          child: CustomPaint(
            size: Size(width, height),
            painter: _HeatmapPainter(grid),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, HeatmapGrid grid) {
    if (position.dy < _monthLabelHeight) return;
    final week = (position.dx / _cellStep).floor();
    final day = ((position.dy - _monthLabelHeight) / _cellStep).floor();
    if (week < 0 || week >= grid.weeks.length || day < 0 || day >= 7) return;

    final cell = grid.weeks[week].cells[day];
    if (cell == null) return; // gelecek gün — dokunulamaz
    widget.onDayTap(cell.dayKey, cell.level > 0);
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter(this.grid);

  final HeatmapGrid grid;

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint();

    for (var w = 0; w < grid.weeks.length; w++) {
      final cells = grid.weeks[w].cells;
      for (var d = 0; d < 7; d++) {
        final cell = cells[d];
        if (cell == null) continue;
        cellPaint.color = AppColors.heatmapLevels[cell.level];
        canvas.drawOval(
          Rect.fromLTWH(
            w * _cellStep,
            _monthLabelHeight + d * _cellStep,
            _cellSize,
            _cellSize,
          ),
          cellPaint,
        );
      }
    }

    for (final label in grid.monthLabels) {
      final painter = TextPainter(
        text: TextSpan(text: label.label, style: AppTextStyles.monthLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(label.weekIndex * _cellStep, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) => true;
}
