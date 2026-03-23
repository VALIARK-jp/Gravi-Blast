import 'dart:math';

/// Fixed shape definitions for blocks.
/// Each shape is represented as `List<List<int>>` where 1 = occupied, 0 = empty.
/// Origin is top-left.
class BlockShape {
  final List<List<int>> cells;
  final String id;

  const BlockShape({
    required this.id,
    required this.cells,
  });

  int get width => cells.isNotEmpty ? cells.first.length : 0;
  int get height => cells.length;

  /// Returns all (col, row) coordinates relative to top-left origin
  /// where the block occupies a cell. Format: (col, row).
  List<(int, int)> get occupiedOffsets {
    final result = <(int, int)>[];
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if (cells[r][c] == 1) {
          result.add((c, r));
        }
      }
    }
    return result;
  }

  /// All predefined block shapes (1x1廃止、稲妻・プラス・1x4追加)
  static const List<BlockShape> all = [
    horizontal2,
    horizontal3,
    horizontal4,
    vertical2,
    vertical3,
    vertical4,
    square,
    lShape,
    tShape,
    lightningShape,
    plusShape,
  ];

  // 1x2 horizontal
  static const horizontal2 = BlockShape(
    id: 'h2',
    cells: [
      [1, 1],
    ],
  );

  // 1x3 horizontal
  static const horizontal3 = BlockShape(
    id: 'h3',
    cells: [
      [1, 1, 1],
    ],
  );

  // 1x4 horizontal
  static const horizontal4 = BlockShape(
    id: 'h4',
    cells: [
      [1, 1, 1, 1],
    ],
  );

  // 2x1 vertical
  static const vertical2 = BlockShape(
    id: 'v2',
    cells: [
      [1],
      [1],
    ],
  );

  // 3x1 vertical
  static const vertical3 = BlockShape(
    id: 'v3',
    cells: [
      [1],
      [1],
      [1],
    ],
  );

  // 4x1 vertical
  static const vertical4 = BlockShape(
    id: 'v4',
    cells: [
      [1],
      [1],
      [1],
      [1],
    ],
  );

  // 2x2 square
  static const square = BlockShape(
    id: 'square',
    cells: [
      [1, 1],
      [1, 1],
    ],
  );

  // L shape
  static const lShape = BlockShape(
    id: 'l',
    cells: [
      [1, 0],
      [1, 0],
      [1, 1],
    ],
  );

  // T shape
  static const tShape = BlockShape(
    id: 't',
    cells: [
      [1, 1, 1],
      [0, 1, 0],
    ],
  );

  // 稲妻型 (lightning / Z shape)
  static const lightningShape = BlockShape(
    id: 'lightning',
    cells: [
      [1, 0],
      [1, 1],
      [0, 1],
    ],
  );

  // プラス型 (plus / cross)
  static const plusShape = BlockShape(
    id: 'plus',
    cells: [
      [0, 1, 0],
      [1, 1, 1],
      [0, 1, 0],
    ],
  );

  static BlockShape random(Random random) {
    return all[random.nextInt(all.length)];
  }

  /// Creates a shape from a set of cells (for fragments after partial line clear).
  /// [cells] are board coordinates (col, row).
  static BlockShape fromCells(List<(int, int)> cells) {
    if (cells.isEmpty) {
      return const BlockShape(id: 'empty', cells: []);
    }
    final minC = cells.map((e) => e.$1).reduce((a, b) => a < b ? a : b);
    final minR = cells.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final maxC = cells.map((e) => e.$1).reduce((a, b) => a > b ? a : b);
    final maxR = cells.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    final w = maxC - minC + 1;
    final h = maxR - minR + 1;
    final grid = List.generate(h, (_) => List.filled(w, 0));
    for (final (c, r) in cells) {
      grid[r - minR][c - minC] = 1;
    }
    return BlockShape(id: 'fragment', cells: grid);
  }
}

/// A block instance placed on the board.
/// [col] and [row] are the top-left position of the block's bounding box.
class Block {
  final String blockId;
  final BlockShape shape;
  final int col;
  final int row;
  /// 色の割当用インデックス（0〜99で100色を周期）
  final int colorIndex;

  const Block({
    required this.blockId,
    required this.shape,
    required this.col,
    required this.row,
    this.colorIndex = 0,
  });

  Block copyWith({int? col, int? row, int? colorIndex}) {
    return Block(
      blockId: blockId,
      shape: shape,
      col: col ?? this.col,
      row: row ?? this.row,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  /// All (col, row) board coordinates occupied by this block
  List<(int, int)> get occupiedCells {
    return shape.occupiedOffsets
        .map((o) => (col + o.$1, row + o.$2))
        .toList();
  }

  int get minCol => col;
  int get maxCol => shape.width > 0 ? col + shape.width - 1 : col;
  int get minRow => row;
  int get maxRow => shape.height > 0 ? row + shape.height - 1 : row;

  /// Creates a block from a set of cells (for fragments after partial line clear).
  static Block fromCells({
    required String blockId,
    required List<(int, int)> cells,
    int colorIndex = 0,
  }) {
    if (cells.isEmpty) {
      throw ArgumentError('cells must not be empty');
    }
    final minC = cells.map((e) => e.$1).reduce((a, b) => a < b ? a : b);
    final minR = cells.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final shape = BlockShape.fromCells(cells);
    return Block(
      blockId: blockId,
      shape: shape,
      col: minC,
      row: minR,
      colorIndex: colorIndex,
    );
  }
}
