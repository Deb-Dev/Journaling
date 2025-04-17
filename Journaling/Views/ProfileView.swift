//
//  ProfileView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isEditingProfile = false
    @State private var isShowingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile header
                    ProfileHeaderView(
                        name: appState.currentUser?.name ?? "",
                        email: appState.currentUser?.email ?? "",
                        onEditProfile: { isEditingProfile = true }
                    )
                    
                    Divider()
                    
                    // Journaling goals
                    if let goals = appState.currentUser?.journalingGoals, !goals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("My Journaling Goals")
                                .font(.headline)
                            
                            Text(goals)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.accentColor)
                                
                                Text("Settings")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Button(action: logout) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.red)
                                
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView()
            }
        }
    }
    
    private func logout() {
        appState.logout()
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let name: String
    let email: String
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile picture
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 5) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onEditProfile) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var journalingGoals: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Journaling Goals")) {
                    TextEditor(text: $journalingGoals)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = ""
                    }
                )
            }
            .onAppear {
                if let user = appState.currentUser {
                    name = user.name
                    journalingGoals = user.journalingGoals
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = ""
        
        appState.updateUserProfile(name: name, journalingGoals: journalingGoals)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { _ in
                dismiss()
            })
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var notificationsEnabled: Bool = true
    @State private var reminderTime: Date = Date()
    @State private var useBiometricAuth: Bool = false
    @State private var prefersDarkMode: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Daily Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _ in
                        updateNotificationSettings()
                    }
                
                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _ in
                            updateNotificationSettings()
                        }
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $prefersDarkMode)
                    .onChange(of: prefersDarkMode) { _ in
                        appState.updateThemePreference(darkMode: prefersDarkMode)
                    }
            }
            
            Section(header: Text("Security")) {
                Toggle("Use Face ID / Touch ID", isOn: $useBiometricAuth)
                    .onChange(of: useBiometricAuth) { _ in
                        appState.updateBiometricAuthPreference(enabled: useBiometricAuth)
                    }
            }
            
            Section(header: Text("Legal")) {
                NavigationLink(destination: LegalDocumentView(title: "Privacy Policy", content: privacyPolicyText)) {
                    Text("Privacy Policy")
                }
                
                NavigationLink(destination: LegalDocumentView(title: "Terms of Service", content: termsOfServiceText)) {
                    Text("Terms of Service")
                }
            }
            
            Section(header: Text("App Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if let user = appState.currentUser {
                notificationsEnabled = user.notificationsEnabled
                reminderTime = user.reminderTime
                useBiometricAuth = user.useBiometricAuth
                prefersDarkMode = user.prefersDarkMode
            }
        }
    }
    
    private func updateNotificationSettings() {
        appState.updateNotificationPreferences(enabled: notificationsEnabled, reminderTime: reminderTime)
    }
}

// MARK: - Legal Document View
struct LegalDocumentView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            Text(content)
                .padding()
        }
        .navigationTitle(title)
    }
}

// Sample text for legal documents
let privacyPolicyText = """
# Privacy Policy

Last Updated: April 16, 2025

This Privacy Policy describes how Reflect ("we", "our", or "us") collects, uses, and shares your personal information when you use our mobile application.

## Information We Collect

### Personal Information
- Email address
- Name (optional)
- Journal entries and associated data (mood indicators, tags)
- App preferences and settings

### Automatically Collected Information
- Device information (model, operating system)
- App usage statistics
- Crash reports

## How We Use Your Information

We use the information we collect to:
- Provide, maintain, and improve the app
- Create and maintain your account
- Store your journal entries
- Send notifications (if enabled)
- Analyze app usage to improve user experience

## Data Storage and Security

Your journal entries are stored securely and are only accessible by you through your authenticated account. We implement appropriate technical and organizational measures to protect your personal information.

## Your Rights

You have the right to:
- Access your personal information
- Correct inaccurate information
- Delete your account and associated data
- Export your journal entries

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

## Contact Us

If you have any questions about this Privacy Policy, please contact us at support@reflectapp.com.
"""

let termsOfServiceText = """
# Terms of Service

Last Updated: April 16, 2025

Please read these Terms of Service ("Terms") carefully before using the Reflect mobile application.

## Acceptance of Terms

By accessing or using our app, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access the app.

## User Accounts

To use certain features of the app, you must create an account. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.

## User Content

You retain all rights to the journal entries and other content you create within the app. By using our app, you grant us a non-exclusive license to host and store your content solely for the purpose of providing the service to you.

## Prohibited Activities

You agree not to:
- Use the app for any illegal purpose
- Attempt to gain unauthorized access to other user accounts
- Interfere with the proper functioning of the app
- Distribute malware or other harmful code

## Termination

We may terminate or suspend your account at any time, without prior notice or liability, for any reason, including, without limitation, if you breach these Terms.

## Disclaimer of Warranties

The app is provided "as is" and "as available" without any warranties of any kind, either express or implied.

## Limitation of Liability

In no event shall Reflect be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, or other intangible losses.

## Changes to Terms

We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days' notice prior to any new terms taking effect.

## Contact Us

If you have any questions about these Terms, please contact us at support@reflectapp.com.
"""

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppState())
    }
}
