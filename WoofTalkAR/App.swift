import SwiftUI
import Supabase

@main
struct WoofTalkAR: App {
    @StateObject private var supabaseClient = SupabaseClient(
        supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!,
        supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseClient)
        }
    }
}
