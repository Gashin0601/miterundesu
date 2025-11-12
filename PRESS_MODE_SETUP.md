# プレスモード管理システム設計

## 概要

報道関係者向けの特別モード「プレスモード」を、デバイス単位で管理するシステム。

## データベース設計

### テーブル: press_devices

| カラム名 | 型 | 説明 | 制約 |
|---------|-----|------|------|
| id | uuid | 主キー | PRIMARY KEY, DEFAULT uuid_generate_v4() |
| device_id | text | デバイスの識別子（UUID） | NOT NULL, UNIQUE |
| access_code | text | デバイス専用アクセスコード | NOT NULL |
| organization | text | 所属機関名 | NOT NULL |
| contact_email | text | 連絡先メールアドレス | |
| contact_name | text | 担当者名 | |
| expires_at | timestamptz | 有効期限 | NOT NULL |
| is_active | boolean | 有効/無効 | NOT NULL, DEFAULT true |
| created_at | timestamptz | 作成日時 | NOT NULL, DEFAULT now() |
| updated_at | timestamptz | 更新日時 | NOT NULL, DEFAULT now() |
| notes | text | 備考 | |

### SQL（Supabaseで実行）

```sql
-- テーブル作成
CREATE TABLE press_devices (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id text NOT NULL UNIQUE,
    access_code text NOT NULL,
    organization text NOT NULL,
    contact_email text,
    contact_name text,
    expires_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    notes text
);

-- インデックス作成（検索高速化）
CREATE INDEX idx_press_devices_device_id ON press_devices(device_id);
CREATE INDEX idx_press_devices_access_code ON press_devices(access_code);
CREATE INDEX idx_press_devices_expires_at ON press_devices(expires_at);
CREATE INDEX idx_press_devices_is_active ON press_devices(is_active);

-- RLS（Row Level Security）を有効化
ALTER TABLE press_devices ENABLE ROW LEVEL SECURITY;

-- 読み取りポリシー（全デバイスからの読み取りを許可）
CREATE POLICY "Allow read access to all devices"
ON press_devices FOR SELECT
USING (true);

-- 挿入・更新・削除はサービスロールのみ（管理者）
CREATE POLICY "Only service role can insert"
ON press_devices FOR INSERT
WITH CHECK (false);

CREATE POLICY "Only service role can update"
ON press_devices FOR UPDATE
USING (false);

CREATE POLICY "Only service role can delete"
ON press_devices FOR DELETE
USING (false);

-- 更新日時の自動更新トリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_press_devices_updated_at
    BEFORE UPDATE ON press_devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

## セキュリティ設計

### 1. デバイス識別

- iOSの `identifierForVendor` を使用
- アプリ削除・再インストールで変わる可能性あり
- より永続的な識別が必要な場合はKeychain保存のUUIDを生成

### 2. アクセスコード認証

- プレスモードのオン/オフ時に毎回アクセスコードを要求
- 各デバイスが専用のアクセスコードを持つ
- デバイスID + アクセスコードの両方で認証
- セキュリティ向上: 他のデバイスのコードでは認証できない

### 3. 読み取り専用API

- アプリからは読み取りのみ可能（anonキー使用）
- 挿入・更新・削除は管理画面から（service_roleキー使用）

### 4. 有効期限チェック

- アプリ起動時に毎回チェック
- 期限切れの場合は通常モードに戻る
- アクセスコード認証時も期限をチェック

## 管理方法

### 1. Supabase Dashboard（推奨）

1. https://app.supabase.com でプロジェクトを開く
2. Table Editor → press_devices
3. 手動でレコードを追加・編集

### 2. SQL Editor

```sql
-- デバイスを追加（アクセスコードも設定）
INSERT INTO press_devices (device_id, access_code, organization, contact_email, contact_name, expires_at)
VALUES (
    'DEVICE-UUID-HERE',
    'PRESS2025',
    '朝日新聞',
    'press@example.com',
    '山田太郎',
    '2025-12-31 23:59:59+09'
);

-- アクセスコードを変更
UPDATE press_devices
SET access_code = '新しいコード'
WHERE device_id = 'DEVICE-UUID-HERE';

-- 有効期限を延長
UPDATE press_devices
SET expires_at = '2026-12-31 23:59:59+09'
WHERE device_id = 'DEVICE-UUID-HERE';

-- デバイスを無効化
UPDATE press_devices
SET is_active = false
WHERE device_id = 'DEVICE-UUID-HERE';

-- 期限切れのデバイスを確認
SELECT * FROM press_devices
WHERE expires_at < now()
ORDER BY expires_at DESC;
```

## アプリ側の実装

### 機能

1. **デバイスID取得** - UIDevice.identifierForVendor
2. **権限チェック** - 起動時にSupabaseにリクエスト
3. **アクセスコード認証** - プレスモードのオン/オフ時に毎回認証
4. **プレスモード有効化** - 権限とアクセスコードが正しい場合に有効化
5. **期限表示** - プレスモード画面に有効期限を表示

### 動作フロー

#### アプリ起動時
```
アプリ起動
  ↓
デバイスID取得
  ↓
Supabaseにリクエスト
  ↓
権限チェック（device_id + expires_at + is_active）
  ├─ 有効 → プレスモード設定を表示可能
  └─ 無効 → プレスモード設定をグレーアウト
```

#### プレスモードのオン/オフ時
```
ユーザーがトグルをタップ
  ↓
権限がある場合
  ↓
アクセスコード入力画面を表示
  ↓
ユーザーがコードを入力
  ↓
Supabaseで検証（device_id + access_code + is_active + expires_at）
  ├─ 正しい → プレスモードの状態を変更
  └─ 間違い → エラー表示 + バイブレーション
```

## 管理画面（将来的）

必要に応じて、Web管理画面を作成可能：

- デバイス一覧表示
- デバイス追加・編集・削除
- 有効期限の一括更新
- 利用状況の確認

実装技術: Next.js + Supabase または Supabase Dashboard で十分
