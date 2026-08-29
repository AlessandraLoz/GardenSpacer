import 'package:flutter/material.dart';

class SketchCrop {
  final Color color;
  final int plantCount;
  final int rows;
  final int perRow;
  final double xIn;
  final double yIn;
  final double lengthIn;
  final double widthIn;
  final String label;

  const SketchCrop({
    required this.color,
    required this.plantCount,
    required this.rows,
    required this.perRow,
    required this.xIn,
    required this.yIn,
    required this.lengthIn,
    required this.widthIn,
    this.label = '',
  });
}

List<Color> gardenCropColors(ColorScheme scheme) {
  return [
    scheme.primary,
    scheme.tertiary,
    scheme.secondary,
    scheme.onPrimaryContainer,
    scheme.error,
    scheme.outline,
  ];
}

class BedSketch extends StatelessWidget {
  final double lengthIn;
  final double widthIn;
  final List<SketchCrop> crops;

  const BedSketch({
    super.key,
    required this.lengthIn,
    required this.widthIn,
    required this.crops,
  });

  static const _maxDots = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspect = (lengthIn <= 0 || widthIn <= 0)
        ? 1.5
        : (lengthIn / widthIn).clamp(0.45, 2.8);
    final total = crops.fold<int>(0, (sum, crop) => sum + crop.plantCount);
    final previewing = total > _maxDots;

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
                  masterLengthIn: lengthIn,
                  masterWidthIn: widthIn,
                  crops: crops,
                  maxDots: _maxDots,
                  outline: theme.colorScheme.outline,
                  labelStyle: theme.textTheme.labelSmall ??
                      const TextStyle(fontSize: 11),
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
  final double masterLengthIn;
  final double masterWidthIn;
  final List<SketchCrop> crops;
  final int maxDots;
  final Color outline;
  final TextStyle labelStyle;

  _BedSketchPainter({
    required this.masterLengthIn,
    required this.masterWidthIn,
    required this.crops,
    required this.maxDots,
    required this.outline,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (masterLengthIn <= 0 || masterWidthIn <= 0) {
      return;
    }
    final scaleX = size.width / masterLengthIn;
    final scaleY = size.height / masterWidthIn;
    for (final crop in crops) {
      final rect = Rect.fromLTWH(
        crop.xIn * scaleX,
        crop.yIn * scaleY,
        crop.lengthIn * scaleX,
        crop.widthIn * scaleY,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(6)),
        Paint()
          ..color = crop.color.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(6)),
        Paint()
          ..color = crop.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _paintCrop(canvas, rect.deflate(4), crop);
      if (crop.label.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: crop.label,
            style: labelStyle.copyWith(color: outline),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: (rect.width - 8).clamp(12, double.infinity));
        painter.paint(canvas, Offset(rect.left + 6, rect.top + 4));
      }
    }
  }

  void _paintCrop(Canvas canvas, Rect rect, SketchCrop crop) {
    if (crop.plantCount <= 0 || crop.rows <= 0 || crop.perRow <= 0) {
      return;
    }
    var drawRows = crop.rows;
    var drawCols = crop.perRow;
    var drawCount = crop.plantCount;
    if (crop.plantCount > maxDots) {
      final scale = maxDots / crop.plantCount;
      drawRows = (crop.rows * scale).round().clamp(1, crop.rows);
      drawCols = (crop.perRow * scale).round().clamp(1, crop.perRow);
      drawCount = drawRows * drawCols;
    }
    final paint = Paint()..color = crop.color;
    final cellW = rect.width / drawCols;
    final cellH = rect.height / drawRows;
    final radius = (cellW < cellH ? cellW : cellH) * 0.28;
    var drawn = 0;
    for (var r = 0; r < drawRows; r++) {
      for (var c = 0; c < drawCols; c++) {
        if (drawn >= drawCount) {
          return;
        }
        canvas.drawCircle(
          Offset(rect.left + (c + 0.5) * cellW, rect.top + (r + 0.5) * cellH),
          radius.clamp(2.5, 12.0),
          paint,
        );
        drawn++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BedSketchPainter oldDelegate) {
    return oldDelegate.crops != crops ||
        oldDelegate.masterLengthIn != masterLengthIn ||
        oldDelegate.masterWidthIn != masterWidthIn;
  }
}
