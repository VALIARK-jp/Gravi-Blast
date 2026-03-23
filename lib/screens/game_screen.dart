import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/direction_buttons.dart';
import '../widgets/game_board.dart';

class _SlideUp extends Intent {}
class _SlideDown extends Intent {}
class _SlideLeft extends Intent {}
class _SlideRight extends Intent {}

bool _canSlide(GameState s, SlideDirection dir) {
  if (s.phase != GamePhase.playing) return false;
  if (s.clearingCells.isNotEmpty || s.slideAnimations.isNotEmpty) return false;
  if (s.lastSlideDirection != dir) return true;
  return s.consecutiveSameDirectionCount < 2;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(gameProvider);
      if (state.phase == GamePhase.menu) {
        ref.read(gameProvider.notifier).startGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (gameState.phase == GamePhase.gameOver) {
      return _GameOverOverlay(
        score: gameState.score,
        linesCleared: gameState.linesCleared,
        onRestart: notifier.startGame,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GraviBlast'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Score: ${gameState.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        child: Shortcuts(
          shortcuts: {
            SingleActivator(LogicalKeyboardKey.arrowUp): _SlideUp(),
            SingleActivator(LogicalKeyboardKey.arrowDown): _SlideDown(),
            SingleActivator(LogicalKeyboardKey.arrowLeft): _SlideLeft(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _SlideRight(),
          },
          child: Actions(
            actions: {
              _SlideUp: CallbackAction<_SlideUp>(onInvoke: (_) {
                if (_canSlide(gameState, SlideDirection.up)) notifier.slide(SlideDirection.up);
                return null;
              }),
              _SlideDown: CallbackAction<_SlideDown>(onInvoke: (_) {
                if (_canSlide(gameState, SlideDirection.down)) notifier.slide(SlideDirection.down);
                return null;
              }),
              _SlideLeft: CallbackAction<_SlideLeft>(onInvoke: (_) {
                if (_canSlide(gameState, SlideDirection.left)) notifier.slide(SlideDirection.left);
                return null;
              }),
              _SlideRight: CallbackAction<_SlideRight>(onInvoke: (_) {
                if (_canSlide(gameState, SlideDirection.right)) notifier.slide(SlideDirection.right);
                return null;
              }),
            },
            child: SafeArea(
              child: _GameBody(notifier: notifier, gameState: gameState),
            ),
          ),
        ),
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

  bool _canSlideDirection(SlideDirection dir) {
    if (gameState.clearingCells.isNotEmpty || gameState.slideAnimations.isNotEmpty) {
      return false;
    }
    if (gameState.lastSlideDirection != dir) return true;
    return gameState.consecutiveSameDirectionCount < 2;
  }

  @override
  Widget build(BuildContext context) {
    final canSlide = gameState.clearingCells.isEmpty && gameState.slideAnimations.isEmpty;
    return GestureDetector(
      onVerticalDragEnd: canSlide
          ? (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100 && _canSlideDirection(SlideDirection.up)) {
                notifier.slide(SlideDirection.up);
              } else if (details.primaryVelocity! > 100 && _canSlideDirection(SlideDirection.down)) {
                notifier.slide(SlideDirection.down);
              }
            }
          : null,
      onHorizontalDragEnd: canSlide
          ? (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100 && _canSlideDirection(SlideDirection.left)) {
                notifier.slide(SlideDirection.left);
              } else if (details.primaryVelocity! > 100 && _canSlideDirection(SlideDirection.right)) {
                notifier.slide(SlideDirection.right);
              }
            }
          : null,
      child: LayoutBuilder(
          builder: (context, constraints) {
            const cellSize = 36.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: GameBoard(
                    board: gameState.board,
                    blocks: gameState.blocks,
                    cellSize: cellSize,
                    clearingCells: gameState.clearingCells,
                    clearingTriggerRows: gameState.clearingTriggerRows,
                    clearingTriggerCols: gameState.clearingTriggerCols,
                    slideAnimations: gameState.slideAnimations,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lines: ${gameState.linesCleared}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                DirectionButtons(
                  onDirection: (dir) => notifier.slide(dir),
                  enabled: canSlide,
                  isDirectionEnabled: (dir) {
                    if (gameState.lastSlideDirection != dir) return true;
                    return gameState.consecutiveSameDirectionCount < 2;
                  },
                ),
              ],
            );
          },
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
    return Scaffold(
      body: Center(
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
      ),
    );
  }
}
