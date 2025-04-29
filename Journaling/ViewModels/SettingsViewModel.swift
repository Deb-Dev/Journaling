// 
//  SettingsViewModel.swift
//  Journaling
//
//  Created on 2025-04-26.
//

import SwiftUI
import Combine
import FirebaseFirestore

class SettingsViewModel: ObservableObject {
    // Published properties that will drive the UI
    @Published var notificationsEnabled: Bool = false
    @Published var reminderTime: Date = Date()
    @Published var useBiometricAuth: Bool = false
    @Published var prefersDarkMode: Bool = false
    @Published var isLoading: Bool = true
    @Published var showDeleteAccountConfirmation: Bool = false
    
    // Private properties
    private var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var userListener: ListenerRegistration?
    
    deinit {
        // Clean up Firestore listener when the view model is deallocated
        userListener?.remove()
    }
    
    /// Initializes the view model with app state and sets up Firestore listener
    func initialize(with appState: AppState) {
        self.appState = appState
        
        // Initialize with current user data
        if let user = appState.currentUser {
            self.notificationsEnabled = user.notificationsEnabled
            self.reminderTime = user.reminderTime
            self.useBiometricAuth = user.useBiometricAuth
            self.prefersDarkMode = user.prefersDarkMode
        }
        
        // Setup Firestore listener for real-time updates
        setupUserListener()
        
        // Setup property observers
        setupObservers()
    }
    
    /// Sets up a Firestore listener for the current user document
    private func setupUserListener() {
        guard let userId = appState?.currentUser?.id else { return }
        
        // Remove existing listener if any
        userListener?.remove()
        
        // Create a new listener
        let db = Firestore.firestore()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print("Error listening for user updates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.isLoading = false
                
                // Only update if the document exists and has data
                guard let data = snapshot.data() else { return }
                
                // Update published properties with data from Firestore
                if let notificationsEnabled = data["notificationsEnabled"] as? Bool {
                    self.notificationsEnabled = notificationsEnabled
                }
                
                if let reminderTimeTimestamp = data["reminderTime"] as? Timestamp {
                    self.reminderTime = reminderTimeTimestamp.dateValue()
                }
                
                if let useBiometricAuth = data["useBiometricAuth"] as? Bool {
                    self.useBiometricAuth = useBiometricAuth
                }
                
                if let prefersDarkMode = data["prefersDarkMode"] as? Bool {
                    self.prefersDarkMode = prefersDarkMode
                }
                
                print("Updated user settings from Firestore: notifications=\(self.notificationsEnabled), time=\(self.reminderTime)")
            }
    }
    
    /// Sets up observers for the published properties to update Firestore when they change
    private func setupObservers() {
        // Observe notifications toggle and time
        $notificationsEnabled
            .dropFirst() // Skip the initial value
            .debounce(for: 0.5, scheduler: RunLoop.main) // Debounce rapid changes
            .sink { [weak self] newValue in
                guard let self = self, let appState = self.appState else { return }
                appState.updateNotificationPreferences(enabled: newValue, reminderTime: self.reminderTime)
            }
            .store(in: &cancellables)
        
        $reminderTime
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self, let appState = self.appState, self.notificationsEnabled else { return }
                appState.updateNotificationPreferences(enabled: self.notificationsEnabled, reminderTime: newValue)
            }
            .store(in: &cancellables)
        
        // Observe theme preference
        $prefersDarkMode
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let appState = self?.appState else { return }
                appState.updateThemePreference(darkMode: newValue)
            }
            .store(in: &cancellables)
        
        // Observe biometric auth preference
        $useBiometricAuth
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let appState = self?.appState else { return }
                appState.updateBiometricAuthPreference(enabled: newValue)
            }
            .store(in: &cancellables)
    }
    
    /// Deletes the user's account
    func deleteAccount() {
        // Implementation will be added in the next phase
        print("Delete account requested")
    }
}
