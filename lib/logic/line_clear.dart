import '../models/block.dart';
import '../models/board.dart';

/// Result of line clearing: updated blocks and cells being cleared.
class LineClearResult {
  final List<Block> blocks;
  final int linesCleared;
  /// 消去されたセル（揃った行・列のセルのみ）
  final Set<(int, int)> clearedCells;
  final Set<int> triggerRows;
  final Set<int> triggerCols;

  const LineClearResult({
    required this.blocks,
    required this.linesCleared,
    this.clearedCells = const {},
    this.triggerRows = const {},
    this.triggerCols = const {},
  });
}

/// Clears fully filled rows and columns.
/// セル単位で消去: 揃った行・列のセルのみ消し、残りパーツは連結ごとにブロック化して残す。
class LineClear {
  final int boardWidth;
  final int boardHeight;

  LineClear({required this.boardWidth, required this.boardHeight});

  /// Returns updated blocks and lines cleared.
  LineClearResult clear(List<Block> blocks) {
    if (blocks.isEmpty) {
      return const LineClearResult(blocks: [], linesCleared: 0);
    }

    final board = Board.fromBlocks(
      width: boardWidth,
      height: boardHeight,
      blocks: blocks
          .map((b) => (
                blockId: b.blockId,
                cells: b.occupiedCells,
              ))
          .toList(),
    );

    final rowsToClear = board.getFullRows();
    final colsToClear = board.getFullCols();

    if (rowsToClear.isEmpty && colsToClear.isEmpty) {
      return LineClearResult(blocks: blocks, linesCleared: 0);
    }

    // 揃った行・列のセルだけが消去対象
    final clearedSet = <(int, int)>{};
    for (final r in rowsToClear) {
      for (var c = 0; c < boardWidth; c++) {
        clearedSet.add((c, r));
      }
    }
    for (final c in colsToClear) {
      for (var r = 0; r < boardHeight; r++) {
        clearedSet.add((c, r));
      }
    }

    // 全ブロックのセルから消去分を除いた残り + (blockId, colorIndex)
    final remainingWithMeta = <(int, int), ({String blockId, int colorIndex})>{};
    for (final b in blocks) {
      for (final cell in b.occupiedCells) {
        if (!clearedSet.contains(cell)) {
          remainingWithMeta[cell] = (blockId: b.blockId, colorIndex: b.colorIndex);
        }
      }
    }

    // 今回の消去で仲間が消えたブロック（セルの一部が clearedSet に入ったブロック）のみ対象
    final clearedBlockIds = <String>{};
    for (final b in blocks) {
      if (b.occupiedCells.any((c) => clearedSet.contains(c))) {
        clearedBlockIds.add(b.blockId);
      }
    }

    // 連結成分を求める（隣接する残りパーツは一体のブロックに）
    final components = _findConnectedComponents(
      remainingWithMeta.keys.toSet(),
      boardWidth,
      boardHeight,
    );

    // 各連結成分を Block に変換。
    // 仲間が消えたブロックの残りパーツのみ：2つ目以降の色を変える。影響なしブロックはそのまま。
    var fragmentId = 0;
    final newBlocks = <Block>[];
    final fragmentCountPerBlock = <String, int>{};
    const colorCount = 100;
    const colorOffsets = [50, 25, 75, 17, 83, 33, 67, 42, 58, 8];
    for (final component in components) {
      if (component.isEmpty) continue;
      final firstCell = component.first;
      final meta = remainingWithMeta[firstCell]!;
      final wasCleared = clearedBlockIds.contains(meta.blockId);
      final count = fragmentCountPerBlock[meta.blockId] ?? 0;
      fragmentCountPerBlock[meta.blockId] = count + 1;
      final colorIndex = (!wasCleared || count == 0)
          ? meta.colorIndex
          : (meta.colorIndex + colorOffsets[count % colorOffsets.length]) % colorCount;
      newBlocks.add(Block.fromCells(
        blockId: 'frag_${meta.blockId}_$fragmentId',
        cells: component.toList(),
        colorIndex: colorIndex,
      ));
      fragmentId++;
    }

    return LineClearResult(
      blocks: newBlocks,
      linesCleared: rowsToClear.length + colsToClear.length,
      clearedCells: clearedSet,
      triggerRows: rowsToClear.toSet(),
      triggerCols: colsToClear.toSet(),
    );
  }

  /// 隣接セル（上下左右）で連結している成分に分ける
  List<Set<(int, int)>> _findConnectedComponents(
    Set<(int, int)> cells,
    int width,
    int height,
  ) {
    final result = <Set<(int, int)>>[];
    final visited = <(int, int)>{};
    for (final start in cells) {
      if (visited.contains(start)) continue;
      final component = <(int, int)>{};
      final queue = [start];
      while (queue.isNotEmpty) {
        final (c, r) = queue.removeLast();
        if (visited.contains((c, r))) continue;
        if (!cells.contains((c, r))) continue;
        visited.add((c, r));
        component.add((c, r));
        for (final (dc, dr) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nc = c + dc;
          final nr = r + dr;
          if (nc >= 0 && nc < width && nr >= 0 && nr < height) {
            queue.add((nc, nr));
          }
        }
      }
      if (component.isNotEmpty) result.add(component);
    }
    return result;
  }
}
