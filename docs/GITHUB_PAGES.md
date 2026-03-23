# GitHub Pages で Web 版を公開（git / GitHub Actions）

## 画面に「Upgrade or make this repository public」と出るとき

**無料の GitHub Pages** は、**パブリックリポジトリ**で使うのが一般的です。

1. リポジトリ **Settings** → **General** → 一番下 **Danger Zone** → **Change repository visibility** → **Public**  
   （組織の方針で公開できない場合は、**Firebase Hosting** など別ホスティングを検討）

## Pages のソースを「GitHub Actions」にする

1. **Settings** → **Pages**
2. **Build and deployment** の **Source** で **GitHub Actions** を選ぶ  
   （「Deploy from a branch」ではなく **Actions**）

## 初回デプロイ

- `main` に push すると `.github/workflows/deploy-web.yml` が動き、`build/web` が公開されます。
- 完了後、サイト URL はだいたい次の形です（組織・リポジトリ名はそのまま）:

  `https://valiark-jp.github.io/Gravi-Blast/`

## base-href

プロジェクトページはサブパス `/Gravi-Blast/` になるため、ワークフローでは次を指定しています。

```bash
flutter build web --release --base-href "/Gravi-Blast/"
```

リポジトリ名を変えたら、この文字列とワークフロー内の `--base-href` を合わせてください。

## 手元でビルドだけ試す

```bash
flutter build web --release --base-href "/Gravi-Blast/"
```

`build/web` をローカルサーバーで開いて動作確認できます。
