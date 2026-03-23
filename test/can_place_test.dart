import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:graviblast/logic/line_clear.dart';
import 'package:graviblast/logic/slide_engine.dart';
import 'package:graviblast/logic/spawner.dart';
import 'package:graviblast/models/block.dart';
import 'package:graviblast/models/game_state.dart';

void main() {
  const boardWidth = 8;
  const boardHeight = 8;

  late SlideEngine slideEngine;
  late LineClear lineClear;
  late Spawner spawner;

  setUp(() {
    slideEngine = SlideEngine(boardWidth: boardWidth, boardHeight: boardHeight);
    lineClear = LineClear(boardWidth: boardWidth, boardHeight: boardHeight);
    spawner = Spawner(
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      random: Random(42),
    );
  });

  bool blockCanBePlaced(Block block, List<Block> existingBlocks) {
    final occupied = <(int, int)>{};
    for (final b in existingBlocks) {
      for (final cell in b.occupiedCells) {
        if (cell.$1 >= 0 &&
            cell.$1 < boardWidth &&
            cell.$2 >= 0 &&
            cell.$2 < boardHeight) {
          occupied.add(cell);
        }
      }
    }
    for (final (c, r) in block.occupiedCells) {
      if (c < 0 || c >= boardWidth || r < 0 || r >= boardHeight) {
        return false;
      }
      if (occupied.contains((c, r))) return false;
    }
    return true;
  }

  bool canSpawnFromDirection(
    BlockShape shape,
    SlideDirection direction,
    List<Block> blocks,
  ) {
    var blocksAfterSlide = slideEngine.slide(blocks, direction);
    while (true) {
      final clearResult = lineClear.clear(blocksAfterSlide);
      if (clearResult.linesCleared == 0) break;
      blocksAfterSlide = clearResult.blocks;
    }
    return spawner.trySpawnShapeAtEdge(
          shape,
          direction,
          (b) => slideEngine.slideNewBlock(b, blocksAfterSlide, direction),
          (b) => blockCanBePlaced(b, blocksAfterSlide),
        ) !=
        null;
  }

  test('horizontal4 in middle: all 4 directions should be placeable', () {
    final h4 = Block(
      blockId: 'h4',
      shape: BlockShape.horizontal4,
      col: 2,
      row: 4,
    );
    final blocks = [h4];

    expect(
      canSpawnFromDirection(BlockShape.horizontal4, SlideDirection.up, blocks),
      true,
      reason: 'Up (4x1) should be placeable',
    );
    expect(
      canSpawnFromDirection(BlockShape.vertical3, SlideDirection.down, blocks),
      true,
      reason: 'Down (1x3) should be placeable',
    );
    expect(
      canSpawnFromDirection(BlockShape.lShape, SlideDirection.left, blocks),
      true,
      reason: 'Left (L-shape) should be placeable',
    );
    expect(
      canSpawnFromDirection(BlockShape.tShape, SlideDirection.right, blocks),
      true,
      reason: 'Right (T-shape) should be placeable',
    );
  });
}
