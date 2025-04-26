//
//  TabBarView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $appState.router.path) {
                HomeView()
            }
            .tabItem {
                Label("home.title".localized, systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack(path: $appState.router.path) {
                CalendarView()
            }
            .tabItem {
                Label("calendar.title".localized, systemImage: "calendar")
            }
            .tag(1)

            NavigationStack(path: $appState.router.path) {
                ProfileView()
            }
            .tabItem {
                Label("profile.title".localized, systemImage: "person.fill")
            }
            .tag(2)
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .environmentObject(AppState())
    }
}
