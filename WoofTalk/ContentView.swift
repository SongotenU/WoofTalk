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

            CommunityPhraseBrowserView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }

            OfflineModeView()
                .tabItem {
                    Label("Offline", systemImage: "moon.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
