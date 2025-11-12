# Supabase導入ガイド

## 概要

このドキュメントでは、miterundesuプロジェクトにSupabaseを導入する手順を説明します。

---

## 前提条件

- Xcode 15.0以降
- iOS 13.0以降をターゲット
- Supabaseアカウント（https://app.supabase.com で作成）

---

## 導入手順

### 1. Supabaseパッケージの追加（Xcodeで実行）

**⚠️ コマンドラインではできません。以下の手順をXcodeで実行してください。**

1. Xcodeでプロジェクトを開く
2. `File` → `Add Package Dependencies...` を選択
3. 検索バーに以下のURLを入力：
   ```
   https://github.com/supabase/supabase-swift.git
   ```
4. バージョン：`2.0.0` 以降（最新版推奨）を選択
5. `Supabase` 製品を選択
6. ターゲット `miterundesu` に追加
7. `Add Package` をクリック

### 2. Supabaseプロジェクトの作成

1. https://app.supabase.com にアクセス
2. 新規プロジェクトを作成
3. `Project Settings` → `API` から以下を取得：
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbG...`（長い文字列）

### 3. 環境変数の設定

`SupabaseClient.swift` を編集：

```swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_PROJECT_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

上記の `YOUR_SUPABASE_PROJECT_URL` と `YOUR_SUPABASE_ANON_KEY` を実際の値に置き換えてください。

**セキュリティ上の注意：**
- 本番環境では環境変数や設定ファイルを使用
- `.gitignore` に設定ファイルを追加して機密情報を保護

### 4. データモデルの作成

Supabaseのテーブルに対応するSwift構造体を作成：

```swift
struct YourModel: Codable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}
```

### 5. データ操作の実装例

#### データ取得
```swift
func fetchData() async throws -> [YourModel] {
    let response: [YourModel] = try await supabase
        .from("your_table")
        .select()
        .execute()
        .value
    return response
}
```

#### データ挿入
```swift
func insertData(item: YourModel) async throws {
    try await supabase
        .from("your_table")
        .insert(item)
        .execute()
}
```

#### データ更新
```swift
func updateData(id: UUID, name: String) async throws {
    try await supabase
        .from("your_table")
        .update(["name": name])
        .eq("id", value: id)
        .execute()
}
```

#### データ削除
```swift
func deleteData(id: UUID) async throws {
    try await supabase
        .from("your_table")
        .delete()
        .eq("id", value: id)
        .execute()
}
```

---

## 利用可能な機能

Supabase Swift SDKでは以下の機能が利用可能：

### 1. Database（Postgrest）
- CRUD操作
- リアルタイムクエリ
- フィルタリング、ソート

### 2. Authentication
- メール/パスワード認証
- OAuth（Google, GitHub, etc.）
- マジックリンク

```swift
// サインアップ
try await supabase.auth.signUp(email: email, password: password)

// ログイン
try await supabase.auth.signIn(email: email, password: password)

// ログアウト
try await supabase.auth.signOut()

// セッション取得
let session = try await supabase.auth.session
```

### 3. Storage
- ファイルアップロード/ダウンロード
- 画像最適化

```swift
// ファイルアップロード
try await supabase.storage
    .from("bucket-name")
    .upload(path: "file.jpg", file: imageData)

// ダウンロード
let data = try await supabase.storage
    .from("bucket-name")
    .download(path: "file.jpg")
```

### 4. Realtime
- データベース変更のリアルタイム購読

```swift
let channel = await supabase.channel("public:your_table")

await channel.on(.postgresChanges(
    event: .insert,
    schema: "public",
    table: "your_table"
)) { payload in
    print("New row inserted: \(payload)")
}

await channel.subscribe()
```

### 5. Edge Functions
- サーバーサイド関数の呼び出し

```swift
let response = try await supabase.functions.invoke(
    "function-name",
    options: FunctionInvokeOptions(
        body: ["key": "value"]
    )
)
```

---

## ベストプラクティス

### 1. Singletonパターン
- `SupabaseClient` はアプリ全体で1つのインスタンスを使用
- グローバル変数 `supabase` で管理

### 2. エラーハンドリング
```swift
do {
    let data = try await fetchData()
    // 成功時の処理
} catch {
    print("Error: \(error)")
    // エラー処理
}
```

### 3. Row Level Security（RLS）
- Supabaseダッシュボードでテーブルごとにセキュリティポリシーを設定
- ユーザーが自分のデータのみアクセスできるように制限

### 4. 環境変数の管理
```swift
// Config.plist または Config.swift で管理
struct Config {
    static let supabaseURL = "YOUR_URL"
    static let supabaseKey = "YOUR_KEY"
}
```

---

## トラブルシューティング

### パッケージが追加できない
- Xcodeのバージョンを確認（15.0以降推奨）
- ネットワーク接続を確認
- Derived Dataをクリア: `Xcode` → `Settings` → `Locations` → `Derived Data` → 削除

### ビルドエラー
- Clean Build: `Cmd + Shift + K`
- Rebuild: `Cmd + B`
- パッケージキャッシュをリセット: `File` → `Packages` → `Reset Package Caches`

### 接続エラー
- Supabase URLとキーが正しいか確認
- Supabaseプロジェクトが一時停止していないか確認
- ネットワーク接続を確認

---

## 参考リンク

- [Supabase公式ドキュメント](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Swift API Reference](https://supabase.com/docs/reference/swift)
- [iOS SwiftUI クイックスタート](https://supabase.com/docs/guides/getting-started/quickstarts/ios-swiftui)

---

## コマンドラインでできること・できないこと

### ✅ できること
- 設定ファイル（`SupabaseClient.swift`など）の作成
- モデルファイルの作成
- ドキュメントの作成

### ❌ できないこと
- **Swift Package Managerでのパッケージ追加**（Xcode GUIが必要）
- Xcodeプロジェクトファイル（.xcodeproj）への自動追加

理由: このプロジェクトは `.xcodeproj` 形式で、`Package.swift` ファイルを使用していないため、パッケージ管理はXcode GUI経由でのみ可能です。
