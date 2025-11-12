# データベースセットアップ手順

## 1. 新規セットアップ（初めてプレスモード機能を導入する場合）

`setup_press_devices.sql`をSupabase Dashboardで実行してください。

1. https://app.supabase.com でプロジェクトを開く
2. SQL Editor を開く
3. `setup_press_devices.sql`の内容を貼り付けて実行

## 2. マイグレーション（既にpress_access_codesテーブルが存在する場合）

既存のシステムをデバイスごとの専用アクセスコード方式に移行する場合、`migrate_to_device_access_codes.sql`を実行してください。

### マイグレーションの内容

1. `press_devices`テーブルに`access_code`カラムを追加
2. 既存デバイスのアクセスコードを`TEMP-CODE`に設定
3. `press_access_codes`テーブルを削除

### 実行手順

1. https://app.supabase.com でプロジェクトを開く
2. SQL Editor を開く
3. `migrate_to_device_access_codes.sql`の内容を貼り付けて実行
4. **重要**: 各デバイスに固有のアクセスコードを設定してください

```sql
-- 各デバイスにアクセスコードを設定
UPDATE press_devices
SET access_code = '新しいコード'
WHERE device_id = 'デバイスID';
```

## 3. デバイスの追加

新しい報道機関のデバイスを追加する際は、以下のSQLを使用してください。

```sql
INSERT INTO press_devices (device_id, access_code, organization, contact_email, contact_name, expires_at, notes)
VALUES (
    'アプリから取得したデバイスID',
    'PRESS2025',  -- デバイス専用のアクセスコード
    '朝日新聞',
    'press@example.com',
    '山田太郎',
    '2025-12-31 23:59:59+09',
    '2025年取材用'
);
```

### デバイスIDの取得方法

報道機関の担当者に以下の手順でデバイスIDを取得してもらってください：

1. アプリを起動
2. 設定画面を開く
3. プレスモード設定セクションの「デバイスID」をタップ
4. 「コピー」ボタンでクリップボードにコピー
5. メールなどで送信

## 4. よくある操作

### アクセスコードの変更
```sql
UPDATE press_devices
SET access_code = '新しいコード'
WHERE device_id = 'デバイスID';
```

### 有効期限の延長
```sql
UPDATE press_devices
SET expires_at = '2026-12-31 23:59:59+09'
WHERE device_id = 'デバイスID';
```

### デバイスの一時無効化
```sql
UPDATE press_devices
SET is_active = false
WHERE device_id = 'デバイスID';
```

### 期限切れデバイスの確認
```sql
SELECT device_id, organization, expires_at,
       EXTRACT(DAY FROM (expires_at - now())) as days_remaining
FROM press_devices
WHERE expires_at < now() + interval '30 days'
ORDER BY expires_at ASC;
```

## セキュリティについて

- アプリからはデータの読み取りのみ可能（Row Level Security設定済み）
- データの追加・更新・削除はSupabase Dashboardまたはservice_roleキーでのみ可能
- 各デバイスは専用のアクセスコードを持ち、他のデバイスのコードでは認証できません
- アクセスコードは大文字に変換されて検証されます（大文字小文字の区別なし）
