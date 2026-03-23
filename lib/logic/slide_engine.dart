import '../models/block.dart';
import '../models/game_state.dart';

/// Handles sliding all blocks in a direction until they hit a wall or another block.
class SlideEngine {
  final int boardWidth;
  final int boardHeight;

  SlideEngine({required this.boardWidth, required this.boardHeight});

  /// Slides only [newBlock] until it hits wall or [obstacleBlocks].
  /// Use this for spawn - guarantees new block collides with obstacles.
  Block slideNewBlock(
    Block newBlock,
    List<Block> obstacleBlocks,
    SlideDirection direction,
  ) {
    final occupied = <(int, int)>{};
    for (final b in obstacleBlocks) {
      for (final cell in b.occupiedCells) {
        if (cell.$1 >= 0 && cell.$1 < boardWidth && cell.$2 >= 0 && cell.$2 < boardHeight) {
          occupied.add(cell);
        }
      }
    }
    return _slideOneBlock(newBlock, direction, occupied);
  }

  /// Returns updated list of blocks after sliding in [direction].
  /// Blocks are processed in order of their "leading edge" so that
  /// blocks in front get their final positions first.
  List<Block> slide(List<Block> blocks, SlideDirection direction) {
    if (blocks.isEmpty) return [];

    final sorted = _sortByLeadingEdge(blocks, direction);
    final occupied = <(int, int)>{};
    final result = <Block>[];

    for (final block in sorted) {
      final finalBlock = _slideOneBlock(block, direction, occupied);
      result.add(finalBlock);
      for (final cell in finalBlock.occupiedCells) {
        if (cell.$1 >= 0 && cell.$1 < boardWidth &&
            cell.$2 >= 0 && cell.$2 < boardHeight) {
          occupied.add(cell);
        }
      }
    }

    return result;
  }

  /// Sorts blocks by leading edge. When two blocks share the same leading edge
  /// (e.g. overlapping or adjacent), processes the one "in front" first so it
  /// moves out of the way before the one behind.
  List<Block> _sortByLeadingEdge(List<Block> blocks, SlideDirection direction) {
    final list = List<Block>.from(blocks);
    switch (direction) {
      case SlideDirection.right:
        list.sort((a, b) {
          final cmp = b.maxCol.compareTo(a.maxCol);
          if (cmp != 0) return cmp;
          return b.minCol.compareTo(a.minCol);
        });
        break;
      case SlideDirection.left:
        list.sort((a, b) {
          final cmp = a.minCol.compareTo(b.minCol);
          if (cmp != 0) return cmp;
          return a.maxCol.compareTo(b.maxCol);
        });
        break;
      case SlideDirection.down:
        list.sort((a, b) {
          final cmp = b.maxRow.compareTo(a.maxRow);
          if (cmp != 0) return cmp;
          return b.minRow.compareTo(a.minRow);
        });
        break;
      case SlideDirection.up:
        list.sort((a, b) {
          final cmp = a.minRow.compareTo(b.minRow);
          if (cmp != 0) return cmp;
          return a.maxRow.compareTo(b.maxRow);
        });
        break;
    }
    return list;
  }

  Block _slideOneBlock(
    Block block,
    SlideDirection direction,
    Set<(int, int)> occupied,
  ) {
    var current = block;
    while (true) {
      final next = _moveOne(current, direction);
      if (_wouldCollide(next, occupied)) break;
      current = next;
    }
    return current;
  }

  Block _moveOne(Block block, SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return block.copyWith(col: block.col + 1);
      case SlideDirection.left:
        return block.copyWith(col: block.col - 1);
      case SlideDirection.down:
        return block.copyWith(row: block.row + 1);
      case SlideDirection.up:
        return block.copyWith(row: block.row - 1);
    }
  }

  bool _wouldCollide(Block block, Set<(int, int)> occupied) {
    for (final (c, r) in block.occupiedCells) {
      if (c < 0 || c >= boardWidth || r < 0 || r >= boardHeight) {
        return true;
      }
      if (occupied.contains((c, r))) return true;
    }
    return false;
  }
}
