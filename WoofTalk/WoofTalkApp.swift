//
//  WoofTalkApp.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import SwiftUI
import CoreData

@main
struct WoofTalkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                TranslationView()
                    .tabItem {
                        Label("Translate", systemImage: "bubble.left.and.bubble.right")
                    }
                
                CommunityPhraseBrowserView()
                    .tabItem {
                        Label("Community", systemImage: "person.3.fill")
                    }
                
                OfflineModeView()
                    .tabItem {
                        Label("Offline", systemImage: "moon.fill")
                    }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
