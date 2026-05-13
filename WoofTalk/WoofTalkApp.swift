import SwiftUI
import CoreData

@main
struct WoofTalkApp: App {
    let persistenceController = PersistenceController.shared
    private let revenueCatManager = RevenueCatManager.shared

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\ .managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(EntitlementManager.shared)
                .onAppear {
                    // Initialize Sentry for error tracking
                    SentryManager.shared.initialize(
                        dsn: ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? "",
                        environment: ProcessInfo.processInfo.environment["SENTRY_ENVIRONMENT"] ?? "production"
                    )
                    revenueCatManager.configure()
                    // FIX: Configure SupabaseManager with environment credentials
                    // This was missing - without it, client is nil and all auth fails
                    SupabaseManager.shared.configure(
                        url: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "",
                        anonKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
                    )
                }
        }
    }
}

class AppState: ObservableObject {
    // App-wide state
}
