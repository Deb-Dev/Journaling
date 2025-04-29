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
                            Text("profile.goals.header".localized) // Updated key
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

                                Text("settings.title".localized) // Updated key
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

                                Text("profile.logout.button".localized) // Updated key
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
            .navigationTitle("profile.title".localized) // Updated key
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
                Text("profile.edit.button".localized)
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
                Section(header: Text("profile.personalInfo.header".localized)) { // Updated key
                    TextField("profile.name.placeholder".localized, text: $name) // Updated key
                }

                Section(header: Text("profile.goals.header".localized)) { // Updated key
                    TextEditor(text: $journalingGoals)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("profile.edit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.save".localized) {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("general.error.title".localized),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("general.ok".localized)) {
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
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("settings.notifications.header".localized)) {
                Toggle("settings.notifications.enable.toggle".localized, isOn: $viewModel.notificationsEnabled)
                
                if viewModel.notificationsEnabled {
                    DatePicker("settings.notifications.time.label".localized, 
                              selection: $viewModel.reminderTime, 
                              displayedComponents: .hourAndMinute)
                }
            }

            Section(header: Text("settings.appearance.header".localized)) {
                Toggle("settings.appearance.theme.dark".localized, isOn: $viewModel.prefersDarkMode)
            }

            Section(header: Text("settings.security.header".localized)) {
                Toggle("settings.security.biometrics.toggle".localized, isOn: $viewModel.useBiometricAuth)
            }

            Section(header: Text("settings.legal.header".localized)) {
                NavigationLink(destination: LegalDocumentView(title: "settings.legal.privacyPolicy".localized, content: privacyPolicyText)) {
                    Text("settings.legal.privacyPolicy".localized)
                }

                NavigationLink(destination: LegalDocumentView(title: "settings.legal.termsOfService".localized, content: termsOfServiceText)) {
                    Text("settings.legal.termsOfService".localized)
                }
            }

            Section(header: Text("settings.account.header".localized)) {
                Button(action: { viewModel.showDeleteAccountConfirmation = true }) {
                    Text("settings.account.delete.button".localized)
                        .foregroundColor(.red)
                }
            }

            Section(header: Text("settings.about.header".localized)) {
                HStack {
                    Text("settings.about.version".localized)
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("settings.title".localized)
        .environmentObject(appState)
        .onAppear {
            viewModel.initialize(with: appState)
        }
        .alert(isPresented: $viewModel.showDeleteAccountConfirmation) {
            Alert(
                title: Text("settings.account.delete.confirmation.title".localized),
                message: Text("settings.account.delete.confirmation.message".localized),
                primaryButton: .destructive(Text("settings.account.delete.confirmation.confirm".localized)) {
                    viewModel.deleteAccount()
                },
                secondaryButton: .cancel(Text("general.cancel".localized))
            )
        }
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
        .navigationTitle(title.localized) // Localize the title passed in
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

// Helper to get app version
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
}
