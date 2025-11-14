# チュートリアル機能セットアップ手順

## 完了した実装

以下のファイルが作成・更新されました：

### 新規作成ファイル
1. `OnboardingManager.swift` - チュートリアル状態管理
2. `TutorialWelcomeView.swift` - ウェルカム画面
3. `FeatureHighlightView.swift` - 機能ハイライト画面（暫定版を含む）

### 更新ファイル
1. `LocalizationManager.swift` - チュートリアル用ローカライズ文字列を追加
2. `ContentView.swift` - OnboardingManager統合、チュートリアル表示ロジック追加
3. `SettingsView.swift` - チュートリアル再表示ボタン追加
4. `Assets.xcassets/AppIcon.appiconset/Contents.json` - アイコンファイル名指定

## 手動で行う必要がある作業

### 1. アプリアイコンの配置

提供された緑色のアイコン画像を以下の手順で配置してください：

1. 画像を1024x1024ピクセルのPNG形式で保存
2. ファイル名を `miterundesu_app_icon_1024.png` に変更
3. 以下のディレクトリに配置：
   ```
   miterundesu/Assets.xcassets/AppIcon.appiconset/miterundesu_app_icon_1024.png
   ```

### 2. Swift Package Managerでパッケージを追加

Xcodeで以下の2つのパッケージを追加してください：

#### 方法：
1. Xcodeでプロジェクトを開く
2. メニューバー: `File` → `Add Package Dependencies...`
3. 以下のURLを順番に入力して追加

#### パッケージ1: OnboardingKit (danielsaidi版)
- **URL**: `https://github.com/danielsaidi/OnboardingKit`
- **Version**: "Up to Next Major Version" から最新版を選択
- **Note**: 現在は暫定実装を使用しているため、必須ではありません

#### パッケージ2: SSCoachMarks
- **URL**: `https://github.com/SimformSolutionsPvtLtd/SSCoachMarks.git`
- **Version**: "Up to Next Major Version" から最新版 (1.0.0以上)
- **Note**: 機能ハイライトに必要。現在は暫定実装を使用

### 3. SSCoachMarksの有効化（オプション）

SSCoachMarksパッケージをインストールした後：

1. `FeatureHighlightView.swift`を開く
2. ファイル先頭の`// import SSCoachMarks`のコメントを解除
3. `FeatureHighlightView`のbody内のコメントアウトされたコードを有効化
4. `TemporaryFeatureHighlightView`から`FeatureHighlightView`に切り替え

**注意**: 現在は`TemporaryFeatureHighlightView`が動作します。SSCoachMarksは高度なハイライト機能が必要な場合のみ使用してください。

## 動作確認

### 初回起動時の動作
1. アプリを起動
2. ウェルカム画面が表示される
3. 「始める」ボタンをタップ
4. 機能ハイライト画面が表示される
5. 各ステップを進めて完了

### 設定画面からの呼び出し
1. アプリを起動（通常モード）
2. 設定ボタンをタップ
3. 「アプリ情報」セクションの「チュートリアルを見る」をタップ
4. 機能ハイライト画面が表示される

### チュートリアルリセット
UserDefaultsから`hasCompletedOnboarding`キーを削除すると、再び初回起動時の動作になります。

## トラブルシューティング

### ビルドエラーが発生する場合

#### エラー: "Cannot find 'SSCoachMarks' in scope"
- SSCoachMarksパッケージがインストールされていない
- `FeatureHighlightView.swift`のimport文がコメントアウトされている
- または`ContentView.swift`で`TemporaryFeatureHighlightView`を使用する

#### エラー: "Cannot find 'TutorialWelcomeView' in scope"
- ファイルがターゲットに追加されていない
- Xcodeでプロジェクトをクリーン (Cmd+Shift+K) してリビルド

#### エラー: アイコンが表示されない
- `miterundesu_app_icon_1024.png`が正しい場所に配置されているか確認
- Xcodeでアセットカタログを開いて確認
- 必要に応じてDerived Dataを削除

### ローカライズが機能しない場合
- `LocalizationManager.swift`が正しく更新されているか確認
- アプリを完全に削除して再インストール

## 実装の詳細

### 状態管理
- `OnboardingManager.shared` - シングルトンパターン
- UserDefaultsで`hasCompletedOnboarding`キーを使用

### 画面遷移フロー
```
アプリ起動
  ↓
OnboardingManager.checkOnboardingStatus()
  ↓
[初回] showWelcomeScreen = true → TutorialWelcomeView表示
  ↓
「始める」タップ
  ↓
completeWelcomeScreen() → showFeatureHighlights = true
  ↓
TemporaryFeatureHighlightView表示
  ↓
「完了」タップ
  ↓
completeOnboarding() → hasCompletedOnboarding = true
  ↓
メイン画面へ
```

### 設定画面から呼び出し
```
設定画面
  ↓
「チュートリアルを見る」タップ
  ↓
OnboardingManager.showTutorial()
  ↓
showFeatureHighlights = true
  ↓
TemporaryFeatureHighlightView表示
```

## 今後の改善案

1. **SSCoachMarksへの完全移行**
   - 実際の画面要素をハイライト
   - よりインタラクティブなチュートリアル

2. **アニメーション強化**
   - ページ遷移のアニメーション
   - ハイライトの視覚効果

3. **チュートリアルスキップ機能**
   - ウェルカム画面にスキップボタン追加
   - 設定でチュートリアル無効化オプション

4. **多言語対応の拡張**
   - より詳細なチュートリアル説明
   - 言語別のチュートリアル画像

## 参考リンク

- [OnboardingKit Documentation](https://github.com/danielsaidi/OnboardingKit)
- [SSCoachMarks Documentation](https://github.com/SimformSolutionsPvtLtd/SSCoachMarks)
- [Apple HIG - Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)
