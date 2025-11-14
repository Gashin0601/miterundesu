//
//  SupabaseClient.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation
import Supabase

// Supabaseクライアントのシングルトン（遅延初期化）
// Note: Auth警告について
// Supabase Auth v2では、次のメジャーバージョンでセッション発行の動作が変更されます
// 遅延初期化により、警告がXcodeのデバッグ停止ポイントとして扱われるのを回避します
// Supabase Swift v3.xにアップデート時に根本的に解決されます
// 参考: https://github.com/supabase/supabase-swift/pull/822
let supabase: SupabaseClient = {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://gtxoniuzwhmdwnhegwnz.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0eG9uaXV6d2htZHduaGVnd256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTY3OTcsImV4cCI6MjA3ODUzMjc5N30.MZPcs9O0xaWcQPRDhn7pIrv9JbFZRU6AI_sQH0dERC8"
    )
    return client
}()
