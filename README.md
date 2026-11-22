# Rickroll Watcher for macOS

指定したフォルダを Finder で開いた瞬間、ウィンドウを自動的に閉じてボーダーレス全画面で動画を再生する macOS 向けジョーク／監視ツールです。

標準の「フォルダアクション（`on opening folder window`）」が動作しない近年の macOS 環境でも確実に動作するよう、軽量な常駐監視プロセスと Swift 製の専用全画面プレイヤーを組み合わせています。

## 主な特徴

- **管理者権限（パスワード）不要のインストール**
  `~/Applications`（ログインユーザー専用領域）にインストールされる `.pkg` を生成するため、管理者パスワードなしで導入・アンインストールが可能です。
- **完全ステルス常駐**
  `LSUIElement` により Dock や `Command + Tab` 一覧にアイコンを表示せずバックグラウンドで静かに待機します。
- **UIなしのシームレスな全画面演出**
  QuickTime Player を使わず Swift（`AVFoundation`）製の独自プレイヤーを採用。再生バーやマウスカーソルを一切表示せず、画面下端から滑らかにせり上がって全画面化します。
- **管理・設定用ユーティリティを同梱**
  インストール時に以下の4つのアプリが `~/Applications` に配置されます。
  - **`rickroll.app`**：バックグラウンド監視本体（インストール直後に自動起動）
  - **`Configure.app`**：設定ファイル（`config.json`）の編集と即時リロード
  - **`StopWatcher.app`**：監視プロセスと再生中プレイヤーの一時停止
  - **`UninstallWatcher.app`**：アプリ本体・設定ファイル・インストール履歴の完全削除

---

## 使い方（インストール後）

1. **初回許可の承認**
   インストール完了後、初回のみ「"rickroll" が "Finder" の制御を求めています」というダイアログが表示されるので **「OK」** を押してください。
2. **トリガーの発動**
   設定された監視対象フォルダ（デフォルト：`~/Desktop/名称未設定フォルダ 3`）を Finder で開くと、即座にフォルダが閉じて再生が始まります。
3. **再生の解除**
   再生中に **`Shift + Esc`** キーを押すとプレイヤーが終了します（通常の `Esc` キー単体では閉じません）。
4. **監視対象や設定の変更**
   `~/Applications/Configure.app` を起動すると `config.json` が開きます。編集・保存（`Command + S`）したあと、ダイアログの **「Reload」** を押すと再署名なしで即座に反映されます。

### `config.json` の設定項目

設定ファイルは `~/Library/Application Support/RickrollWatcher/config.json` に保存されます。

```json
{
  "targetFolder": "~/Desktop/名称未設定フォルダ 3",
  "videoName": "rickroll.mp4",
  "interval": 0.5
}
```

- `targetFolder`：監視するフォルダのパス（`~/` によるホームディレクトリ指定に対応）
- `videoName`：アプリ内の `Resources` に同梱された動画ファイル名
- `interval`：Finder ウィンドウの監視間隔（秒）

---

## ビルド方法（開発者向け）

### 必要環境
- macOS（Apple Silicon / Intel）
- Xcode Command Line Tools（`swiftc` / `codesign` / `pkgbuild` / `productbuild`）
- `yt-dlp`（動画を自動ダウンロードする場合：`brew install yt-dlp`）

### ビルド手順

1. リポジトリをクローンします。
   ```bash
   git clone https://github.com
   cd リポジトリ名
   ```
2. ビルドスクリプトを実行します（VS Code の場合は `Command + Shift + B` でも実行できます）。
   ```bash
   zsh build.sh
   ```
   - ローカルに `rickroll.mp4` がない場合は `yt-dlp` 経由で自動取得されます（事前に `rickroll.mp4` をプロジェクト直下に置いておけばそちらを優先します）。
   - 完了するとプロジェクト直下に **`RickrollInstaller-v1.1.0.pkg`** が生成されます。

## 注意事項

- 本ツールはジョーク・学習目的で作成されています。他者の端末や組織の管理端末で使用する場合は、必ず相手の許可を得た上でマナーの範囲内でご使用ください。
- Apple Developer ID による公証（Notarization）を行っていない `.pkg` を別の Mac で開く場合は、ダブルクリックではなく **「右クリック（Control + クリック）＞ 開く」** からインストーラーを起動してください。
