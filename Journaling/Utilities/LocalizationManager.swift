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
    // MARK: - Properties
    
    /// The current locale identifier
    private static var currentLocaleIdentifier = UserDefaults.standard.string(forKey: "app_language") ?? Locale.current.identifier
    
    /// The bundle to get resources from
    private static var bundle: Bundle = {
        // If we have a custom language set, load that bundle instead of the main bundle
        guard let languageCode = UserDefaults.standard.string(forKey: "app_language"),
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }()
    
    // MARK: - Public Methods
    
    /// Get a localized string for the given key
    static func string(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, comment: comment)
    }
    
    /// Get a localized string with format arguments
    static func string(_ key: String, with args: CVarArg..., comment: String = "") -> String {
        String(format: NSLocalizedString(key, tableName: nil, bundle: bundle, comment: comment), args)
    }
    
    /// Get a localized pluralized string
    static func pluralString(_ key: String, count: Int, comment: String = "") -> String {
        let format = NSLocalizedString(key, tableName: nil, bundle: bundle, comment: comment)
        return String.localizedStringWithFormat(format, count)
    }
    
    /// Set the application language
    static func setLanguage(_ languageCode: String) -> Bool {
        // Save the preferred language
        UserDefaults.standard.set(languageCode, forKey: "app_language")
        UserDefaults.standard.synchronize()
        
        // Update the locale and bundle
        currentLocaleIdentifier = languageCode
        
        // Reload the bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let newBundle = Bundle(path: path) {
            bundle = newBundle
            return true
        }
        
        // If we couldn't find the bundle, revert to main
        bundle = Bundle.main
        return false
    }
    
    /// Get the current language code
    static func currentLanguage() -> String {
        return currentLocaleIdentifier
    }
    
    /// Get list of supported languages
    static func supportedLanguages() -> [(code: String, name: String)] {
        let locales = Bundle.main.localizations.filter { $0 != "Base" }
        return locales.map { code in
            let name = Locale.current.localizedString(forLanguageCode: code) ?? code
            return (code, name)
        }
    }
}

// MARK: - SwiftUI Text Extension
extension Text {
    /// Initialize a Text view with a localized string key
    static func localized(_ key: String) -> Text {
        Text(LocalizationManager.string(key))
    }
    
    /// Initialize a Text view with a localized string key and format arguments
    static func localized(_ key: String, with args: CVarArg...) -> Text {
        Text(LocalizationManager.string(key, with: args, comment: ""))
    }
    
    /// Initialize a Text view with a pluralized string
    static func pluralized(_ key: String, count: Int) -> Text {
        Text(LocalizationManager.pluralString(key, count: count))
    }
}

// MARK: - String Extension for Bridging Old Code
extension String {
    func pluralized(count: Int) -> String {
        return LocalizationManager.pluralString(self, count: count)
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
