// 
//  Extensions.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import SwiftUI

// MARK: - View Extensions
extension View {
    /// Applies the given transform if the condition evaluates to true.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies modifiers to only specific display sizes
    func responsiveFrame(size: CGSize, isCompact: Bool) -> some View {
        self
            .frame(maxWidth: isCompact ? size.width * 0.9 : nil)
            .padding(isCompact ? 10 : 20)
    }
    
    /// A reusable style for primary buttons in the app
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(10)
    }
    
    /// A reusable style for secondary buttons in the app
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(Color.accentColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
    }
    
    /// A reusable style for text fields in the app
    func textFieldStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
    }
    
    /// Applies accessibility features to buttons
    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibility(label: Text(label))
            .if(hint != nil) { view in
                view.accessibility(hint: Text(hint!))
            }
    }
}

// MARK: - Date Extensions
extension Date {
    /// Returns a formatted string for display in the UI
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    /// Returns a time string for display in the UI
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns true if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Returns a relative time description
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extensions
extension String {
    /// Checks if the string contains at least one emoji character
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            // Check if the scalar is an emoji
            // This covers most emoji ranges including emoticons, symbols, and pictographs
            if scalar.properties.isEmoji && scalar.value > 0x238C {
                return true
            }
        }
        return false
    }
}

// MARK: - String Extensions
extension String {
    /// Returns true if the string is a valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Returns true if the string is a valid password (8+ chars, with at least one number)
    var isValidPassword: Bool {
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: self)
    }
}

// MARK: - Color Extensions
extension Color {
    static let backgroundColor = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    static let textColor = Color(.label)
    static let secondaryTextColor = Color(.secondaryLabel)
    static let tertiaryTextColor = Color(.tertiaryLabel)
    
    static let moodHappy = Color.yellow
    static let moodContent = Color.green
    static let moodNeutral = Color.blue
    static let moodSad = Color.indigo
    static let moodAnxious = Color.purple
    static let moodAngry = Color.red
    
    func toMoodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return .moodHappy
        case .content: return .moodContent
        case .neutral: return .moodNeutral
        case .sad: return .moodSad
        case .anxious: return .moodAnxious
        case .angry: return .moodAngry
        }
    }
}
