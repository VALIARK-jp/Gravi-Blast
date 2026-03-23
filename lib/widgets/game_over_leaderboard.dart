import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leaderboard_mapper.dart';
import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';
import '../utils/jst_date.dart';

String _leaderboardErrorMessage(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore のルールで読み取りが拒否されています（permission-denied）。'
            'Firebase コンソール → Firestore → ルールで leaderboard を許可してください（docs/FIRESTORE_RULES.md 参照）。';
      case 'unavailable':
        return 'ネットワークの都合でランキングを取得できませんでした。';
      case 'failed-precondition':
        return 'Firestore が利用できません。データベース作成済みか確認してください。';
      default:
        return 'ランキングの取得に失敗しました（${e.code}）';
    }
  }
  return 'ランキングの取得に失敗しました: $e';
}

String _leaderboardWriteErrorMessage(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore のルールで書き込みが拒否されています。ルールで leaderboard の書き込みを許可してください。';
      default:
        return '送信に失敗しました（${e.code}）';
    }
  }
  return '送信に失敗しました: $e';
}

/// ゲームオーバー時、通算・今日の記録を更新できるならニックネーム入力を促し Firestore に送る。
Future<void> submitGameOverLeaderboardIfNeeded(
  BuildContext context,
  WidgetRef ref,
  int score,
) async {
  final repo = ref.read(leaderboardRepositoryProvider);
  LeaderboardEntry? all;
  LeaderboardEntry? daily;
  try {
    all = await repo.getAllTimeOnce();
    daily = await repo.getDailyOnce(jstDateKey());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Leaderboard get failed: $e\n$st');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_leaderboardErrorMessage(e)),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return;
  }

  final beatsAll = all == null || score > all.score;
  final beatsDaily = daily == null || score > daily.score;
  if (!beatsAll && !beatsDaily) return;
  if (!context.mounted) return;

  final nickname = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _NicknameRecordDialog(
      score: score,
      beatsAllTime: beatsAll,
      beatsToday: beatsDaily,
    ),
  );

  if (nickname == null) return;

  final sanitized = LeaderboardMapper.sanitizeNicknameForInput(nickname);
  if (sanitized.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームを入力してください')),
      );
    }
    return;
  }

  try {
    var wrote = false;
    if (beatsAll) {
      wrote = await repo.tryUpdateAllTimeIfBetter(score: score, nickname: sanitized) || wrote;
    }
    if (beatsDaily) {
      wrote = await repo.tryUpdateDailyIfBetter(
            jstDateKey: jstDateKey(),
            score: score,
            nickname: sanitized,
          ) ||
          wrote;
    }
    if (wrote && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ランキングを更新しました')),
      );
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Leaderboard write failed: $e\n$st');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_leaderboardWriteErrorMessage(e))),
      );
    }
  }
}

class _NicknameRecordDialog extends StatefulWidget {
  const _NicknameRecordDialog({
    required this.score,
    required this.beatsAllTime,
    required this.beatsToday,
  });

  final int score;
  final bool beatsAllTime;
  final bool beatsToday;

  @override
  State<_NicknameRecordDialog> createState() => _NicknameRecordDialogState();
}

class _NicknameRecordDialogState extends State<_NicknameRecordDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        '新記録！',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('スコア ${widget.score}'),
            const SizedBox(height: 8),
            if (widget.beatsAllTime) const Text('・通算ランキングを更新できます'),
            if (widget.beatsToday) const Text('・今日のランキングを更新できます'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: LeaderboardMapper.maxNicknameLength,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('スキップ'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('送信'),
        ),
      ],
    );
  }

  void _submit() {
    final raw = _controller.text;
    if (LeaderboardMapper.sanitizeNicknameForInput(raw).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームを入力してください')),
      );
      return;
    }
    Navigator.of(context).pop(raw);
  }
}
