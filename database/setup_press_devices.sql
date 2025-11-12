-- プレスモード管理テーブルのセットアップ
-- このSQLをSupabase Dashboard > SQL Editorで実行してください

-- テーブル作成
CREATE TABLE IF NOT EXISTS press_devices (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id text NOT NULL UNIQUE,
    access_code text NOT NULL,
    organization text NOT NULL,
    contact_email text,
    contact_name text,
    starts_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    notes text
);

-- インデックス作成（検索高速化）
CREATE INDEX IF NOT EXISTS idx_press_devices_device_id ON press_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_press_devices_access_code ON press_devices(access_code);
CREATE INDEX IF NOT EXISTS idx_press_devices_starts_at ON press_devices(starts_at);
CREATE INDEX IF NOT EXISTS idx_press_devices_expires_at ON press_devices(expires_at);
CREATE INDEX IF NOT EXISTS idx_press_devices_is_active ON press_devices(is_active);

-- RLS（Row Level Security）を有効化
ALTER TABLE press_devices ENABLE ROW LEVEL SECURITY;

-- 既存のポリシーを削除（再実行時のため）
DROP POLICY IF EXISTS "Allow read access to all devices" ON press_devices;
DROP POLICY IF EXISTS "Only service role can insert" ON press_devices;
DROP POLICY IF EXISTS "Only service role can update" ON press_devices;
DROP POLICY IF EXISTS "Only service role can delete" ON press_devices;

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

DROP TRIGGER IF EXISTS update_press_devices_updated_at ON press_devices;

CREATE TRIGGER update_press_devices_updated_at
    BEFORE UPDATE ON press_devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- サンプルデータ（テスト用）
-- 本番環境では削除してください
/*
INSERT INTO press_devices (device_id, access_code, organization, contact_email, contact_name, starts_at, expires_at, notes)
VALUES (
    'SAMPLE-DEVICE-ID',
    'PRESS2025',
    'サンプル新聞社',
    'sample@example.com',
    'サンプル太郎',
    '2025-01-01 00:00:00+09',
    '2025-12-31 23:59:59+09',
    'テスト用デバイス'
);
*/
