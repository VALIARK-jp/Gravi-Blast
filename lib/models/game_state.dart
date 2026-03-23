import 'board.dart';
import 'block.dart';

/// Direction for sliding the board.
enum SlideDirection {
  up,
  down,
  left,
  right,
}

/// Current phase of the game.
enum GamePhase {
  menu,
  playing,
  gameOver,
}

/// Immutable game state.
class GameState {
  final GamePhase phase;
  final Board board;
  final List<Block> blocks;
  final int score;
  final int linesCleared;
  /// スライド回数（10プレイごとに10点ボーナス用）
  final int playCount;
  /// Cells currently animating the clear effect (fade out).
  final Set<(int, int)> clearingCells;
  /// 揃ったトリガー行（アニメ差別化用）
  final Set<int> clearingTriggerRows;
  /// 揃ったトリガー列（アニメ差別化用）
  final Set<int> clearingTriggerCols;
  /// Blocks sliding from (fromCol,fromRow) to (toCol,toRow). Empty = no slide anim.
  final Map<String, ({int fromCol, int fromRow, int toCol, int toRow})> slideAnimations;
  /// 直前のスライド方向（連続回数制限用）
  final SlideDirection? lastSlideDirection;
  /// 同じ方向の連続回数
  final int consecutiveSameDirectionCount;
  /// 各方向から次に出現するブロックの形
  final Map<SlideDirection, BlockShape> nextBlockPerDirection;
  /// 各方向から次に出現するブロックの色インデックス（0〜99）
  final Map<SlideDirection, int> nextBlockColorPerDirection;

  const GameState({
    required this.phase,
    required this.board,
    required this.blocks,
    this.score = 0,
    this.linesCleared = 0,
    this.playCount = 0,
    this.clearingCells = const {},
    this.clearingTriggerRows = const {},
    this.clearingTriggerCols = const {},
    this.slideAnimations = const {},
    this.lastSlideDirection,
    this.consecutiveSameDirectionCount = 0,
    this.nextBlockPerDirection = const {},
    this.nextBlockColorPerDirection = const {},
  });

  GameState copyWith({
    GamePhase? phase,
    Board? board,
    List<Block>? blocks,
    int? score,
    int? linesCleared,
    int? playCount,
    Set<(int, int)>? clearingCells,
    Set<int>? clearingTriggerRows,
    Set<int>? clearingTriggerCols,
    Map<String, ({int fromCol, int fromRow, int toCol, int toRow})>? slideAnimations,
    SlideDirection? lastSlideDirection,
    int? consecutiveSameDirectionCount,
    Map<SlideDirection, BlockShape>? nextBlockPerDirection,
    Map<SlideDirection, int>? nextBlockColorPerDirection,
    bool clearSlideDirectionHistory = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      board: board ?? this.board,
      blocks: blocks ?? this.blocks,
      score: score ?? this.score,
      linesCleared: linesCleared ?? this.linesCleared,
      playCount: clearSlideDirectionHistory ? 0 : (playCount ?? this.playCount),
      clearingCells: clearingCells ?? this.clearingCells,
      clearingTriggerRows: clearingTriggerRows ?? this.clearingTriggerRows,
      clearingTriggerCols: clearingTriggerCols ?? this.clearingTriggerCols,
      slideAnimations: slideAnimations ?? this.slideAnimations,
      lastSlideDirection: clearSlideDirectionHistory ? null : (lastSlideDirection ?? this.lastSlideDirection),
      consecutiveSameDirectionCount: clearSlideDirectionHistory ? 0 : (consecutiveSameDirectionCount ?? this.consecutiveSameDirectionCount),
      nextBlockPerDirection: nextBlockPerDirection ?? this.nextBlockPerDirection,
      nextBlockColorPerDirection: nextBlockColorPerDirection ?? this.nextBlockColorPerDirection,
    );
  }

  static GameState initial({
    int boardWidth = 8,
    int boardHeight = 8,
  }) {
    return GameState(
      phase: GamePhase.menu,
      board: Board(width: boardWidth, height: boardHeight),
      blocks: [],
    );
  }
}
