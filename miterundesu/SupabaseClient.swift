//
//  SupabaseClient.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation
import Supabase

// Supabaseクライアントのシングルトン
// Note: Auth警告について
// Supabase Auth v2では、次のメジャーバージョンでセッション発行の動作が変更されます
// 現在の実装では警告が表示されますが、機能には影響ありません
// Supabase Swift v3.xにアップデート時に対応が必要です
// 参考: https://github.com/supabase/supabase-swift/pull/822
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://gtxoniuzwhmdwnhegwnz.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0eG9uaXV6d2htZHduaGVnd256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTY3OTcsImV4cCI6MjA3ODUzMjc5N30.MZPcs9O0xaWcQPRDhn7pIrv9JbFZRU6AI_sQH0dERC8"
)
