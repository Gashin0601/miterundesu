-- プレスモード管理テーブルのマイグレーション
-- press_access_codesテーブルを廃止し、press_devicesにaccess_codeを追加
-- このSQLをSupabase Dashboard > SQL Editorで実行してください

-- STEP 1: press_devicesテーブルにaccess_codeカラムを追加
-- 既存のレコードにはデフォルト値'TEMP-CODE'を設定（後で手動更新が必要）
ALTER TABLE press_devices
ADD COLUMN IF NOT EXISTS access_code text;

-- 既存のレコードにデフォルトのアクセスコードを設定
UPDATE press_devices
SET access_code = 'TEMP-CODE'
WHERE access_code IS NULL;

-- access_codeをNOT NULLに変更
ALTER TABLE press_devices
ALTER COLUMN access_code SET NOT NULL;

-- STEP 2: access_code用のインデックスを作成
CREATE INDEX IF NOT EXISTS idx_press_devices_access_code ON press_devices(access_code);

-- STEP 3: press_access_codesテーブルが存在する場合のみ削除
DO $$
BEGIN
    -- テーブルが存在するかチェック
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'press_access_codes') THEN
        -- ポリシーを削除
        DROP POLICY IF EXISTS "Allow read access to all" ON press_access_codes;
        DROP POLICY IF EXISTS "Only service role can insert" ON press_access_codes;
        DROP POLICY IF EXISTS "Only service role can update" ON press_access_codes;
        DROP POLICY IF EXISTS "Only service role can delete" ON press_access_codes;

        -- インデックスを削除
        DROP INDEX IF EXISTS idx_press_access_codes_code;
        DROP INDEX IF EXISTS idx_press_access_codes_is_active;

        -- テーブルを削除
        DROP TABLE press_access_codes;

        RAISE NOTICE 'press_access_codesテーブルを削除しました。';
    ELSE
        RAISE NOTICE 'press_access_codesテーブルは存在しません（スキップ）。';
    END IF;
END $$;

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE 'マイグレーション完了: press_devicesテーブルにaccess_codeカラムを追加し、press_access_codesテーブルを削除しました。';
    RAISE NOTICE '注意: 既存のデバイスのaccess_codeは"TEMP-CODE"に設定されています。各デバイスに固有のアクセスコードを設定してください。';
END $$;

-- 既存デバイスのaccess_codeを更新する例
-- UPDATE press_devices SET access_code = '新しいコード' WHERE device_id = 'デバイスID';
