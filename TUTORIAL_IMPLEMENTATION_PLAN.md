# チュートリアル実装計画

## 使用するライブラリ

### 1. OnboardingKit (danielsaidi/OnboardingKit)
- **URL**: https://github.com/danielsaidi/OnboardingKit
- **用途**: ウェルカム画面の作成
- **要件**: iOS 17.0+（現在のプロジェクトはiOS 18.2）

### 2. SSCoachMarks
- **URL**: https://github.com/SimformSolutionsPvtLtd/SSCoachMarks
- **用途**: ハイライト付き機能説明
- **要件**: iOS 17.0+

## 実装コンポーネント

### 1. OnboardingManager
- 初回起動判定を管理
- UserDefaultsで状態を保存
- チュートリアル完了状態を追跡

### 2. TutorialWelcomeView
- アプリアイコンを表示
- 「ようこそ」メッセージ
- 「始める」ボタン

### 3. FeatureHighlightView
- SSCoachMarksを使用
- 主要機能のハイライト表示
  1. カメラズームコントロール
  2. シアターモードトグル
  3. 設定ボタン
  4. スクロールメッセージ

### 4. 設定画面への統合
- 「チュートリアルを再表示」オプションを追加

## データフロー

```
アプリ起動
  ↓
初回起動判定 (OnboardingManager)
  ↓
[初回] TutorialWelcomeView 表示
  ↓
「始める」ボタンタップ
  ↓
FeatureHighlightView 表示（SSCoachMarks）
  ↓
機能ハイライトツアー
  ↓
完了 → メイン画面へ
```

## ファイル構成

```
miterundesu/
├── Onboarding/
│   ├── OnboardingManager.swift
│   ├── TutorialWelcomeView.swift
│   └── FeatureHighlightCoordinator.swift
├── ContentView.swift (修正)
├── SettingsView.swift (修正)
└── Assets.xcassets/
    ├── AppIcon.appiconset/ (アイコン追加)
    └── TutorialAssets.imageset/
```

## 実装手順

1. パッケージのインストール（Xcodeで手動）
2. OnboardingManager作成
3. TutorialWelcomeView作成
4. FeatureHighlightCoordinator作成
5. ContentViewへの統合
6. SettingsViewへの統合
7. アプリアイコンの設定
8. テストと調整

## 注意事項

- ハイライトする要素には`.id()`または`.tag()`モディファイアが必要
- SSCoachMarksの順序は明示的に指定
- チュートリアルはスキップ可能にする
