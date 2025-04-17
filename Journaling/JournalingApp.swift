//
//  JournalingApp.swift
//  Journaling
//
//  Created by Debasish Chowdhury on 2025-04-15.
//

import SwiftUI
import FirebaseCore

// Create a dedicated AppDelegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct JournalingApp: App {
    // Use UIApplicationDelegateAdaptor to handle Firebase initialization
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
