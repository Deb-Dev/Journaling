//
//  MainView.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                if appState.isOnboarding {
                    OnboardingView()
                } else {
                    TabBarView()
                }
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppState())
    }
}
