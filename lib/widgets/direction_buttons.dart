import 'package:flutter/material.dart';

import '../models/block.dart';
import '../models/game_state.dart';

class DirectionButtons extends StatelessWidget {
  final void Function(SlideDirection) onDirection;
  final bool enabled;
  final bool Function(SlideDirection)? isDirectionEnabled;
  final Map<SlideDirection, BlockShape> nextBlockPerDirection;

  const DirectionButtons({
    super.key,
    required this.onDirection,
    required this.nextBlockPerDirection,
    this.enabled = true,
    this.isDirectionEnabled,
  });

  static const _buttonSize = 56.0;
  static const _colors = [
    Color(0xFF6B4EFF),
    Color(0xFF4ECDC4),
    Color(0xFFE056FD),
    Color(0xFF45B7D1),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            null,
            _buildButton(SlideDirection.up, 0),
            null,
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildButton(SlideDirection.left, 1),
            null,
            _buildButton(SlideDirection.right, 2),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            null,
            _buildButton(SlideDirection.down, 3),
            null,
          ]),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget?> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map((w) => w ?? const SizedBox(width: _buttonSize, height: _buttonSize))
          .toList(),
    );
  }

  Widget _buildButton(SlideDirection direction, int colorIndex) {
    final directionOk = isDirectionEnabled?.call(direction) ?? true;
    final canTap = enabled && directionOk;
    final shape = nextBlockPerDirection[direction];
    final color = canTap ? _colors[colorIndex % _colors.length] : Colors.grey;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: canTap ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          onTap: canTap ? () => onDirection(direction) : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: _buttonSize,
            height: _buttonSize,
            child: shape != null
                ? Opacity(
                    opacity: canTap ? 1.0 : 0.5,
                    child: Center(
                      child: _ShapePreview(shape: shape, color: color),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  final BlockShape shape;
  final Color color;

  const _ShapePreview({required this.shape, required this.color});

  static const _maxSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final maxDim = shape.width > shape.height ? shape.width : shape.height;
    final cellSize = (maxDim > 0) ? (_maxSize / maxDim).clamp(6.0, 10.0) : 10.0;
    final contentWidth = shape.width * (cellSize + 2); // cell + margin
    final contentHeight = shape.height * (cellSize + 2);
    return SizedBox(
      width: _maxSize,
      height: _maxSize,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var r = 0; r < shape.height; r++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var c = 0; c < shape.width; c++)
                      Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: shape.cells[r][c] == 1 ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
