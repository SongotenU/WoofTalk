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
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(EntitlementManager.shared)
                .onAppear {
                    revenueCatManager.configure()
                }
        }
    }
}

class AppState: ObservableObject {
    // App-wide state
}
