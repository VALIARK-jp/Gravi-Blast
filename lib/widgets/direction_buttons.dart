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

  /// 基準スケール（タブレット以上）。スマホ Web では [_responsiveScale] で縮小する。
  static const _baseScale = 1.3;

  /// 狭い画面ではやや縮小するが、タップしやすい下限を確保する。
  static double _responsiveScale(double screenWidth) {
    if (screenWidth < 400) return 0.64;
    if (screenWidth < 520) return 0.76;
    if (screenWidth < 640) return 0.86;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final r = _responsiveScale(w);
    final s = _baseScale * r;
    final buttonSize = 56.0 * s;
    final logoSize = 50.0 * s;
    final outerPadding = 24.0 * s;
    final rowGap = 8.0 * s;
    final buttonPadding = 4.0 * s;
    final cornerRadius = 12.0 * s;

    return Padding(
      padding: EdgeInsets.fromLTRB(outerPadding * 0.5, 4, outerPadding * 0.5, outerPadding * 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            null,
            _buildButton(SlideDirection.up, 0, buttonSize, buttonPadding, cornerRadius, r, s),
            null,
          ], buttonSize),
          SizedBox(height: rowGap),
          _buildRow([
            _buildButton(SlideDirection.left, 1, buttonSize, buttonPadding, cornerRadius, r, s),
            _buildCenterLogo(logoSize, buttonSize),
            _buildButton(SlideDirection.right, 2, buttonSize, buttonPadding, cornerRadius, r, s),
          ], buttonSize),
          SizedBox(height: rowGap),
          _buildRow([
            null,
            _buildButton(SlideDirection.down, 3, buttonSize, buttonPadding, cornerRadius, r, s),
            null,
          ], buttonSize),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget?> children, double buttonSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map((w) => w ?? SizedBox(width: buttonSize, height: buttonSize))
          .toList(),
    );
  }

  Widget _buildButton(
    SlideDirection direction,
    int colorIndex,
    double buttonSize,
    double buttonPadding,
    double cornerRadius,
    double responsiveScale,
    double combinedScale,
  ) {
    final directionOk = isDirectionEnabled?.call(direction) ?? true;
    final canTap = enabled && directionOk;
    final shape = nextBlockPerDirection[direction];
    final colorIndexForDirection = nextBlockColorPerDirection[direction] ?? colorIndex;
    final color = canTap ? _colorFromIndex(colorIndexForDirection) : Colors.grey;
    return Padding(
      padding: EdgeInsets.all(buttonPadding),
      child: Material(
        color: canTap ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(cornerRadius),
        elevation: responsiveScale < 0.75 ? 2 : 4,
        child: InkWell(
          onTap: canTap ? () => onDirection(direction) : null,
          borderRadius: BorderRadius.circular(cornerRadius),
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: shape != null
                ? Opacity(
                    opacity: canTap ? 1.0 : 0.5,
                    child: Center(
                      child: _ShapePreview(shape: shape, color: color, combinedScale: combinedScale),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterLogo(double logoSize, double buttonSize) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Center(
        child: SvgPicture.asset(
          'lib/assets/valiark.svg',
          width: logoSize,
          height: logoSize,
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
  final double combinedScale;

  const _ShapePreview({
    required this.shape,
    required this.color,
    required this.combinedScale,
  });

  @override
  Widget build(BuildContext context) {
    final maxSize = 44.0 * combinedScale;
    final maxDim = shape.width > shape.height ? shape.width : shape.height;
    final cellSize = (maxDim > 0)
        ? (maxSize / maxDim).clamp(6.0 * combinedScale, 10.0 * combinedScale)
        : 10.0 * combinedScale;
    final contentWidth = shape.width * (cellSize + 2); // cell + margin
    final contentHeight = shape.height * (cellSize + 2);
    return SizedBox(
      width: maxSize,
      height: maxSize,
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
