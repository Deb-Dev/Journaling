//
//  NavigationRouter.swift
//  Journaling
//
//  Created on 2025-04-21.
//

import SwiftUI

/// A centralized navigation manager for the app
class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case newEntry
        case editEntry(JournalEntry)
        case settings
        case editProfile
        
        var id: String {
            switch self {
            case .newEntry: return "newEntry"
            case .editEntry(let entry): return "editEntry-\(entry.id ?? "unknown")"
            case .settings: return "settings"
            case .editProfile: return "editProfile"
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    func navigateToEntryDetail(_ entry: JournalEntry) {
        // Force UI update on main thread to ensure navigation happens immediately
        DispatchQueue.main.async {
            self.path.append(entry)
            // Explicitly trigger objectWillChange to ensure SwiftUI detects the change
            self.objectWillChange.send()
        }
    }
    
    func navigateBack() {
        if !path.isEmpty {
            DispatchQueue.main.async {
                self.path.removeLast()
                self.objectWillChange.send()
            }
        }
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    // MARK: - Sheet Presentation
    
    func showNewEntrySheet() {
        activeSheet = .newEntry
    }
    
    func showEditEntrySheet(_ entry: JournalEntry) {
        activeSheet = .editEntry(entry)
    }
    
    func showSettingsSheet() {
        activeSheet = .settings
    }
    
    func showEditProfileSheet() {
        activeSheet = .editProfile
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
}
