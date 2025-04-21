// filepath: /Users/debchow/Documents/coco/Journaling/Journaling/Utilities/LocalizationManager.swift
//
//  LocalizationManager.swift
//  Journaling
//
//  Created on 2025-04-17.
//

import Foundation
import SwiftUI

/// A centralized helper for handling localization in the app
enum LocalizationManager {
    /// Get a localized string for the given key
    static func string(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, comment: comment)
    }
    
    /// Get a localized string with format arguments
    static func string(_ key: String, with args: CVarArg..., comment: String = "") -> String {
        String(format: NSLocalizedString(key, comment: comment), args)
    }
}

// MARK: - SwiftUI Text Extension
extension Text {
    /// Initialize a Text view with a localized string key
    static func localized(_ key: String) -> Text {
        Text(LocalizationManager.string(key))
    }
}

// MARK: - View Modifier for Localized Navigation Title
extension View {
    /// Apply a localized navigation title 
    func localizedNavigationTitle(_ key: String) -> some View {
        self.navigationTitle(LocalizationManager.string(key))
    }
    
    /// Apply a localized navigation bar item
    func localizedToolbarButton(key: String, action: @escaping () -> Void) -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizationManager.string(key), action: action)
            }
        }
    }
}
