import 'dart:math';

import '../models/block.dart';
import '../models/game_state.dart';

/// Spawns a new block. Can spawn at edge (off-screen) to fall in gravity direction,
/// or at random position (for game start).
class Spawner {
  final int boardWidth;
  final int boardHeight;
  final Random _random;

  Spawner({
    required this.boardWidth,
    required this.boardHeight,
    Random? random,
  }) : _random = random ?? Random();

  /// Spawn at random valid position (for game start).
  Block? spawn(List<Block> existingBlocks) {
    final shape = BlockShape.random(_random);
    final occupied = _buildOccupied(existingBlocks);
    final positions = _validPositions(shape, occupied);

    if (positions.isEmpty) return null;

    final (col, row) = positions[_random.nextInt(positions.length)];
    return Block(
      blockId: 'block_${DateTime.now().millisecondsSinceEpoch}',
      shape: shape,
      col: col,
      row: row,
    );
  }

  /// Spawn at edge off-screen so block will slide in [direction] until it hits obstacle.
  /// Row/col is random along the edge (not fixed at center).
  Block spawnAtEdge(SlideDirection direction, List<Block> existingBlocks) {
    final shape = BlockShape.random(_random);
    int col;
    int row;

    switch (direction) {
      case SlideDirection.right:
        col = 1 - shape.width;
        row = _random.nextInt((boardHeight - shape.height + 1).clamp(1, boardHeight));
        break;
      case SlideDirection.left:
        col = boardWidth - 1;
        row = _random.nextInt((boardHeight - shape.height + 1).clamp(1, boardHeight));
        break;
      case SlideDirection.down:
        col = _random.nextInt((boardWidth - shape.width + 1).clamp(1, boardWidth));
        row = 1 - shape.height;
        break;
      case SlideDirection.up:
        col = _random.nextInt((boardWidth - shape.width + 1).clamp(1, boardWidth));
        row = boardHeight - 1;
        break;
    }

    return Block(
      blockId: 'block_${DateTime.now().millisecondsSinceEpoch}',
      shape: shape,
      col: col,
      row: row,
    );
  }

  Set<(int, int)> _buildOccupied(List<Block> blocks) {
    final set = <(int, int)>{};
    for (final b in blocks) {
      for (final cell in b.occupiedCells) {
        set.add(cell);
      }
    }
    return set;
  }

  List<(int, int)> _validPositions(
    BlockShape shape,
    Set<(int, int)> occupied,
  ) {
    final result = <(int, int)>[];
    for (var row = 0; row <= boardHeight - shape.height; row++) {
      for (var col = 0; col <= boardWidth - shape.width; col++) {
        if (_fits(shape, col, row, occupied)) {
          result.add((col, row));
        }
      }
    }
    return result;
  }

  bool _fits(
    BlockShape shape,
    int col,
    int row,
    Set<(int, int)> occupied,
  ) {
    for (final (dc, dr) in shape.occupiedOffsets) {
      final c = col + dc;
      final r = row + dr;
      if (c < 0 || c >= boardWidth || r < 0 || r >= boardHeight) {
        return false;
      }
      if (occupied.contains((c, r))) return false;
    }
    return true;
  }

  /// Check if any block shape can be placed anywhere (static placement, for game start).
  bool canSpawnAny(List<Block> existingBlocks) {
    final occupied = _buildOccupied(existingBlocks);
    for (final shape in BlockShape.all) {
      if (_validPositions(shape, occupied).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Tries to find a valid spawn for [direction]: shape + position where the block
  /// can fully enter the board. Returns (newBlock, settledBlock) or null if none.
  ({Block newBlock, Block settled})? trySpawnAtEdge(
    SlideDirection direction,
    Block Function(Block) slideNewBlock,
    bool Function(Block) isFullyOnBoard,
  ) {
    final shapes = List<BlockShape>.from(BlockShape.all)..shuffle(_random);
    for (final shape in shapes) {
      final candidates = blocksAtEdgeForShape(shape, direction);
      candidates.shuffle(_random);
      for (final blockAtEdge in candidates) {
        final newBlock = Block(
          blockId: 'block_${DateTime.now().millisecondsSinceEpoch}',
          shape: shape,
          col: blockAtEdge.col,
          row: blockAtEdge.row,
        );
        final settled = slideNewBlock(newBlock);
        if (isFullyOnBoard(settled)) {
          return (newBlock: newBlock, settled: settled);
        }
      }
    }
    return null;
  }

  /// All valid edge spawn positions for a shape and direction.
  /// Used for game over check (try all positions along the edge).
  List<Block> blocksAtEdgeForShape(BlockShape shape, SlideDirection direction) {
    final result = <Block>[];
    switch (direction) {
      case SlideDirection.right:
        for (var row = 0; row <= boardHeight - shape.height; row++) {
          result.add(Block(
            blockId: '_check',
            shape: shape,
            col: 1 - shape.width,
            row: row,
          ));
        }
        break;
      case SlideDirection.left:
        for (var row = 0; row <= boardHeight - shape.height; row++) {
          result.add(Block(
            blockId: '_check',
            shape: shape,
            col: boardWidth - 1,
            row: row,
          ));
        }
        break;
      case SlideDirection.down:
        for (var col = 0; col <= boardWidth - shape.width; col++) {
          result.add(Block(
            blockId: '_check',
            shape: shape,
            col: col,
            row: 1 - shape.height,
          ));
        }
        break;
      case SlideDirection.up:
        for (var col = 0; col <= boardWidth - shape.width; col++) {
          result.add(Block(
            blockId: '_check',
            shape: shape,
            col: col,
            row: boardHeight - 1,
          ));
        }
        break;
    }
    return result;
  }
}
