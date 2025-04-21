//
//  TabBarView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("home.title".localized, systemImage: "house.fill") // Updated key
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("calendar.title".localized, systemImage: "calendar") // Updated key
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("profile.title".localized, systemImage: "person.fill") // Updated key
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
