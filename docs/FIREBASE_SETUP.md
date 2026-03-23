# Firebase 連携（GraviBlast）

プロジェクトには **プレースホルダー** の設定（`graviblast-placeholder`）が入っています。  
実際の Firebase プロジェクトに接続するには、**自分のマシン**で次を実行してください。

## 1. 事前準備

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

`flutterfire` が見つからない場合は、`~/.pub-cache/bin` を PATH に追加します。

## 2. ログイン

```bash
firebase login
```

認証エラーが出たら `firebase login --reauth` を試してください。

## 3. Flutter アプリと Firebase を紐付け（重要）

**現在の Firebase プロジェクト（例）**

| 項目 | 値 |
|------|-----|
| 表示名 | GraviBlast |
| **プロジェクト ID** | `graviblast-6723f` ← `flutterfire` はこれを使う |
| プロジェクト番号 | `775681177017`（GCP 側の番号。コードでは通常不要） |

プロジェクトルート（`pubspec.yaml` がある場所）で:

```bash
cd /path/to/GraviBlast
flutterfire configure \
  --project=graviblast-6723f \
  -y \
  --platforms=android,ios,web
```

Chrome で `flutter run -d chrome` する場合は **Web** 用アプリ登録と `firebase_options.dart` の `web` が必要です。未登録ならコンソールで Web アプリを追加するか、上記に `web` を含めて再実行してください。

別の Firebase プロジェクトに切り替えるときだけ `--project=` を差し替えてください。

これで次が **本物の値で上書き**されます。

| 生成・更新されるもの |
|----------------------|
| `lib/firebase_options.dart` |
| `android/app/google-services.json` |
| `ios/Runner/GoogleService-Info.plist` |

既にプレースホルダーがある場合も、`flutterfire configure` で問題なく置き換わります。

## 4. iOS の Pod（初回または依存変更後）

```bash
cd ios && pod install && cd ..
```

## 5. コンソール側

- [Firestore](https://console.firebase.google.com/) を有効化（ランキング用）
- **セキュリティルール**: デフォルトでは読み書きできません。**「ランキングの取得に失敗」** `permission-denied` になる場合は、**[docs/FIRESTORE_RULES.md](FIRESTORE_RULES.md)** の手順で `leaderboard` を許可してください。リポジトリ直下の `firestore.rules` をコピーしてコンソールに貼れる開発用例もあります。
- 本番前に必ずルールを厳しくする（開発用の「全許可」は本番では使わない）

### データ構造（アプリ側で定義）

Firestore のフィールド名・型・ニックネームの整形は **`lib/data/leaderboard_mapper.dart`** に集約しています。

| コレクション | ドキュメント ID | フィールド |
|-------------|-----------------|------------|
| `leaderboard` | `all_time` | `score` (int), `nickname` (string), `updatedAt` (timestamp) |
| `leaderboard` | `daily_YYYY-MM-DD`（JST） | 同上 |
| `leaderboard_history` | （自動 ID） | 通算／日次の **ベストが更新されたとき**に 1 件追加。`kind` (`all_time` / `daily`), `score`, `nickname`, `createdAt`, 日次のみ `jstDateKey` |

読み取りは `LeaderboardRepository`、Riverpod は `allTimeLeaderboardProvider` / `todayDailyLeaderboardProvider` を参照。履歴は現状 **書き込みのみ**（一覧 UI は未実装）。

**ルール**で `leaderboard_history` も許可する必要があります（`firestore.rules` 参照）。

## パッケージ ID

- **Android** `applicationId`: `com.graviblast.graviblast`
- **iOS** Bundle ID: `com.graviblast.graviblast`

Firebase コンソールにアプリを追加するときは上記と一致させてください。
