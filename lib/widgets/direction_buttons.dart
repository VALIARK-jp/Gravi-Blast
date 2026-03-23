import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/block.dart';
import '../models/game_state.dart';

class DirectionButtons extends StatelessWidget {
  final void Function(SlideDirection) onDirection;
  final bool enabled;
  final bool Function(SlideDirection)? isDirectionEnabled;
  final Map<SlideDirection, BlockShape> nextBlockPerDirection;
  final Map<SlideDirection, int> nextBlockColorPerDirection;

  const DirectionButtons({
    super.key,
    required this.onDirection,
    required this.nextBlockPerDirection,
    required this.nextBlockColorPerDirection,
    this.enabled = true,
    this.isDirectionEnabled,
  });

  /// 全体を約130%に拡大
  static const _scale = 1.3;
  static const _buttonSize = 56.0 * _scale;
  static const _logoSize = 50.0 * _scale;
  static const _outerPadding = 24.0 * _scale;
  static const _rowGap = 8.0 * _scale;
  static const _buttonPadding = 4.0 * _scale;
  static const _cornerRadius = 12.0 * _scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_outerPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            null,
            _buildButton(SlideDirection.up, 0),
            null,
          ]),
          SizedBox(height: _rowGap),
          _buildRow([
            _buildButton(SlideDirection.left, 1),
            _buildCenterLogo(),
            _buildButton(SlideDirection.right, 2),
          ]),
          SizedBox(height: _rowGap),
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
          .map((w) => w ?? SizedBox(width: _buttonSize, height: _buttonSize))
          .toList(),
    );
  }

  Widget _buildButton(SlideDirection direction, int colorIndex) {
    final directionOk = isDirectionEnabled?.call(direction) ?? true;
    final canTap = enabled && directionOk;
    final shape = nextBlockPerDirection[direction];
    final colorIndexForDirection = nextBlockColorPerDirection[direction] ?? colorIndex;
    final color = canTap ? _colorFromIndex(colorIndexForDirection) : Colors.grey;
    return Padding(
      padding: EdgeInsets.all(_buttonPadding),
      child: Material(
        color: canTap ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(_cornerRadius),
        elevation: 4,
        child: InkWell(
          onTap: canTap ? () => onDirection(direction) : null,
          borderRadius: BorderRadius.circular(_cornerRadius),
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

  Widget _buildCenterLogo() {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: Center(
        child: SvgPicture.asset(
          'lib/assets/valiark.svg',
          width: _logoSize,
          height: _logoSize,
        ),
      ),
    );
  }

  Color _colorFromIndex(int index) {
    final hue = (index % 100) * 3.6;
    return HSLColor.fromAHSL(1.0, hue, 0.75, 0.55).toColor();
  }
}

class _ShapePreview extends StatelessWidget {
  final BlockShape shape;
  final Color color;

  const _ShapePreview({required this.shape, required this.color});

  static const _maxSize = 44.0 * DirectionButtons._scale;

  @override
  Widget build(BuildContext context) {
    final maxDim = shape.width > shape.height ? shape.width : shape.height;
    final cellSize = (maxDim > 0)
        ? (_maxSize / maxDim).clamp(6.0 * DirectionButtons._scale, 10.0 * DirectionButtons._scale)
        : 10.0 * DirectionButtons._scale;
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
