# 残りの手動作業

チュートリアル機能の実装が完了しました。以下の手動作業を行ってください。

## 必須作業

### 1. アプリアイコンの配置

提供された緑色のアイコン画像を配置してください。

#### 手順：
1. 提供された画像を開く
2. 画像を **1024x1024ピクセル** のPNG形式で保存
3. ファイル名を `miterundesu_app_icon_1024.png` に変更
4. 以下のディレクトリに配置：
   ```
   miterundesu-ios/miterundesu/miterundesu/Assets.xcassets/AppIcon.appiconset/
   ```

#### 確認方法：
- Xcodeでプロジェクトを開く
- Assets.xcassetsを開く
- AppIconをクリック
- アイコンが表示されることを確認

## オプション作業（推奨）

### 2. SSCoachMarksパッケージのインストール

より高度なハイライト機能を使用する場合のみ必要です。現在の実装でも動作します。

#### 手順：
1. Xcodeでプロジェクトを開く
2. メニューバー: `File` → `Add Package Dependencies...`
3. 検索バーに以下のURLを入力：
   ```
   https://github.com/SimformSolutionsPvtLtd/SSCoachMarks.git
   ```
4. "Up to Next Major Version" から最新版（1.0.0以上）を選択
5. "Add Package" をクリック

#### インストール後の作業：
1. `FeatureHighlightView.swift` を開く
2. ファイル先頭の `// import SSCoachMarks` のコメントを解除
3. `FeatureHighlightView` のbody内のコメントアウトされたコードを有効化
4. `ContentView.swift` で `TemporaryFeatureHighlightView` を `FeatureHighlightView` に変更

**注意**: この作業は任意です。`TemporaryFeatureHighlightView` でも十分機能します。

## テスト方法

### 初回起動のテスト
1. Xcodeでビルド＆実行
2. アプリ起動後、ウェルカム画面が表示されることを確認
3. 「始める」ボタンをタップ
4. 機能ハイライト画面が表示されることを確認
5. 各ステップを進めて完了まで確認

### 設定画面からのテスト
1. アプリを再起動（2回目以降の起動）
2. 設定ボタンをタップ
3. 下にスクロールして「アプリ情報」セクションを表示
4. 「チュートリアルを見る」ボタンをタップ
5. 機能ハイライト画面が表示されることを確認

### チュートリアルリセット方法
初回起動時の動作を再確認したい場合：

1. アプリを削除
2. 再インストール

または：
```swift
// デバッグ用コード（OnboardingManagerに追加可能）
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
```

## トラブルシューティング

### ビルドエラーが発生する
- プロジェクトをクリーン: `Cmd + Shift + K`
- Derived Dataを削除
- Xcodeを再起動

### アイコンが表示されない
- ファイル名が正確に `miterundesu_app_icon_1024.png` であることを確認
- ファイルサイズが1024x1024ピクセルであることを確認
- PNG形式であることを確認
- Xcodeでアセットカタログを確認

### チュートリアルが表示されない
- アプリを完全に削除して再インストール
- UserDefaultsをリセット
- OnboardingManager.swift が正しくビルドされているか確認

## 実装済み機能

✅ OnboardingManager - 状態管理
✅ TutorialWelcomeView - ウェルカム画面
✅ FeatureHighlightView - 機能ハイライト（暫定版）
✅ LocalizationManager更新 - 日英対応
✅ ContentView統合 - 自動表示ロジック
✅ SettingsView統合 - 再表示ボタン
✅ AppIcon設定 - 構成完了

## 保留中の作業

🔲 アプリアイコン画像の配置（手動作業が必要）
⚪ SSCoachMarksインストール（オプション）

## 参考ドキュメント

- `TUTORIAL_IMPLEMENTATION_PLAN.md` - 技術的な実装計画
- `TUTORIAL_SETUP_INSTRUCTIONS.md` - 詳細なセットアップ手順とトラブルシューティング

## 完了したコミット

```
commit 8158f82
Author: Claude Code
Date: [現在の日時]

Add tutorial/onboarding feature with welcome screen and feature highlights
```

GitHubにプッシュ済みです。
