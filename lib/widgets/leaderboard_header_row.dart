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
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 520;
    final topPad = compact ? 28.0 : 48.0;
    final scoreFont = compact ? 30.0 : 48.0;
    final scoreDigits = currentScore.abs().toString().length;
    // 桁が増えるほど字間を詰め、はみ出しを防ぐ
    final scoreLetterSpacing = scoreDigits >= 6
        ? 0.0
        : scoreDigits >= 5
            ? 0.5
            : (compact ? 1.0 : 2.0);

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.black54,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      fontSize: compact ? 9 : null,
    );
    final nameStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w500,
      fontSize: compact ? 10 : null,
    );
    final bestScoreStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 12 : null,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + topPad,
        bottom: compact ? 8 : 12,
        left: compact ? 6 : 12,
        right: compact ? 6 : 12,
      ),
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
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      '$currentScore',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: scoreFont,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: scoreLetterSpacing,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  'Lines: $linesCleared',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: compact ? 13 : null,
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
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      '${e.score}',
                      maxLines: 1,
                      style: scoreStyle?.copyWith(
                        letterSpacing: '${e.score}'.length >= 5 ? 0.0 : 0.3,
                      ),
                      textAlign: textAlign,
                    ),
                  ),
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
