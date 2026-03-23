import 'package:flutter_test/flutter_test.dart';

import 'package:graviblast/logic/slide_engine.dart';
import 'package:graviblast/models/block.dart';
import 'package:graviblast/models/game_state.dart';

void main() {
  group('SlideEngine', () {
    late SlideEngine engine;

    setUp(() {
      engine = SlideEngine(boardWidth: 4, boardHeight: 4);
    });

    test('L-shape moves as rigid body to the right', () {
      // L at (0,0): cells (0,0),(0,1),(0,2),(1,2)
      final l = Block(
        blockId: 'l',
        shape: BlockShape.lShape,
        col: 0,
        row: 0,
      );
      final result = engine.slide([l], SlideDirection.right);
      expect(result.length, 1);
      // Should slide until right edge: maxCol 3, so col can go to 2 (cells at 2,3)
      expect(result[0].col, 2);
      expect(result[0].row, 0);
      expect(result[0].shape, BlockShape.lShape);
      // Verify shape preserved
      final cells = result[0].occupiedCells;
      expect(cells, contains((2, 0)));
      expect(cells, contains((2, 1)));
      expect(cells, contains((2, 2)));
      expect(cells, contains((3, 2)));
    });

    test('L-shape hits another block and stops', () {
      final l = Block(
        blockId: 'l',
        shape: BlockShape.lShape,
        col: 0,
        row: 0,
      );
      // vertical2 at (3,2) blocks L's path at col 2, so L stops at col 1
      final obstacle = Block(
        blockId: 'o',
        shape: BlockShape.vertical2,
        col: 3,
        row: 2,
      );
      final result = engine.slide([l, obstacle], SlideDirection.right);
      expect(result.length, 2);
      final lResult = result.firstWhere((b) => b.blockId == 'l');
      expect(lResult.col, 1);
    });

    test('slideNewBlock - spawned block hits obstacle and stops', () {
      final obstacle = Block(
        blockId: 'o',
        shape: BlockShape.vertical2,
        col: 2,
        row: 2,
      );
      final newBlock = Block(
        blockId: 'new',
        shape: BlockShape.horizontal2,
        col: -1,
        row: 2,
      );
      final settled = engine.slideNewBlock(newBlock, [obstacle], SlideDirection.right);
      expect(settled.col, 0);
      expect(settled.row, 2);
    });
  });
}
