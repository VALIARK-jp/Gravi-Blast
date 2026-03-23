import 'package:flutter/material.dart';

import '../models/game_state.dart';

class DirectionButtons extends StatelessWidget {
  final void Function(SlideDirection) onDirection;
  final bool enabled;
  final bool Function(SlideDirection)? isDirectionEnabled;

  const DirectionButtons({
    super.key,
    required this.onDirection,
    this.enabled = true,
    this.isDirectionEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            null,
            _buildButton(Icons.arrow_upward, SlideDirection.up),
            null,
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildButton(Icons.arrow_back, SlideDirection.left),
            null,
            _buildButton(Icons.arrow_forward, SlideDirection.right),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            null,
            _buildButton(Icons.arrow_downward, SlideDirection.down),
            null,
          ]),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget?> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map((w) => w ?? const SizedBox(width: 56, height: 56))
          .toList(),
    );
  }

  Widget _buildButton(IconData icon, SlideDirection direction) {
    final directionOk = isDirectionEnabled?.call(direction) ?? true;
    final canTap = enabled && directionOk;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: canTap ? Colors.deepPurple : Colors.grey,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          onTap: canTap ? () => onDirection(direction) : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
