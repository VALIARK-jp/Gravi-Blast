import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/direction_buttons.dart';
import '../widgets/game_board.dart';
import '../widgets/game_over_leaderboard.dart';
import '../widgets/leaderboard_header_row.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(gameProvider);
      if (state.phase == GamePhase.menu) {
        ref.read(gameProvider.notifier).startGame();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final gameState = ref.read(gameProvider);
    if (gameState.phase != GamePhase.playing) return false;
    final notifier = ref.read(gameProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && notifier.canSlideDirection(SlideDirection.up)) {
      notifier.slide(SlideDirection.up);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && notifier.canSlideDirection(SlideDirection.down)) {
      notifier.slide(SlideDirection.down);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && notifier.canSlideDirection(SlideDirection.left)) {
      notifier.slide(SlideDirection.left);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && notifier.canSlideDirection(SlideDirection.right)) {
      notifier.slide(SlideDirection.right);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.phase == GamePhase.gameOver && previous?.phase != GamePhase.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await submitGameOverLeaderboardIfNeeded(context, ref, next.score);
        });
      }
    });

    if (gameState.phase == GamePhase.gameOver) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _ScoreHeader(
              score: gameState.score,
              linesCleared: gameState.linesCleared,
            ),
            Expanded(
              child: _GameOverOverlay(
                score: gameState.score,
                linesCleared: gameState.linesCleared,
                onRestart: notifier.startGame,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _ScoreHeader(
            score: gameState.score,
            linesCleared: gameState.linesCleared,
          ),
          Expanded(
            child: _GameBody(
              notifier: notifier,
              gameState: gameState,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final int linesCleared;

  const _ScoreHeader({
    required this.score,
    required this.linesCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: LeaderboardScoreHeader(
        currentScore: score,
        linesCleared: linesCleared,
      ),
    );
  }
}

class _GameBody extends StatefulWidget {
  final dynamic notifier;
  final GameState gameState;

  const _GameBody({
    required this.notifier,
    required this.gameState,
  });

  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  /// スワイプ中の累積移動量（ゆっくりドラッグでも反応するため）
  Offset _panDelta = Offset.zero;

  bool get _canSlide =>
      widget.gameState.clearingCells.isEmpty && widget.gameState.slideAnimations.isEmpty;

  void _onPanEnd(DragEndDetails details) {
    if (!_canSlide) return;

    final v = details.velocity.pixelsPerSecond;
    // フリック: 速度が十分あるときは速度ベクトルで判定
    const velocityFling = 200.0;
    // ゆっくりスワイプ: 距離で判定
    const distanceSwipe = 30.0;
    const axisRatio = 1.15;
    const velAxis = 130.0;
    const distAxis = 22.0;

    double dx;
    double dy;
    final useVelocity = v.distance >= velocityFling;

    if (useVelocity) {
      dx = v.dx;
      dy = v.dy;
    } else {
      dx = _panDelta.dx;
      dy = _panDelta.dy;
      if (Offset(dx, dy).distance < distanceSwipe) return;
    }

    final absX = dx.abs();
    final absY = dy.abs();

    void trySlide(SlideDirection d) {
      if (widget.notifier.canSlideDirection(d)) {
        widget.notifier.slide(d);
      }
    }

    if (absX > absY * axisRatio) {
      if (useVelocity) {
        if (dx < -velAxis) {
          trySlide(SlideDirection.left);
        } else if (dx > velAxis) {
          trySlide(SlideDirection.right);
        }
      } else {
        if (dx < -distAxis) {
          trySlide(SlideDirection.left);
        } else if (dx > distAxis) {
          trySlide(SlideDirection.right);
        }
      }
    } else if (absY > absX * axisRatio) {
      if (useVelocity) {
        if (dy < -velAxis) {
          trySlide(SlideDirection.up);
        } else if (dy > velAxis) {
          trySlide(SlideDirection.down);
        }
      } else {
        if (dy < -distAxis) {
          trySlide(SlideDirection.up);
        } else if (dy > distAxis) {
          trySlide(SlideDirection.down);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSlide = _canSlide;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: canSlide
          ? (_) {
              _panDelta = Offset.zero;
            }
          : null,
      onPanUpdate: canSlide
          ? (details) {
              _panDelta += details.delta;
            }
          : null,
      onPanEnd: canSlide ? _onPanEnd : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const boardCells = 8;
                const minCellSize = 8.0;
                // 盤面は左右の余白のみ（GameBoard 内パディング 8*2 に合わせて控えめに）
                const horizontalMargin = 8.0;
                const verticalMargin = 4.0;
                /// 狭い画面では縦方向の余白を減らし、盤面を大きく見せる
                const boardVerticalAlign = 0.0;
                final availableH =
                    (constraints.maxHeight - verticalMargin * 2).clamp(0.0, double.infinity);
                final availableW =
                    (constraints.maxWidth - horizontalMargin * 2).clamp(0.0, double.infinity);
                final maxCellFromH = availableH / boardCells;
                final maxCellFromW = availableW / boardCells;
                // 横幅いっぱいに近づける（高さが足りないときだけ縮小）。超大画面では上限を付与。
                final cellSize = (maxCellFromH < maxCellFromW ? maxCellFromH : maxCellFromW)
                    .clamp(minCellSize, 88.0);

                return Align(
                  alignment: const Alignment(0, boardVerticalAlign),
                  child: GameBoard(
                    board: widget.gameState.board,
                    blocks: widget.gameState.blocks,
                    cellSize: cellSize,
                    clearingCells: widget.gameState.clearingCells,
                    clearingTriggerRows: widget.gameState.clearingTriggerRows,
                    clearingTriggerCols: widget.gameState.clearingTriggerCols,
                    slideAnimations: widget.gameState.slideAnimations,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          DirectionButtons(
            onDirection: (dir) => widget.notifier.slide(dir),
            nextBlockPerDirection: widget.gameState.nextBlockPerDirection,
            nextBlockColorPerDirection: widget.gameState.nextBlockColorPerDirection,
            enabled: canSlide,
            isDirectionEnabled: (dir) => widget.notifier.canSlideDirection(dir),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final int linesCleared;
  final VoidCallback onRestart;

  const _GameOverOverlay({
    required this.score,
    required this.linesCleared,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game Over',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text('Score: $score'),
            Text('Lines cleared: $linesCleared'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onRestart,
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
