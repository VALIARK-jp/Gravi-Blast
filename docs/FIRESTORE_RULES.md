# Firestore セキュリティルール（ランキング）

「ランキングの取得に失敗しました」や **`permission-denied`** が出るときは、**ルールが読み取り／書き込みを拒否している**ことがほとんどです。

## 手順

1. [Firebase Console](https://console.firebase.google.com/) → プロジェクトを開く  
2. 左メニュー **Firestore Database** → **ルール** タブ  
3. 下の例を参考に編集 → **公開**

## 開発用（誰でも読み書き可）— まず動作確認したいとき

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{docId} {
      allow read, write: if true;
    }
    match /leaderboard_history/{docId} {
      allow read, write: if true;
    }
  }
}
```

**本番では使わないでください。** 不正スコア対策・認証連携など、別ルールに差し替えが必要です。

## 本番向けの例（認証ユーザーだけ書き込み）

将来的に Firebase Authentication を入れる場合のイメージです。

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{docId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /leaderboard_history/{docId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

現在のアプリは **未ログイン**で書き込むため、上記だと書き込めません。認証を入れるまでの間は開発用ルールか、別の条件（スコア上限・レート制限は Cloud Functions 側）を検討してください。

## データベース未作成

Firestore をまだ「作成」していないと、取得もできません。**Firestore Database** でデータベースを作成済みか確認してください。
