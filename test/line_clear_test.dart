import 'package:flutter_test/flutter_test.dart';

import 'package:graviblast/logic/line_clear.dart';
import 'package:graviblast/models/block.dart';

void main() {
  group('LineClear', () {
    late LineClear lineClear;

    setUp(() {
      lineClear = LineClear(boardWidth: 4, boardHeight: 4);
    });

    test('clears a full row', () {
      // horizontal4 at (0,0) fills row 0
      final blocks = [
        Block(blockId: 'a', shape: BlockShape.horizontal4, col: 0, row: 0),
      ];
      final result = lineClear.clear(blocks);
      expect(result.linesCleared, 1);
      expect(result.blocks, isEmpty);
    });

    test('clears a full column', () {
      final blocks = [
        Block(blockId: 'a', shape: BlockShape.vertical4, col: 2, row: 0),
      ];
      final result = lineClear.clear(blocks);
      expect(result.linesCleared, 1);
      expect(result.blocks, isEmpty);
    });

    test('does not clear partial row', () {
      final blocks = [
        Block(blockId: 'a', shape: BlockShape.horizontal2, col: 0, row: 0),
      ];
      final result = lineClear.clear(blocks);
      expect(result.linesCleared, 0);
      expect(result.blocks.length, 1);
    });

    test('clears row with multi-cell block', () {
      // horizontal3 at (0,0) + horizontal2 at (2,0) = row 0 full for 4-wide
      final blocks = [
        Block(blockId: 'a', shape: BlockShape.horizontal3, col: 0, row: 0),
        Block(blockId: 'b', shape: BlockShape.horizontal2, col: 2, row: 0),
      ];
      final result = lineClear.clear(blocks);
      expect(result.linesCleared, 1);
      expect(result.blocks, isEmpty);
    });

    test('8x8 board - full row clears', () {
      final bigClear = LineClear(boardWidth: 8, boardHeight: 8);
      final blocks = [
        Block(blockId: 'a', shape: BlockShape.horizontal3, col: 0, row: 0),
        Block(blockId: 'b', shape: BlockShape.horizontal3, col: 3, row: 0),
        Block(blockId: 'c', shape: BlockShape.horizontal2, col: 6, row: 0),
      ];
      final result = bigClear.clear(blocks);
      expect(result.linesCleared, 1);
      expect(result.blocks, isEmpty);
    });
  });
}
