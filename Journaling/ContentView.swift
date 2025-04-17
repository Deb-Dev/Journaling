//
//  ContentView.swift
//  Journaling
//
//  Created by Debasish Chowdhury on 2025-04-15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        MainView()
            .environmentObject(appState)
            .preferredColorScheme(appState.currentUser?.prefersDarkMode ?? false ? .dark : .light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
