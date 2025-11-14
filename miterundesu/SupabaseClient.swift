//
//  SupabaseClient.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation
import Supabase

// Supabaseクライアントのシングルトン
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://gtxoniuzwhmdwnhegwnz.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0eG9uaXV6d2htZHduaGVnd256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTY3OTcsImV4cCI6MjA3ODUzMjc5N30.MZPcs9O0xaWcQPRDhn7pIrv9JbFZRU6AI_sQH0dERC8",
    options: SupabaseClientOptions(
        auth: AuthClientOptions(
            // 新しいセッション動作にオプトイン
            // ローカルに保存されたセッションが常に発行されるようになります
            // セッションの有効性チェックは呼び出し側で行う必要があります
            emitLocalSessionAsInitialSession: true
        )
    )
)
