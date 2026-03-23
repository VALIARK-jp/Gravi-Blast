import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/line_clear.dart';
import '../logic/slide_engine.dart';
import '../logic/spawner.dart';
import '../models/block.dart';
import '../models/board.dart';
import '../models/game_state.dart';

const int _boardWidth = 8;
const int _boardHeight = 8;

/// 同時消しライン数に応じたポイント（1列100/2列40/3列90/10列100）
int _pointsForLines(int lines) {
  return switch (lines) {
    1 => 100,
    2 => 40,
    3 => 90,
    10 => 100,
    _ => lines * 10, // 4〜9列は1列あたり10点で線形
  };
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());

class GameNotifier extends StateNotifier<GameState> {
  late final SlideEngine _slideEngine;
  late final LineClear _lineClear;
  late final Spawner _spawner;
  final Random _random = Random();

  GameNotifier()
      : super(GameState.initial(
          boardWidth: _boardWidth,
          boardHeight: _boardHeight,
        )) {
    _slideEngine = SlideEngine(
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
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

    state = state.copyWith(
      phase: GamePhase.playing,
      blocks: blocks,
      score: 0,
      linesCleared: 0,
      playCount: 0,
      nextBlockPerDirection: nextBlockPerDirection,
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

    // 同じ方向は連続2回まで
    if (state.lastSlideDirection == direction &&
        state.consecutiveSameDirectionCount >= 2) {
      return;
    }

    // この方向の次ブロックが置けないなら何もしない（ボタン無効扱い）
    final nextShape = state.nextBlockPerDirection[direction];
    if (nextShape == null || !_canSpawnShapeFromDirection(nextShape, direction, state.blocks)) {
      return;
    }
    final newConsecutiveCount = state.lastSlideDirection == direction
        ? state.consecutiveSameDirectionCount + 1
        : 1;

    final oldBlocks = state.blocks;
    var blocks = _slideEngine.slide(oldBlocks, direction);

    final slideAnims = <String, ({int fromCol, int fromRow, int toCol, int toRow})>{};
    for (final b in blocks) {
      final old = oldBlocks.where((o) => o.blockId == b.blockId).firstOrNull;
      if (old != null && (old.col != b.col || old.row != b.row)) {
        slideAnims[b.blockId] = (fromCol: old.col, fromRow: old.row, toCol: b.col, toRow: b.row);
      }
    }
    if (slideAnims.isNotEmpty) {
      state = state.copyWith(
        blocks: blocks,
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
      );
      await Future.delayed(_slideAnimationDuration);
      state = state.copyWith(slideAnimations: {});
    }

    // スライド1回 = 1プレイ。10プレイごとに10点ボーナス
    final newPlayCount = state.playCount + 1;
    var totalScoreGained = (newPlayCount % 10 == 0) ? 10 : 0;

    // 一列繋がった時点で消去（0.5秒アニメーション付き）
    var totalLinesCleared = 0;
    while (true) {
      final clearResult = _lineClear.clear(blocks);
      if (clearResult.linesCleared == 0) break;

      final linesThisClear = clearResult.linesCleared;
      totalScoreGained += _pointsForLines(linesThisClear);
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

    // 画面外から次ブロック（ predetermined shape）を重力方向にスライドして落下
    final spawnResult = _spawner.trySpawnShapeAtEdge(
      nextShape,
      direction,
      (b) => _slideEngine.slideNewBlock(b, blocks, direction),
      (b) => _blockCanBePlaced(b, blocks),
    );
    if (spawnResult == null) {
      state = state.copyWith(
        blocks: blocks,
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
      // 全方向から置けなくなったらゲームオーバー
      if (!_canPlaceNewBlock(blocks)) {
        state = state.copyWith(phase: GamePhase.gameOver);
      }
      return;
    }

    // この方向の次ブロックを更新（次の出現用に新しい形をランダム設定）
    final newNextBlocks = Map<SlideDirection, BlockShape>.from(state.nextBlockPerDirection)
      ..[direction] = BlockShape.random(_random);

    final idx = _random.nextInt(100);
    final newBlock = spawnResult.newBlock.copyWith(colorIndex: idx);
    final settledNew = spawnResult.settled.copyWith(colorIndex: idx);
    final blocksAfterSpawn = [...blocks, settledNew];
    final moved = newBlock.col != settledNew.col || newBlock.row != settledNew.row;
    if (moved) {
      state = state.copyWith(
        blocks: blocksAfterSpawn,
        nextBlockPerDirection: newNextBlocks,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocksAfterSpawn
              .map((b) => (
                    blockId: b.blockId,
                    cells: b.occupiedCells,
                  ))
              .toList(),
        ),
        slideAnimations: {
          newBlock.blockId: (
            fromCol: newBlock.col,
            fromRow: newBlock.row,
            toCol: settledNew.col,
            toRow: settledNew.row,
          ),
        },
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
      );
      await Future.delayed(_slideAnimationDuration);
      state = state.copyWith(slideAnimations: {});
    } else {
      state = state.copyWith(
        blocks: blocksAfterSpawn,
        nextBlockPerDirection: newNextBlocks,
        board: Board.fromBlocks(
          width: _boardWidth,
          height: _boardHeight,
          blocks: blocksAfterSpawn
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
    blocks = blocksAfterSpawn;

    // 新ブロック着地後も一列繋がった時点で消去（アニメーション付き）
    while (true) {
      final clearResult = _lineClear.clear(blocks);
      if (clearResult.linesCleared == 0) break;

      final linesThisClear = clearResult.linesCleared;
      totalScoreGained += _pointsForLines(linesThisClear);
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

    // 最終確認: 一列でも残っていれば消去（アニメーション付き）
    while (true) {
      final finalClear = _lineClear.clear(blocks);
      if (finalClear.linesCleared == 0) break;

      final linesThisClear = finalClear.linesCleared;
      totalScoreGained += _pointsForLines(linesThisClear);
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
        board: boardBeforeClear,
        clearingCells: finalClear.clearedCells,
        clearingTriggerRows: finalClear.triggerRows,
        clearingTriggerCols: finalClear.triggerCols,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
        playCount: newPlayCount,
      );
      await Future.delayed(_clearAnimationDuration);
      blocks = finalClear.blocks;
      state = state.copyWith(
        blocks: blocks,
        nextBlockPerDirection: newNextBlocks,
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

    state = state.copyWith(
      blocks: blocks,
      nextBlockPerDirection: newNextBlocks,
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
  /// 置ける＝スライド＋ライン消去後の盤面に新ブロックを置いた結果、全ブロックが枠内に収まる。
  /// 置けない＝その方向から置くと必ず枠外にブロックが出る場合のみ。
  bool _canSpawnShapeFromDirection(BlockShape shape, SlideDirection direction, List<Block> blocks) {
    // 実際のゲームと同じ順序: スライド → ライン消去 → 新ブロック出現
    var blocksAfterSlide = _slideEngine.slide(blocks, direction);
    while (true) {
      final clearResult = _lineClear.clear(blocksAfterSlide);
      if (clearResult.linesCleared == 0) break;
      blocksAfterSlide = clearResult.blocks;
    }
    return _spawner.trySpawnShapeAtEdge(
      shape,
      direction,
      (b) => _slideEngine.slideNewBlock(b, blocksAfterSlide, direction),
      (b) => _blockCanBePlaced(b, blocksAfterSlide),
    ) != null;
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
    if (state.lastSlideDirection == direction && state.consecutiveSameDirectionCount >= 2) return false;
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
