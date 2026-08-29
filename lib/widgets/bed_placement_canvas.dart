import 'package:flutter/material.dart';

import '../logic/bed_geometry.dart';

class BedPlacementCanvas extends StatefulWidget {
  final double masterLengthIn;
  final double masterWidthIn;
  final List<InchRect> rects;
  final List<String> labels;
  final List<Color> colors;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(int index, InchRect rect) onMove;

  const BedPlacementCanvas({
    super.key,
    required this.masterLengthIn,
    required this.masterWidthIn,
    required this.rects,
    required this.labels,
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
    required this.onMove,
  });

  @override
  State<BedPlacementCanvas> createState() => _BedPlacementCanvasState();
}

enum _HitKind { none, body, resize }

class _BedPlacementCanvasState extends State<BedPlacementCanvas> {
  _HitKind _hit = _HitKind.none;
  int? _index;

  static const _handle = 22.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspect = (widget.masterLengthIn <= 0 || widget.masterWidthIn <= 0)
        ? 1.5
        : (widget.masterLengthIn / widget.masterWidthIn).clamp(0.45, 2.8);

    return AspectRatio(
      aspectRatio: aspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapDown: (details) {
                  final hit = _hitTest(details.localPosition, size);
                  if (hit.$1 != null) {
                    widget.onSelect(hit.$1!);
                  }
                },
                onPanStart: (details) {
                  final hit = _hitTest(details.localPosition, size);
                  _index = hit.$1;
                  _hit = hit.$2;
                  if (_index != null) {
                    widget.onSelect(_index!);
                  }
                },
                onPanUpdate: (details) {
                  final index = _index;
                  if (index == null || _hit == _HitKind.none) {
                    return;
                  }
                  final current = widget.rects[index];
                  final dxIn = _dxInches(details.delta.dx, size);
                  final dyIn = _dyInches(details.delta.dy, size);
                  final next = _hit == _HitKind.resize
                      ? current.copyWith(
                          length: (current.length + dxIn).clamp(
                            minSubBedInches,
                            widget.masterLengthIn - current.x,
                          ),
                          width: (current.width + dyIn).clamp(
                            minSubBedInches,
                            widget.masterWidthIn - current.y,
                          ),
                        )
                      : current.copyWith(
                          x: current.x + dxIn,
                          y: current.y + dyIn,
                        );
                  final others = [
                    for (var i = 0; i < widget.rects.length; i++)
                      if (i != index) widget.rects[i],
                  ];
                  if (placementAllowed(
                    candidate: next,
                    masterLengthIn: widget.masterLengthIn,
                    masterWidthIn: widget.masterWidthIn,
                    others: others,
                  )) {
                    widget.onMove(index, next);
                  }
                },
                onPanEnd: (_) {
                  _hit = _HitKind.none;
                  _index = null;
                },
                child: CustomPaint(
                  size: size,
                  painter: _PlacementPainter(
                    masterLengthIn: widget.masterLengthIn,
                    masterWidthIn: widget.masterWidthIn,
                    rects: widget.rects,
                    labels: widget.labels,
                    colors: widget.colors,
                    selectedIndex: widget.selectedIndex,
                    handle: _handle,
                    outline: theme.colorScheme.outline,
                    labelStyle: theme.textTheme.labelSmall ??
                        const TextStyle(fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _dxInches(double dx, Size size) {
    if (widget.masterLengthIn <= 0) {
      return 0;
    }
    return dx * widget.masterLengthIn / size.width;
  }

  double _dyInches(double dy, Size size) {
    if (widget.masterWidthIn <= 0) {
      return 0;
    }
    return dy * widget.masterWidthIn / size.height;
  }

  (int?, _HitKind) _hitTest(Offset local, Size size) {
    for (var i = widget.rects.length - 1; i >= 0; i--) {
      final pixel = _pixelRect(widget.rects[i], size);
      final handle = Rect.fromLTWH(
        pixel.right - _handle,
        pixel.bottom - _handle,
        _handle,
        _handle,
      );
      if (handle.contains(local)) {
        return (i, _HitKind.resize);
      }
      if (pixel.contains(local)) {
        return (i, _HitKind.body);
      }
    }
    return (null, _HitKind.none);
  }

  Rect _pixelRect(InchRect rect, Size size) {
    final scaleX = size.width / widget.masterLengthIn;
    final scaleY = size.height / widget.masterWidthIn;
    return Rect.fromLTWH(
      rect.x * scaleX,
      rect.y * scaleY,
      rect.length * scaleX,
      rect.width * scaleY,
    );
  }
}

class _PlacementPainter extends CustomPainter {
  final double masterLengthIn;
  final double masterWidthIn;
  final List<InchRect> rects;
  final List<String> labels;
  final List<Color> colors;
  final int? selectedIndex;
  final double handle;
  final Color outline;
  final TextStyle labelStyle;

  _PlacementPainter({
    required this.masterLengthIn,
    required this.masterWidthIn,
    required this.rects,
    required this.labels,
    required this.colors,
    required this.selectedIndex,
    required this.handle,
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
    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i];
      final pixel = Rect.fromLTWH(
        rect.x * scaleX,
        rect.y * scaleY,
        rect.length * scaleX,
        rect.width * scaleY,
      );
      final color = colors[i % colors.length];
      final selected = i == selectedIndex;
      canvas.drawRRect(
        RRect.fromRectAndRadius(pixel, const Radius.circular(8)),
        Paint()
          ..color = color.withValues(alpha: selected ? 0.35 : 0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pixel, const Radius.circular(8)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 2,
      );
      final label = i < labels.length ? labels[i] : '';
      if (label.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: labelStyle.copyWith(color: outline),
          ),
          maxLines: 2,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: (pixel.width - 10).clamp(12, double.infinity));
        painter.paint(canvas, Offset(pixel.left + 6, pixel.top + 6));
      }
      final handleRect = Rect.fromLTWH(
        pixel.right - handle,
        pixel.bottom - handle,
        handle,
        handle,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, const Radius.circular(4)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlacementPainter oldDelegate) {
    return oldDelegate.rects != rects ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.masterLengthIn != masterLengthIn;
  }
}
