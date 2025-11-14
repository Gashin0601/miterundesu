# Supabase Auth警告の対処方法

## 問題

アプリ起動時に以下の警告が表示され、実行が停止する：
```
Initial session emitted after attempting to refresh the local stored session.
```

**症状**:
- アプリがデバッグ実行時に停止する
- スタックトレースに`_RuntimeWarningReporter.reportIssue`が表示される
- 毎回この警告で起動できない

## 原因

1. **Supabase側**: v2.37.0の既知の警告（機能には影響なし）
2. **Xcode側**: Main Thread CheckerとRuntime Issue Breakpointが警告を実行停止として扱っている

**重要**: PR #822の`emitLocalSessionAsInitialSession`は本番環境で推奨されておらず、PR #844で別アプローチに置き換えられました。現在のバージョンではまだ利用不可。

## 解決方法（この順番で実施）

### ステップ1: Xcodeの診断設定を無効化（必須）

1. Xcode上部メニュー: **`Product`** → **`Scheme`** → **`Edit Scheme...`**
2. 左側で **`Run`** を選択
3. **`Diagnostics`** タブを開く
4. 以下を**オフ**にする：
   - ☐ **Main Thread Checker** ← 最重要
   - ☐ **Thread Performance Checker**
   - （Address Sanitizer、Thread Sanitizerはデフォルトでオフ）

5. **`Close`** をクリック

### ステップ2: Runtime Issue Breakpointを削除（推奨）

1. Xcodeの左側ナビゲーター: **Breakpoint Navigator** (⌘+8)
2. **`Runtime Issue Breakpoint`** を探す
3. 見つかったら：
   - **削除**: 右クリック → **`Delete Breakpoint`**
   - または**無効化**: 左側の青いアイコンをクリック

### ステップ3: クリーン＆ビルド

```
Product → Clean Build Folder (⌘⇧K)
Product → Run (⌘R)
```

これで確実に起動するはずです。

### 代替方法: 一時的にすべてのブレークポイントを無効化

キーボードショートカット: **`⌘Y`**
- すべてのブレークポイントを一時的に無効/有効化できます
- デバッグ時に素早く切り替え可能

### その他の設定（オプション）

#### ログレベルの調整
デバッグコンソールの出力を減らす：
1. `Product` → `Scheme` → `Edit Scheme...`
2. 「Run」→「Arguments」タブ
3. 「Environment Variables」に追加：
   - Name: `OS_ACTIVITY_MODE`
   - Value: `disable`

#### 遅延初期化（実装済み）
`SupabaseClient.swift`は既に遅延初期化パターンを使用しています：
```swift
let supabase: SupabaseClient = { /* ... */ }()
```
これにより、警告のタイミングが遅延されます。

## なぜこの設定が必要か

**Main Thread Checker**は、UIの更新がメインスレッド以外で行われていないかをチェックします。Supabaseの警告は実際にはスレッド問題ではなく、セッション管理の動作に関する情報提供ですが、Xcodeが誤って実行を停止してしまいます。

**Runtime Issue Breakpoint**は、すべてのランタイム警告で実行を停止するブレークポイントです。これがあると、Supabaseの警告でも停止してしまいます。

## 注意事項

- この警告自体はアプリの機能に影響しません
- Supabase Swift v3.xにアップデート時に根本的に解決されます
- プロダクションビルドでは影響ありません（デバッグモードのみ）

## 確認方法

設定変更後、アプリをクリーン＆ビルド：
1. `Product` → `Clean Build Folder` (⌘⇧K)
2. `Product` → `Run` (⌘R)
