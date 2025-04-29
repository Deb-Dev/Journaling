//
//  LanguageSelectionView.swift
//  Journaling
//
//  Created on 2025-04-28.
//

import SwiftUI

/// A view for selecting the app's language
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    @State private var languages: [(code: String, name: String)] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(languages, id: \.code) { language in
                    Button(action: {
                        selectedLanguage = language.code
                        LocalizationManager.setLanguage(language.code)
                        // Post notification for views to refresh
                        NotificationCenter.default.post(name: .languageChanged, object: nil)
                        dismiss()
                    }) {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if language.code == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("settings.language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                languages = LocalizationManager.supportedLanguages()
            }
        }
    }
}

// Extension for the language change notification
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(selectedLanguage: .constant("en"))
    }
}
