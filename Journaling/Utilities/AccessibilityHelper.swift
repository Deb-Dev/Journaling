//
//  AccessibilityHelper.swift
// // MARK: - Button Accessibility Extensions
extension Button {
    /// Applies standard accessibility configuration to a button
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - hint: Optional accessibility hint explaining what the button does
    /// - Returns: A button with standard accessibility configuration
    func standardAccessibility(label: String, hint: String? = nil) -> some View {
        var view = self.accessibilityLabel(Text(label.localized))
        if let hintText = hint {
            view = view.accessibilityHint(Text(hintText.localized))
        }
        return view
    }
}
//  Created on 2025-04-21.
//

import SwiftUI

/// Contains modifiers and utilities to improve app accessibility
enum AccessibilityHelper {
    /// Standard accessibility traits for different UI elements
    enum ElementType {
        case button
        case inputField
        case header
        case tab
        case toggleControl
        
        var traits: AccessibilityTraits {
            switch self {
            case .button:
                return .isButton
            case .inputField:
                return [.allowsDirectInteraction, .isSearchField]
            case .header:
                return .isHeader
            case .tab:
                return [.isButton, .isSelected]
            case .toggleControl:
                return [.isButton, .allowsDirectInteraction]
            }
        }
    }
}

//// MARK: - Button Accessibility Extensions
//extension Button {
//    /// Applies standard accessibility configuration to a button
//    /// - Parameters:
//    ///   - label: The accessibility label
//    ///   - hint: Optional accessibility hint explaining what the button does
//    /// - Returns: A button with standard accessibility configuration
//    func standardAccessibility(label: String, hint: String? = nil) -> some View {
//        self
//            .accessibilityLabel(Text(label.localized))
//            .accessibilityHint(hint.map { Text($0.localized) })
//    }
//}
//
//// MARK: - TextField Accessibility Extensions
//extension TextField {
//    /// Applies standard accessibility configuration to a text field
//    /// - Parameters:
//    ///   - label: The accessibility label
//    ///   - hint: Optional accessibility hint explaining what the field is for
//    /// - Returns: A text field with standard accessibility configuration
//    func standardAccessibility(label: String, hint: String? = nil) -> some View {
//        var view = self.accessibilityLabel(Text(label.localized))
//        if let hintText = hint {
//            view = view.accessibilityHint(Text(hintText.localized))
//        }
//        return view.accessibilityTraits(AccessibilityHelper.ElementType.inputField.traits)
//    }
//}

// MARK: - Image Accessibility Extensions
extension Image {
    /// Applies standard accessibility configuration to an image
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - isDecorative: Whether the image is purely decorative
    /// - Returns: An image with standard accessibility configuration
    func standardAccessibility(label: String, isDecorative: Bool = false) -> some View {
        if isDecorative {
            return self
                .accessibilityHidden(true)
        } else {
            return self
                .accessibilityLabel(Text(label.localized))
        }
    }
}

// MARK: - View Accessibility Extensions
extension View {
    /// Applies standard accessibility label and hint
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - hint: Optional accessibility hint
    /// - Returns: A view with standard accessibility configuration
    func standardAccessibility(label: String, hint: String? = nil) -> some View {
        var view = self.accessibilityLabel(Text(label.localized))
        if let hintText = hint {
            view = view.accessibilityHint(Text(hintText.localized))
        }
        return view
    }
    
    /// Configures this view as an accessibility element with the specified traits
    /// - Parameters:
    ///   - type: The type of element (button, inputField, etc)
    ///   - label: The accessibility label
    ///   - hint: Optional accessibility hint
    /// - Returns: A view configured as an accessibility element
//    func accessibilityElement(type: AccessibilityHelper.ElementType, label: String, hint: String? = nil) -> some View {
//        var view = self.accessibilityLabel(Text(label.localized))
//        if let hintText = hint {
//            view = view.accessibilityHint(Text(hintText.localized))
//        }
//        return view.accessibilityTraits(type.traits)
//    }
}
