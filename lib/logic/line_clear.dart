import 'dart:math';

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
  final Random _random;

  LineClear({
    required this.boardWidth,
    required this.boardHeight,
    Random? random,
  }) : _random = random ?? Random();

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

    // 連結成分を求める。同一 blockId かつ隣接するセルのみを連結（違うブロック由来は絶対にマージしない）
    final components = _findConnectedComponents(
      remainingWithMeta,
      boardWidth,
      boardHeight,
    );

    // 仲間が消えたブロックごとの断片数をカウント（2つ以上残った場合のみ色を変える）
    final fragmentCountPerBlock = <String, int>{};
    for (final component in components) {
      if (component.isEmpty) continue;
      final meta = remainingWithMeta[component.first]!;
      if (clearedBlockIds.contains(meta.blockId)) {
        fragmentCountPerBlock[meta.blockId] = (fragmentCountPerBlock[meta.blockId] ?? 0) + 1;
      }
    }

    // 各連結成分を Block に変換。
    // 仲間が消えて残りが2つ以上ある場合のみ：別扱いのためそれぞれ独立した色を割り当て。
    var fragmentId = 0;
    final newBlocks = <Block>[];
    const colorCount = 100;
    final usedColors = <int>{};
    for (final component in components) {
      if (component.isEmpty) continue;
      final firstCell = component.first;
      final meta = remainingWithMeta[firstCell]!;
      final needNewColor = clearedBlockIds.contains(meta.blockId) &&
          (fragmentCountPerBlock[meta.blockId] ?? 0) >= 2;
      final colorIndex = needNewColor
          ? _pickDistinctColor(usedColors, colorCount)
          : meta.colorIndex;
      if (needNewColor) usedColors.add(colorIndex);
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

  /// 既に使った色を避けて新しい色を選ぶ
  int _pickDistinctColor(Set<int> used, int colorCount) {
    if (used.length >= colorCount) return _random.nextInt(colorCount);
    var c = _random.nextInt(colorCount);
    while (used.contains(c)) {
      c = (c + 1) % colorCount;
    }
    return c;
  }

  /// 同一 blockId かつ隣接するセルで連結成分に分ける。違うブロック由来は絶対にマージしない。
  List<Set<(int, int)>> _findConnectedComponents(
    Map<(int, int), ({String blockId, int colorIndex})> cellsWithMeta,
    int width,
    int height,
  ) {
    final cells = cellsWithMeta.keys.toSet();
    final result = <Set<(int, int)>>[];
    final visited = <(int, int)>{};
    for (final start in cells) {
      if (visited.contains(start)) continue;
      final meta = cellsWithMeta[start]!;
      final component = <(int, int)>{};
      final queue = [start];
      while (queue.isNotEmpty) {
        final (c, r) = queue.removeLast();
        if (visited.contains((c, r))) continue;
        if (!cells.contains((c, r))) continue;
        if (cellsWithMeta[(c, r)]!.blockId != meta.blockId) continue;
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
