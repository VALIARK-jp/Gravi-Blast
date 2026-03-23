import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/direction_buttons.dart';
import '../widgets/game_board.dart';

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

    if (gameState.phase == GamePhase.gameOver) {
      return Scaffold(
        body: Column(
          children: [
            _ScoreHeader(score: gameState.score),
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
      appBar: AppBar(
        title: const Text('GraviBlast'),
      ),
      body: Column(
        children: [
          _ScoreHeader(score: gameState.score),
          Expanded(
            child: _GameBody(notifier: notifier, gameState: gameState),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;

  const _ScoreHeader({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'POINTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                Shadow(color: Colors.white24, offset: Offset(-1, -1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  final dynamic notifier;
  final GameState gameState;

  const _GameBody({
    required this.notifier,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final canSlide = gameState.clearingCells.isEmpty && gameState.slideAnimations.isEmpty;
    return GestureDetector(
      onVerticalDragEnd: canSlide
          ? (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100 && notifier.canSlideDirection(SlideDirection.up)) {
                notifier.slide(SlideDirection.up);
              } else if (details.primaryVelocity! > 100 && notifier.canSlideDirection(SlideDirection.down)) {
                notifier.slide(SlideDirection.down);
              }
            }
          : null,
      onHorizontalDragEnd: canSlide
          ? (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100 && notifier.canSlideDirection(SlideDirection.left)) {
                notifier.slide(SlideDirection.left);
              } else if (details.primaryVelocity! > 100 && notifier.canSlideDirection(SlideDirection.right)) {
                notifier.slide(SlideDirection.right);
              }
            }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const boardCells = 8;
                const minCellSize = 8.0;
                const boardPadding = 16.0; // GameBoard padding (8*2)
                final availableH = (constraints.maxHeight - boardPadding).clamp(0.0, double.infinity);
                final availableW = (constraints.maxWidth - boardPadding).clamp(0.0, double.infinity);
                final maxCellFromH = availableH / boardCells;
                final maxCellFromW = availableW / boardCells;
                final cellSize = (maxCellFromH < maxCellFromW ? maxCellFromH : maxCellFromW)
                    .clamp(minCellSize, 36.0);

                return Center(
                  child: GameBoard(
                    board: gameState.board,
                    blocks: gameState.blocks,
                    cellSize: cellSize,
                    clearingCells: gameState.clearingCells,
                    clearingTriggerRows: gameState.clearingTriggerRows,
                    clearingTriggerCols: gameState.clearingTriggerCols,
                    slideAnimations: gameState.slideAnimations,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lines: ${gameState.linesCleared}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          DirectionButtons(
            onDirection: (dir) => notifier.slide(dir),
            nextBlockPerDirection: gameState.nextBlockPerDirection,
            enabled: canSlide,
            isDirectionEnabled: (dir) => notifier.canSlideDirection(dir),
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
