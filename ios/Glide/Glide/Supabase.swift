import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://sokgshsbxuzkebpaqmms.supabase.co")!,
    supabaseKey: "sb_publishable_muWVvZvbv_lzf6kjs2POhw_sNxqoVva",
    options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
)
