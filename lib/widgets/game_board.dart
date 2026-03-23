import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/block.dart';
import '../models/board.dart';

class GameBoard extends StatelessWidget {
  final Board board;
  final List<Block> blocks;
  final double cellSize;
  final Set<(int, int)> clearingCells;
  final Set<int> clearingTriggerRows;
  final Set<int> clearingTriggerCols;
  final Map<String, ({int fromCol, int fromRow, int toCol, int toRow})> slideAnimations;

  const GameBoard({
    super.key,
    required this.board,
    required this.blocks,
    this.cellSize = 36,
    this.clearingCells = const {},
    this.clearingTriggerRows = const {},
    this.clearingTriggerCols = const {},
    this.slideAnimations = const {},
  });

  static const _clearDuration = Duration(milliseconds: 500);
  static const _slideDuration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    final hasSlideAnim = slideAnimations.isNotEmpty;
    const outerRadius = 20.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(outerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            // メタリックブラック：左上ハイライト → 深黒（わずかに青み）
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A4D54),
                Color(0xFF1E1F24),
                Color(0xFF0A0A0C),
                Color(0xFF12141A),
              ],
              stops: [0.0, 0.35, 0.72, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF6E7178).withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -1,
              ),
              BoxShadow(
                color: const Color(0xFF8A9099).withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: board.width * cellSize,
              height: board.height * cellSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildGrid(context),
                  if (hasSlideAnim) _buildAnimatedBlocks(context) else _buildStaticCells(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < board.height; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < board.width; c++) _buildEmptyCell(context, c, r),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyCell(BuildContext context, int col, int row) {
    final isClearing = clearingCells.contains((col, row));
    final isTrigger = clearingTriggerRows.contains(row) || clearingTriggerCols.contains(col);
    final hasSlideAnim = slideAnimations.isNotEmpty;
    final blockId = board.cell(col, row);
    final hasBlock = !hasSlideAnim && blockId != null;

    final block = blockId != null ? blocks.where((b) => b.blockId == blockId).firstOrNull : null;
    final color = hasBlock ? _colorForBlock(blockId, block) : null;
    final cell = SizedBox(
      width: cellSize,
      height: cellSize,
      child: Container(
        margin: EdgeInsets.all(cellSize * 0.04),
        decoration: hasBlock && color != null
            ? _glassBlockDecoration(color, cellSize)
            : _emptyGlassCellDecoration(cellSize),
      ),
    );

    if (isClearing && hasBlock) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: _clearDuration,
        builder: (context, t, child) {
          final opacity = t;
          final scale = t;
          // トリガー（揃った行・列）: 白フラッシュで強調してから消える
          final flashOpacity = isTrigger ? (t > 0.5 ? (1 - t) * 2 : t * 2) : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              ),
              if (isTrigger && flashOpacity > 0)
                IgnorePointer(
                  child: Container(
                    margin: EdgeInsets.all(cellSize * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: flashOpacity * 0.75),
                      borderRadius: BorderRadius.circular(cellSize * 0.18),
                    ),
                  ),
                ),
            ],
          );
        },
        child: cell,
      );
    }
    return cell;
  }

  Widget _buildStaticCells(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildAnimatedBlocks(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final block in blocks)
          KeyedSubtree(
            key: ValueKey(block.blockId),
            child: _buildAnimatedBlock(context, block),
          ),
      ],
    );
  }

  Widget _buildAnimatedBlock(BuildContext context, Block block) {
    final anim = slideAnimations[block.blockId];
    final fromCol = anim?.fromCol ?? block.col;
    final fromRow = anim?.fromRow ?? block.row;
    final toCol = block.col;
    final toRow = block.row;

    if (anim == null) {
      return _buildBlockAt(context, block, block.col.toDouble(), block.row.toDouble());
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _slideDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final col = fromCol + (toCol - fromCol) * t;
        final row = fromRow + (toRow - fromRow) * t;
        return _buildBlockAt(context, block, col, row);
      },
    );
  }

  Widget _buildBlockAt(BuildContext context, Block block, double col, double row) {
    return Positioned(
      left: col * cellSize,
      top: row * cellSize,
      child: SizedBox(
        width: block.shape.width * cellSize,
        height: block.shape.height * cellSize,
        child: _buildBlockShape(block),
      ),
    );
  }

  Widget _buildBlockShape(Block block) {
    final color = _colorForBlock(block.blockId, block);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < block.shape.height; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < block.shape.width; c++)
                if (block.shape.cells[r][c] == 1)
                  Container(
                    width: cellSize - cellSize * 0.08,
                    height: cellSize - cellSize * 0.08,
                    margin: EdgeInsets.all(cellSize * 0.04),
                    decoration: _glassBlockDecoration(color, cellSize),
                  )
                else
                  SizedBox(width: cellSize, height: cellSize),
            ],
          ),
      ],
    );
  }

  /// 空マス：暗いメタル上のすりガラス風タイル
  BoxDecoration _emptyGlassCellDecoration(double cellSize) {
    final r = cellSize * 0.18;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF3A3C42).withValues(alpha: 0.65),
          const Color(0xFF1A1B1F).withValues(alpha: 0.88),
        ],
      ),
      border: Border.all(
        color: const Color(0xFF8E9299).withValues(alpha: 0.35),
        width: 0.85,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 3,
          offset: const Offset(1, 1),
        ),
        BoxShadow(
          color: const Color(0xFF6B7078).withValues(alpha: 0.15),
          blurRadius: 2,
          offset: const Offset(-1, -1),
        ),
      ],
    );
  }

  /// ブロック：リキッドグラス風（半透明グラデ＋縁光＋発色シャドウ）
  BoxDecoration _glassBlockDecoration(Color base, double cellSize) {
    final r = cellSize * 0.2;
    final light = Color.lerp(base, Colors.white, 0.42)!;
    final deep = Color.lerp(base, Colors.black, 0.18)!;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          light.withValues(alpha: 0.92),
          base.withValues(alpha: 0.72),
          deep.withValues(alpha: 0.58),
        ],
        stops: const [0.0, 0.48, 1.0],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.52),
        width: 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: base.withValues(alpha: 0.42),
          blurRadius: cellSize * 0.28,
          offset: Offset(0, cellSize * 0.07),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.35),
          blurRadius: 3,
          offset: const Offset(-1.5, -1.5),
        ),
      ],
    );
  }

  /// 100色パレット（HSLで均等に分布、ブロックごとにランダム割当）
  static final List<Color> _palette = () {
    final list = <Color>[];
    for (var i = 0; i < 100; i++) {
      final hue = (i * 3.6) % 360.0;
      final color = HSLColor.fromAHSL(1.0, hue, 0.75, 0.55);
      list.add(color.toColor());
    }
    return list;
  }();

  Color _colorForBlock(String blockId, Block? block) {
    final index = block?.colorIndex ?? blockId.hashCode.abs() % 100;
    return _palette[index % _palette.length];
  }
}
