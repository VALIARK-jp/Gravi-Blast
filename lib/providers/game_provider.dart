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
const int _pointsPerLine = 10;

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

    state = state.copyWith(
      phase: GamePhase.playing,
      blocks: blocks,
      score: 0,
      linesCleared: 0,
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

    // 一列繋がった時点で消去（0.5秒アニメーション付き）
    var totalLinesCleared = 0;
    var totalScoreGained = 0;
    while (true) {
      final clearResult = _lineClear.clear(blocks);
      if (clearResult.linesCleared == 0) break;

      final linesThisClear = clearResult.linesCleared;
      var points = linesThisClear * _pointsPerLine;
      if (linesThisClear >= 2) points *= 2; // 同時消し2倍
      totalScoreGained += points;
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

    // 画面外から新ブロックを重力方向にスライドして落下（障害物で止まる、アニメーション付き）
    // 置ける場所がなければゲームオーバー。置ける形・位置を探してから出現させる。
    final spawnResult = _spawner.trySpawnAtEdge(
      direction,
      (b) => _slideEngine.slideNewBlock(b, blocks, direction),
      _blockFullyOnBoard,
    );
    if (spawnResult == null) {
      state = state.copyWith(
        phase: GamePhase.gameOver,
        blocks: blocks,
        score: state.score + totalScoreGained,
        linesCleared: state.linesCleared + totalLinesCleared,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
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

    final idx = _random.nextInt(100);
    final newBlock = spawnResult.newBlock.copyWith(colorIndex: idx);
    final settledNew = spawnResult.settled.copyWith(colorIndex: idx);
    final blocksAfterSpawn = [...blocks, settledNew];
    final moved = newBlock.col != settledNew.col || newBlock.row != settledNew.row;
    if (moved) {
      state = state.copyWith(
        blocks: blocksAfterSpawn,
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
      );
      await Future.delayed(_slideAnimationDuration);
      state = state.copyWith(slideAnimations: {});
    } else {
      state = state.copyWith(
        blocks: blocksAfterSpawn,
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
      );
    }
    blocks = blocksAfterSpawn;

    // 新ブロック着地後も一列繋がった時点で消去（アニメーション付き）
    while (true) {
      final clearResult = _lineClear.clear(blocks);
      if (clearResult.linesCleared == 0) break;

      final linesThisClear = clearResult.linesCleared;
      var points = linesThisClear * _pointsPerLine;
      if (linesThisClear >= 2) points *= 2;
      totalScoreGained += points;
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
        score: state.score + totalScoreGained,
        linesCleared: state.linesCleared + totalLinesCleared,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
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
      var points = linesThisClear * _pointsPerLine;
      if (linesThisClear >= 2) points *= 2;
      totalScoreGained += points;
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
        clearingCells: finalClear.clearedCells,
        clearingTriggerRows: finalClear.triggerRows,
        clearingTriggerCols: finalClear.triggerCols,
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
      );
      await Future.delayed(_clearAnimationDuration);
      blocks = finalClear.blocks;
      state = state.copyWith(
        blocks: blocks,
        clearingCells: {},
        clearingTriggerRows: {},
        clearingTriggerCols: {},
        lastSlideDirection: direction,
        consecutiveSameDirectionCount: newConsecutiveCount,
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
      score: state.score + totalScoreGained,
      linesCleared: state.linesCleared + totalLinesCleared,
      lastSlideDirection: direction,
      consecutiveSameDirectionCount: newConsecutiveCount,
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

  bool _blockFullyOnBoard(Block block) {
    for (final (c, r) in block.occupiedCells) {
      if (c < 0 || c >= _boardWidth || r < 0 || r >= _boardHeight) {
        return false;
      }
    }
    return true;
  }

  /// いずれかの形状ブロックが、いずれかの方向からスライドして置けるか
  bool _canPlaceNewBlock(List<Block> blocks) {
    for (final direction in SlideDirection.values) {
      for (final shape in BlockShape.all) {
        for (final blockAtEdge in _spawner.blocksAtEdgeForShape(shape, direction)) {
          final settled = _slideEngine.slideNewBlock(blockAtEdge, blocks, direction);
          if (_blockFullyOnBoard(settled)) return true;
        }
      }
    }
    return false;
  }

  void backToMenu() {
    state = GameState.initial(
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
  }
}
