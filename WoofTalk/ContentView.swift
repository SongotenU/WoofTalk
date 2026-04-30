//
//  ContentView.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TranslationView()
                .tabItem {
                    Label("Translate", systemImage: "bubble.left.and.bubble.right")
                }
                .accessibilityLabel("Translate Tab")
                .accessibilityHint("Real-time dog translation")

            CommunityPhraseBrowserView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .accessibilityLabel("Community Tab")
                .accessibilityHint("Browse community phrases")

            OfflineModeView()
                .tabItem {
                    Label("Offline", systemImage: "moon.fill")
                }
                .accessibilityLabel("Offline Mode Tab")
                .accessibilityHint("Use app without internet")
        }
        .accessibilityLabel("Main Tab Navigation")
    }
}

#Preview {
    ContentView()
}
