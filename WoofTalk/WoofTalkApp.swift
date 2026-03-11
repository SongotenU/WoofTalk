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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
