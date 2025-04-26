//
//  ViewModifiers.swift
//  Journaling
//
//  Created on 2025-04-21.
//

import SwiftUI

// MARK: - Error Alert Modifier

/// A view modifier for presenting error alerts with standardized formatting
struct ErrorAlertModifier: ViewModifier {
    @Binding var errorMessage: String

    func body(content: Content) -> some View {
        content.alert(isPresented: Binding(
            get: { !errorMessage.isEmpty },
            set: { if !$0 { errorMessage = "" } }
        )) {
            Alert(
                title: Text("general.error.title".localized),
                message: Text(errorMessage),
                dismissButton: .default(Text("general.ok".localized))
            )
        }
    }
}

// MARK: - Confirmation Alert Modifier

/// A view modifier for presenting consistent confirmation alerts
struct ConfirmationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmAction: () -> Void

    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented) {
            Button("general.cancel".localized, role: .cancel) {}
            Button("general.delete".localized, role: .destructive, action: confirmAction)
        } message: {
            Text(message)
        }
    }
}

// MARK: - View Styling Modifiers

/// A view modifier for applying consistent card styling
struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 3
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
            .padding(.horizontal)
    }
}

// MARK: - View Extensions

extension View {
    /// Presents a standardized error alert using the provided error message
    func errorAlert(errorMessage: Binding<String>) -> some View {
        modifier(ErrorAlertModifier(errorMessage: errorMessage))
    }
    
    /// Presents a standardized confirmation alert for destructive actions
    func confirmationAlert(
        isPresented: Binding<Bool>, 
        title: String, 
        message: String, 
        confirmAction: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmationAlertModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            confirmAction: confirmAction
        ))
    }
    
    /// Applies standard card styling to the content
    func standardCard(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 3) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}
