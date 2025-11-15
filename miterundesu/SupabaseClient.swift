//
//  SupabaseClient.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation
import Supabase

// Supabaseクライアントのシングルトン（遅延初期化）
// Note: Supabase Auth警告について
// この警告はSupabase Swift SDK v2の既知の動作で、機能には影響しません
// Main Thread CheckerとRuntime Issue Breakpointを無効にすることで警告を非表示にできます
// 詳細は SUPABASE_AUTH_WORKAROUND.md を参照
// 参考: https://github.com/supabase/supabase-swift/pull/822
let supabase: SupabaseClient = {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://gtxoniuzwhmdwnhegwnz.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0eG9uaXV6d2htZHduaGVnd256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTY3OTcsImV4cCI6MjA3ODUzMjc5N30.MZPcs9O0xaWcQPRDhn7pIrv9JbFZRU6AI_sQH0dERC8"
    )
    return client
}()
