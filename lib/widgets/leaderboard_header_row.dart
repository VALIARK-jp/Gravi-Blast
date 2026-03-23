import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// 中央に現在スコア、その左に Best score、右に Today's best score（ニックネーム＋点数）。
class LeaderboardScoreHeader extends ConsumerWidget {
  const LeaderboardScoreHeader({
    super.key,
    required this.currentScore,
    required this.linesCleared,
  });

  final int currentScore;
  final int linesCleared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTimeLeaderboardProvider);
    final dailyAsync = ref.watch(todayDailyLeaderboardProvider);
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.black54,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final nameStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );
    final bestScoreStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 12, left: 12, right: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _SideBestPanel(
              title: 'Best score',
              asyncValue: allAsync,
              titleStyle: titleStyle,
              nameStyle: nameStyle,
              scoreStyle: bestScoreStyle,
              alignEnd: false,
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentScore',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lines: $linesCleared',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: _SideBestPanel(
              title: "Today's best score",
              asyncValue: dailyAsync,
              titleStyle: titleStyle,
              nameStyle: nameStyle,
              scoreStyle: bestScoreStyle,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBestPanel extends StatelessWidget {
  const _SideBestPanel({
    required this.title,
    required this.asyncValue,
    required this.titleStyle,
    required this.nameStyle,
    required this.scoreStyle,
    required this.alignEnd,
  });

  final String title;
  final AsyncValue<LeaderboardEntry?> asyncValue;
  final TextStyle? titleStyle;
  final TextStyle? nameStyle;
  final TextStyle? scoreStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle, textAlign: textAlign),
        const SizedBox(height: 6),
        asyncValue.when(
          data: (e) {
            if (e == null) {
              return Column(
                crossAxisAlignment: cross,
                children: [
                  Text('—', style: nameStyle, textAlign: textAlign),
                  Text('—', style: scoreStyle, textAlign: textAlign),
                ],
              );
            }
            return Column(
              crossAxisAlignment: cross,
              children: [
                Text(
                  e.nickname,
                  style: nameStyle,
                  textAlign: textAlign,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.score}',
                  style: scoreStyle,
                  textAlign: textAlign,
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: cross,
            children: [
              Text('…', style: nameStyle, textAlign: textAlign),
              Text('…', style: scoreStyle, textAlign: textAlign),
            ],
          ),
          error: (_, __) => Column(
            crossAxisAlignment: cross,
            children: [
              Text('—', style: nameStyle, textAlign: textAlign),
              Text('—', style: scoreStyle, textAlign: textAlign),
            ],
          ),
        ),
      ],
    );
  }
}
