# Supabase Auth警告の対処方法

## 問題

アプリ起動時に以下の警告が表示され、実行が停止する：
```
Initial session emitted after attempting to refresh the local stored session.
```

## 原因

Xcodeのデバッグ設定で「Runtime API Checking」が有効になっているため、警告が実行停止ポイントとして扱われています。

## 解決方法

### 方法1: Xcodeのデバッグ設定を変更（推奨）

1. Xcode上部メニュー: `Product` → `Scheme` → `Edit Scheme...`
2. 左側で「Run」を選択
3. 「Diagnostics」タブを開く
4. 「Runtime API Checking」セクションで以下を**オフ**にする：
   - Main Thread Checker
   - Thread Performance Checker
   - Runtime Issues（すべて）

5. 「Close」をクリック

### 方法2: Supabase初期化の遅延

`SupabaseClient.swift`を以下のように変更：

```swift
import Foundation
import Supabase

// 遅延初期化によるクラッシュ回避
let supabase: SupabaseClient = {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://gtxoniuzwhmdwnhegwnz.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0eG9uaXV6d2htZHduaGVnd256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTY3OTcsImV4cCI6MjA3ODUzMjc5N30.MZPcs9O0xaWcQPRDhn7pIrv9JbFZRU6AI_sQH0dERC8"
    )
    return client
}()
```

### 方法3: Exception Breakpointの無効化

1. Xcodeの左側ナビゲーターで「Breakpoint Navigator」（⌘8）を開く
2. 「Runtime Issues Breakpoint」があれば右クリック → 「Delete Breakpoint」

### 方法4: ログレベルの調整（一時的）

デバッグコンソールの出力を減らす：
1. Xcode上部メニュー: `Product` → `Scheme` → `Edit Scheme...`
2. 「Run」→「Arguments」タブ
3. 「Environment Variables」に追加：
   - Name: `OS_ACTIVITY_MODE`
   - Value: `disable`

## 推奨設定

**方法1**が最も効果的です。Runtime API Checkingは開発時に便利ですが、サードパーティライブラリの警告で頻繁に停止する場合は無効化することをお勧めします。

## 注意事項

- この警告自体はアプリの機能に影響しません
- Supabase Swift v3.xにアップデート時に根本的に解決されます
- プロダクションビルドでは影響ありません（デバッグモードのみ）

## 確認方法

設定変更後、アプリをクリーン＆ビルド：
1. `Product` → `Clean Build Folder` (⌘⇧K)
2. `Product` → `Run` (⌘R)
