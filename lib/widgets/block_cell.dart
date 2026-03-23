import 'package:flutter/material.dart';

class BlockCell extends StatelessWidget {
  final double size;
  final Color color;

  const BlockCell({
    super.key,
    required this.size,
    this.color = Colors.deepPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
