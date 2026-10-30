# KeepInput

既定の README: [简体中文](README.md)

他の言語: [English](README.en.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | 日本語

InputLock は、現在の入力方式を固定する軽量な macOS メニューバーアプリです。文章作成、開発作業、アプリ間の移動中に入力方式が誤って切り替わることを減らします。

## 機能

- 現在の入力方式を固定し、別の入力ソースに切り替わった場合は自動的に戻す
- 選択した入力方式へ一時的に切り替え、入力が止まると固定した入力方式へ戻す。待ち時間は 1〜60 秒、既定は 5 秒
- 通常の単独キー、ファンクションキー、Globe、Caps Lock、Shift、Option、Control、Command とその組み合わせに対応
- メニューバーパネル、コンテキストメニュー、または `Command + ,` から設定ウィンドウを開けます
- メニューバーのアイコンを非表示にでき、アプリを再度起動すると設定が開く
- 左クリックで入力ソース一覧を開き、右クリックでクイック操作を開く
- English、简体中文、Français、Deutsch、日本語に対応
- ログイン時の起動はシステムの実際の状態を表示し、前回の固定状態を復元可能
- パスワードのセキュア入力中は固定を一時停止
- GitHub Releases の更新を確認し、ダウンロード後に再起動してインストール

## 必要環境

- macOS 12.0 Monterey 以降
- ログイン時に起動する機能は macOS 13.0 以降が必要です

## インストール

GitHub Releases からのインストールを推奨します。

1. [Releases](https://github.com/trah01/keepinput/releases) ページを開きます。
2. 最新の `InputLock-1.3.dmg` をダウンロードします。
3. DMG を開き、`lockinput.app` を `Applications` にドラッグします。
4. `Applications` から InputLock を起動します。

現在のリリースは Apple の公証を受けていません。初回起動時に macOS によりブロックされた場合は、システム設定 > プライバシーとセキュリティで許可するか、Control キーを押しながらアプリをクリックして「開く」を選択してください。

## 使い方

- メニューバーのロックアイコンを左クリック: メインパネルを開く
- メニューバーのロックアイコンを右クリック: クイック操作メニューを開く
- 一覧内の入力方式をクリック: 解除中は直接切り替え、固定中は一時的に切り替える
- 固定 / 解除ボタン: 現在の入力ソースを固定、または固定を解除
- メインパネル下部の設定、または `Command + ,` で設定ウィンドウを開きます
- 設定でショートカット、切り替え先、待ち時間を指定します。再度押すとすぐに固定した入力方式へ戻ります
- 通常のキーは押すと記録し、修飾キーのみの組み合わせは離すと保存します。再度クリックでキャンセル、× で消去できます。Escape と Delete も記録できます
- 必要に応じてアクセシビリティを許可してください。macOS が予約した組み合わせはシステムの操作も実行する場合があります
- 設定でメニューバーのアイコンを隠せます。アプリを再度起動すると設定を開けます
- 「このアプリについて」で更新を確認し、ダウンロードして再起動するとインストールします
- 設定でインターフェイス言語を変更
- ログイン時に起動を有効化: macOS 13.0 以降でログイン後に自動起動
- 再起動後に前回のロックを復元を有効化: 次回起動時に前回固定した入力方式を復元

## ソースから実行

```bash
git clone https://github.com/trah01/keepinput.git
cd keepinput
open lockinput.xcodeproj
```

Xcode で `lockinput` scheme を選択して実行します。

## リリースパッケージのビルド

`xcodebuild` が Command Line Tools を指している場合は、完全版の Xcode に切り替えます。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Release app をビルドします。

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

DMG を作成します。

```bash
./scripts/create-dmg.sh
```

生成されるファイル:

```text
InputLock-1.3.dmg
```

## 自動ビルドとリリース

[.github/workflows/release.yml](.github/workflows/release.yml) は `v1.3`、`v1.3.1` などのタグを push すると実行されます。Actions → Build and Release → Run workflow から手動実行も可能で、バージョン番号は `v` の有無を問いません。既存のタグは選択したコードと一致する必要があります。

Apple Silicon と Intel 対応のユニバーサルアプリをビルドし、ad-hoc 署名を行い、`InputLock-<バージョン>.dmg` と `.sha256` を GitHub Releases に公開します。アプリのバージョンはタグから `v` を除いた値となり、手動実行では必要に応じてタグを作成します。Apple の証明書は不要で、公証は行いません。

## プロジェクト構成

```text
lockinput/
├── lockinputApp.swift        # アプリのエントリーポイントとメニューバー設定
├── ContentView.swift         # メインパネル UI
├── SettingsView.swift        # 設定ウィンドウ UI
├── InputMethodManager.swift  # 入力ソースの検出、切り替え、固定処理
├── InputSourceLockState.swift # 固定状態モデル
├── LanguageManager.swift     # 実行時の言語切り替え
├── Info.plist                # アプリのメタデータ
├── Assets.xcassets/          # アイコンとアセット
└── Resources/
    ├── en.lproj/             # 英語
    ├── zh-Hans.lproj/        # 簡体字中国語
    ├── fr.lproj/             # フランス語
    ├── de.lproj/             # ドイツ語
    └── ja.lproj/             # 日本語
```

## ローカライズ

言語を追加する手順:

1. `lockinput/Resources/` に新しい `.lproj` フォルダを作成します。
2. 既存の `Localizable.strings` をコピーして翻訳します。
3. `lockinput.xcodeproj/project.pbxproj` の `knownRegions` に言語コードを追加します。
4. `LanguageManager.swift` の `AppLanguage` enum に言語を追加します。

## ライセンス

このリポジトリには現在、個別の `LICENSE` ファイルは含まれていません。
