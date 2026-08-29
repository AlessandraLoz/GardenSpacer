import 'package:flutter/material.dart';

class BedSketch extends StatelessWidget {
  final double lengthIn;
  final double widthIn;
  final int plantCount;
  final int? rows;
  final int? perRow;

  const BedSketch({
    super.key,
    required this.lengthIn,
    required this.widthIn,
    required this.plantCount,
    this.rows,
    this.perRow,
  });

  static const _maxDots = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspect = (lengthIn <= 0 || widthIn <= 0)
        ? 1.5
        : (lengthIn / widthIn).clamp(0.45, 2.8);
    final previewing = plantCount > _maxDots;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _BedSketchPainter(
                  color: theme.colorScheme.primary,
                  plantCount: plantCount,
                  rows: rows ?? 1,
                  perRow: perRow ?? plantCount.clamp(1, _maxDots),
                  maxDots: _maxDots,
                ),
              ),
            ),
          ),
        ),
        if (previewing) ...[
          const SizedBox(height: 8),
          Text(
            'Preview of spacing — not every plant is drawn',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _BedSketchPainter extends CustomPainter {
  final Color color;
  final int plantCount;
  final int rows;
  final int perRow;
  final int maxDots;

  _BedSketchPainter({
    required this.color,
    required this.plantCount,
    required this.rows,
    required this.perRow,
    required this.maxDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plantCount <= 0 || rows <= 0 || perRow <= 0) {
      return;
    }

    var drawRows = rows;
    var drawCols = perRow;
    var drawCount = plantCount;
    if (plantCount > maxDots) {
      final scale = maxDots / plantCount;
      drawRows = (rows * scale).round().clamp(1, rows);
      drawCols = (perRow * scale).round().clamp(1, perRow);
      drawCount = drawRows * drawCols;
    }

    final paint = Paint()..color = color;
    final cellW = size.width / drawCols;
    final cellH = size.height / drawRows;
    final radius = (cellW < cellH ? cellW : cellH) * 0.28;

    var drawn = 0;
    for (var r = 0; r < drawRows; r++) {
      for (var c = 0; c < drawCols; c++) {
        if (drawn >= drawCount) {
          return;
        }
        canvas.drawCircle(
          Offset((c + 0.5) * cellW, (r + 0.5) * cellH),
          radius.clamp(3.0, 14.0),
          paint,
        );
        drawn++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BedSketchPainter oldDelegate) {
    return oldDelegate.plantCount != plantCount ||
        oldDelegate.rows != rows ||
        oldDelegate.perRow != perRow ||
        oldDelegate.color != color;
  }
}
