import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/line_clear.dart';
import '../logic/spawner.dart';
import '../models/block.dart';
import '../models/board.dart';
import '../models/game_state.dart';

const int _boardWidth = 8;
const int _boardHeight = 8;

/// ポイント計算:
/// - 行の特典: 行数の二乗 * 100
/// - 列の特典: 列数の二乗 * 100
/// - 十字架消し（行と列の同時成立）: 1000点を加算
int _pointsForClear({
  required Set<int> triggerRows,
  required Set<int> triggerCols,
}) {
  final rowPoints = triggerRows.length * triggerRows.length * 100;
  final colPoints = triggerCols.length * triggerCols.length * 100;
  final crossBonus = (triggerRows.isNotEmpty && triggerCols.isNotEmpty) ? 1000 : 0;
  return rowPoints + colPoints + crossBonus;
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());

class GameNotifier extends StateNotifier<GameState> {
  late final LineClear _lineClear;
  late final Spawner _spawner;
  final Random _random = Random();

  GameNotifier()
      : super(GameState.initial(
          boardWidth: _boardWidth,
          boardHeight: _boardHeight,
        )) {
    _lineClear = LineClear(
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
    _spawner = Spawner(
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
  }

  void startGame() {
    var blocks = <Block>[];
    final first = _spawner.spawn(blocks);
    if (first == null) {
      state = state.copyWith(phase: GamePhase.gameOver, clearSlideDirectionHistory: true);
      return;
    }
    blocks = [first.copyWith(colorIndex: _random.nextInt(100))];

    final nextBlockPerDirection = {
      for (final d in SlideDirection.values) d: BlockShape.random(_random),
    };
    final nextBlockColorPerDirection = {
      for (final d in SlideDirection.values) d: _random.nextInt(100),
    };

    state = state.copyWith(
      phase: GamePhase.playing,
      blocks: blocks,
      score: 0,
      linesCleared: 0,
      playCount: 0,
      nextBlockPerDirection: nextBlockPerDirection,
      nextBlockColorPerDirection: nextBlockColorPerDirection,
      clearSlideDirectionHistory: true,
      board: Board.fromBlocks(
        width: _boardWidth,
        height: _boardHeight,
        blocks: blocks
            .map((b) => (
                  blockId: b.blockId,
                  cells: b.occupiedCells,
                ))
            .toList(),
      ),
    );
  }

  static const _clearAnimationDuration = Duration(milliseconds: 500);
  static const _slideAnimationDuration = Duration(milliseconds: 350);

  Future<void> slide(SlideDirection direction) async {
    if (state.phase != GamePhase.playing) return;
    if (state.clearingCells.isNotEmpty) return;
    if (state.slideAnimations.isNotEmpty) return;

    // この方向の次ブロックが置けないなら何もしない（ボタン無効扱い）
    final nextShape = state.nextBlockPerDirection[direction];
    if (nextShape == null || !_canSpawnShapeFromDirection(nextShape, direction, state.blocks)) {
      return;
    }
    const newConsecutiveCount = 0;

    final oldBlocks = state.blocks;

    // スライド1回 = 1プレイ。10プレイごとに10点ボーナス
    final newPlayCount = state.playCount + 1;
    var totalScoreGained = (newPlayCount % 10 == 0) ? 10 : 0;
    var totalLinesCleared = 0;

    // 既存ブロックと新ブロックを同時に進める（すり抜け防止）
    final spawnResult = _trySpawnShapeSimultaneously(nextShape, direction, oldBlocks);
    if (spawnResult == null) {
      state = state.copyWith(
        blocks: oldBlocks,
        score: state.score + totalScoreGained,
        linesCleared: state.linesCleared + totalLinesCleared,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: oldBlocks
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
      );
      // 全方向から置けなくなったらゲームオーバー
      if (!_canPlaceNewBlock(oldBlocks)) {
        state = state.copyWith(phase: GamePhase.gameOver);
      }
      return;
    }

    // この方向の次ブロックを更新（次の出現用に新しい形をランダム設定）
    final newNextBlocks = Map<SlideDirection, BlockShape>.from(state.nextBlockPerDirection)
      ..[direction] = BlockShape.random(_random);
    final newNextColors = Map<SlideDirection, int>.from(state.nextBlockColorPerDirection)
      ..[direction] = _random.nextInt(100);

    final idx = state.nextBlockColorPerDirection[direction] ?? _random.nextInt(100);
    final newBlock = spawnResult.newBlock.copyWith(colorIndex: idx);
    final settledNew = spawnResult.settled.copyWith(colorIndex: idx);
    final slidBlocks = spawnResult.slidExistingBlocks;
    var blocks = [...slidBlocks, settledNew];

    final slideAnims = <String, ({int fromCol, int fromRow, int toCol, int toRow})>{};
    for (final b in slidBlocks) {
      final old = oldBlocks.where((o) => o.blockId == b.blockId).firstOrNull;
      if (old != null && (old.col != b.col || old.row != b.row)) {
        slideAnims[b.blockId] = (fromCol: old.col, fromRow: old.row, toCol: b.col, toRow: b.row);
      }
    }
    if (newBlock.col != settledNew.col || newBlock.row != settledNew.row) {
      slideAnims[newBlock.blockId] = (
        fromCol: newBlock.col,
        fromRow: newBlock.row,
        toCol: settledNew.col,
        toRow: settledNew.row,
      );
    }

    if (slideAnims.isNotEmpty) {
      state = state.copyWith(
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
        nextBlockColorPerDirection: newNextColors,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocks
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
        slideAnimations: slideAnims,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
      );
      await Future.delayed(_slideAnimationDuration);
      state = state.copyWith(slideAnimations: {});
    } else {
      state = state.copyWith(
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
        nextBlockColorPerDirection: newNextColors,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocks
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
      );
    }

    // スライド完了後に消去（アニメーション付き）
    while (true) {
      final clearResult = _lineClear.clear(blocks);
      if (clearResult.linesCleared == 0) break;

      final linesThisClear = clearResult.linesCleared;
      totalScoreGained += _pointsForClear(
        triggerRows: clearResult.triggerRows,
        triggerCols: clearResult.triggerCols,
      );
      totalLinesCleared += linesThisClear;

      final boardBeforeClear = Board.fromBlocks(
        width: _boardWidth,
        height: _boardHeight,
        blocks: blocks
            .map((b) => (
                  blockId: b.blockId,
                  cells: b.occupiedCells,
                ))
            .toList(),
      );
      state = state.copyWith(
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
        nextBlockColorPerDirection: newNextColors,
        board: boardBeforeClear,
        clearingCells: clearResult.clearedCells,
        clearingTriggerRows: clearResult.triggerRows,
        clearingTriggerCols: clearResult.triggerCols,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
      );
      await Future.delayed(_clearAnimationDuration);
      blocks = clearResult.blocks;
      state = state.copyWith(
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
        nextBlockColorPerDirection: newNextColors,
        clearingCells: {},
        clearingTriggerRows: {},
        clearingTriggerCols: {},
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocks
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
      );
    }

    // ゲームオーバー: 新しいブロックがどの方向からも置けなくなったら
    if (!_canPlaceNewBlock(blocks)) {
      state = state.copyWith(
        phase: GamePhase.gameOver,
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
        nextBlockColorPerDirection: newNextColors,
        score: state.score + totalScoreGained,
        linesCleared: state.linesCleared + totalLinesCleared,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocks
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
      );
      return;
    }

    state = state.copyWith(
      blocks: blocks,
      nextBlockPerDirection: newNextBlocks,
      nextBlockColorPerDirection: newNextColors,
      score: state.score + totalScoreGained,
      linesCleared: state.linesCleared + totalLinesCleared,
      lastSlideDirection: direction,
      consecutiveSameDirectionCount: newConsecutiveCount,
      playCount: newPlayCount,
      board: Board.fromBlocks(
        width: _boardWidth,
        height: _boardHeight,
        blocks: blocks
            .map((b) => (
                  blockId: b.blockId,
                  cells: b.occupiedCells,
                ))
            .toList(),
      ),
    );
  }

  /// ブロックが盤内に完全に収まり、既存ブロックと重ならないか
  bool _blockCanBePlaced(Block block, List<Block> existingBlocks) {
    final occupied = <(int, int)>{};
    for (final b in existingBlocks) {
      for (final cell in b.occupiedCells) {
        if (cell.$1 >= 0 && cell.$1 < _boardWidth &&
            cell.$2 >= 0 && cell.$2 < _boardHeight) {
          occupied.add(cell);
        }
      }
    }
    for (final (c, r) in block.occupiedCells) {
      if (c < 0 || c >= _boardWidth || r < 0 || r >= _boardHeight) {
        return false;
      }
      if (occupied.contains((c, r))) return false;
    }
    return true;
  }

  /// 指定形状が [direction] から置けるか。
  /// 置ける＝既存ブロックと新ブロックを同時に進めた結果、全ブロックが枠内に収まる。
  /// 置けない＝その方向から置くと必ず枠外にブロックが出る場合のみ。
  bool _canSpawnShapeFromDirection(BlockShape shape, SlideDirection direction, List<Block> blocks) {
    return _trySpawnShapeSimultaneously(shape, direction, blocks) != null;
  }

  ({Block newBlock, Block settled, List<Block> slidExistingBlocks})? _trySpawnShapeSimultaneously(
    BlockShape shape,
    SlideDirection direction,
    List<Block> blocks,
  ) {
    final candidates = _spawner.blocksAtEdgeForShape(shape, direction)..shuffle(_random);
    for (final blockAtEdge in candidates) {
      final newBlock = Block(
        blockId: 'block_${DateTime.now().millisecondsSinceEpoch}',
        shape: shape,
        col: blockAtEdge.col,
        row: blockAtEdge.row,
      );
      final sim = _simulateSimultaneousSlide(blocks, newBlock, direction);
      if (sim == null) continue;
      if (_blockCanBePlaced(sim.settledIncoming, sim.slidExisting)) {
        return (
          newBlock: newBlock,
          settled: sim.settledIncoming,
          slidExistingBlocks: sim.slidExisting,
        );
      }
    }
    return null;
  }

  ({List<Block> slidExisting, Block settledIncoming})? _simulateSimultaneousSlide(
    List<Block> existingBlocks,
    Block incoming,
    SlideDirection direction,
  ) {
    var currentExisting = List<Block>.from(existingBlocks);
    var currentIncoming = incoming;

    // 盤面サイズ以上は進めないため、安全側で反復上限を設ける
    final maxSteps = (_boardWidth + _boardHeight) * 2;
    for (var i = 0; i < maxSteps; i++) {
      final movedExisting = _moveExistingOneStep(currentExisting, direction);
      final occupiedAfterExisting = <(int, int)>{};
      for (final b in movedExisting.blocks) {
        for (final cell in b.occupiedCells) {
          if (cell.$1 >= 0 && cell.$1 < _boardWidth && cell.$2 >= 0 && cell.$2 < _boardHeight) {
            occupiedAfterExisting.add(cell);
          }
        }
      }

      final nextIncoming = _moveOne(currentIncoming, direction);
      final incomingCanMove = !_wouldCollide(nextIncoming, occupiedAfterExisting);
      final movedIncoming = incomingCanMove ? nextIncoming : currentIncoming;

      // 同期ステップ中の一時重なりは、次の位置で解消できるなら許可。
      // 解消できない重なりのみ不正扱いにして、すり抜けを防ぐ。
      final overlapsNow = currentIncoming.occupiedCells
          .any((cell) => occupiedAfterExisting.contains(cell));
      if (overlapsNow && !incomingCanMove) {
        return null;
      }

      currentExisting = movedExisting.blocks;
      currentIncoming = movedIncoming;

      if (!movedExisting.movedAny && !incomingCanMove) {
        break;
      }
    }

    return (slidExisting: currentExisting, settledIncoming: currentIncoming);
  }

  ({List<Block> blocks, bool movedAny}) _moveExistingOneStep(
    List<Block> blocks,
    SlideDirection direction,
  ) {
    if (blocks.isEmpty) return (blocks: const <Block>[], movedAny: false);
    final sorted = _sortByLeadingEdge(blocks, direction);
    final occupied = <(int, int)>{};
    for (final b in blocks) {
      for (final cell in b.occupiedCells) {
        if (cell.$1 >= 0 && cell.$1 < _boardWidth && cell.$2 >= 0 && cell.$2 < _boardHeight) {
          occupied.add(cell);
        }
      }
    }

    final byId = <String, Block>{for (final b in blocks) b.blockId: b};
    var movedAny = false;
    for (final b in sorted) {
      for (final cell in b.occupiedCells) {
        occupied.remove(cell);
      }
      final next = _moveOne(b, direction);
      final canMove = !_wouldCollide(next, occupied);
      final settled = canMove ? next : b;
      if (canMove) movedAny = true;
      byId[b.blockId] = settled;
      for (final cell in settled.occupiedCells) {
        occupied.add(cell);
      }
    }

    return (
      blocks: blocks.map((b) => byId[b.blockId] ?? b).toList(),
      movedAny: movedAny,
    );
  }

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
      if (c < 0 || c >= _boardWidth || r < 0 || r >= _boardHeight) {
        return true;
      }
      if (occupied.contains((c, r))) return true;
    }
    return false;
  }

  /// いずれかの方向で次ブロックが置けるか（ゲームオーバー判定用）
  bool _canPlaceNewBlock(List<Block> blocks) {
    final nextBlocks = state.nextBlockPerDirection;
    for (final direction in SlideDirection.values) {
      final shape = nextBlocks[direction];
      if (shape != null && _canSpawnShapeFromDirection(shape, direction, blocks)) {
        return true;
      }
    }
    return false;
  }

  /// この方向のボタンが押せるか（スライド可能かつ次ブロックが置ける）
  bool canSlideDirection(SlideDirection direction) {
    if (state.phase != GamePhase.playing) return false;
    if (state.clearingCells.isNotEmpty || state.slideAnimations.isNotEmpty) return false;
    final shape = state.nextBlockPerDirection[direction];
    if (shape == null) return false;
    return _canSpawnShapeFromDirection(shape, direction, state.blocks);
  }

  void backToMenu() {
    state = GameState.initial(
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
  }
}
