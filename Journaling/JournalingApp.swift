//
//  JournalingApp.swift
//  Journaling
//
//  Created by Debasish Chowdhury on 2025-04-15.
//

import SwiftUI

@main
struct JournalingApp: App {
    // Create our app state
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .preferredColorScheme(appState.currentUser?.prefersDarkMode ?? false ? .dark : .light)
        }
    }
}
