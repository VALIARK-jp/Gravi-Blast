/// Represents the game board state.
/// [width] x [height] grid. Each cell is either empty (null) or holds a blockId.
class Board {
  final int width;
  final int height;
  final List<List<String?>> _grid;

  Board({
    required this.width,
    required this.height,
  }) : _grid = List.generate(
          height,
          (_) => List.filled(width, null as String?),
        );

  Board._(this.width, this.height, this._grid);

  String? cell(int col, int row) {
    if (col < 0 || col >= width || row < 0 || row >= height) {
      return null;
    }
    return _grid[row][col];
  }

  bool isInBounds(int col, int row) {
    return col >= 0 && col < width && row >= 0 && row < height;
  }

  bool isEmpty(int col, int row) {
    return isInBounds(col, row) && cell(col, row) == null;
  }

  Board copyWithGrid(List<List<String?>> grid) {
    return Board._(width, height, grid);
  }

  /// Build a fresh Board from a list of blocks (used after slide / spawn).
  static Board fromBlocks({
    required int width,
    required int height,
    required List<({String blockId, List<(int, int)> cells})> blocks,
  }) {
    final grid = List.generate(
      height,
      (_) => List.filled(width, null as String?),
    );
    for (final b in blocks) {
      for (final (c, r) in b.cells) {
        if (c >= 0 && c < width && r >= 0 && r < height) {
          grid[r][c] = b.blockId;
        }
      }
    }
    return Board._(width, height, grid);
  }

  /// Returns row indices that are completely filled.
  List<int> getFullRows() {
    final result = <int>[];
    for (var r = 0; r < height; r++) {
      var full = true;
      for (var c = 0; c < width; c++) {
        if (_grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) result.add(r);
    }
    return result;
  }

  /// Returns column indices that are completely filled.
  List<int> getFullCols() {
    final result = <int>[];
    for (var c = 0; c < width; c++) {
      var full = true;
      for (var r = 0; r < height; r++) {
        if (_grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) result.add(c);
    }
    return result;
  }

  /// Create a copy with a specific cell set (for testing/debug).
  Board setCell(int col, int row, String? blockId) {
    if (!isInBounds(col, row)) return this;
    final newGrid = _grid.map((row) => row.toList()).toList();
    newGrid[row][col] = blockId;
    return Board._(width, height, newGrid);
  }
}
