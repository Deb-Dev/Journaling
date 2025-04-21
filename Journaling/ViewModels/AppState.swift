// 
//  AppState.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

/// Main state container for the app
class AppState: ObservableObject {
    // Dependencies
    private let authService: AuthServiceProtocol
    private let journalService: JournalServiceProtocol
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Authentication state
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isOnboarding: Bool = true
    
    init(authService: AuthServiceProtocol = FirebaseAuthService(),
         journalService: JournalServiceProtocol = FirestoreJournalService()) {
        self.authService = authService
        self.journalService = journalService
        
        // Check if user is already logged in
        currentUser = authService.getCurrentUser()
        isAuthenticated = currentUser != nil
        
        // For demo purpose - set this to false to skip onboarding
        // In real app, we would check if this is first launch
        isOnboarding = UserDefaults.standard.object(forKey: "hasCompletedOnboarding") == nil
        
        // Subscribe to authentication state changes
        if let firebaseAuthService = authService as? FirebaseAuthService {
            firebaseAuthService.authStateChanges()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] user in
                    guard let self = self else { return }
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                    
                    // If this is a new user, show onboarding
                    if user != nil && user?.journalingGoals.isEmpty ?? true {
                        self.isOnboarding = true
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) -> AnyPublisher<Void, AuthError> {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String, name: String) -> AnyPublisher<Void, AuthError> {
        authService.signup(email: email, password: password, name: name)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
                self?.isOnboarding = true // Show personalization flow
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError> {
        authService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func logout() {
        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Onboarding Methods
    
    func updateUserProfile(name: String, journalingGoals: String) -> AnyPublisher<Void, JournalError> {
        guard var updatedUser = currentUser else {
            return Fail(error: JournalError.unauthorized).eraseToAnyPublisher()
        }
        
        updatedUser.name = name
        updatedUser.journalingGoals = journalingGoals
        
        // In a real app, we would call an API to update the user profile
        // For demo, we'll just update the local state
        return Future<Void, JournalError> { [weak self] promise in
            DispatchQueue.main.async {
                self?.currentUser = updatedUser
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func completeOnboarding() {
        isOnboarding = false
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Settings Methods
    
    func updateNotificationPreferences(enabled: Bool, reminderTime: Date) {
        guard var user = currentUser else { return }
        user.notificationsEnabled = enabled
        user.reminderTime = reminderTime
        currentUser = user
        
        // In a real app, save to backend and update local notifications
    }
    
    func updateThemePreference(darkMode: Bool) {
        guard var user = currentUser else { return }
        user.prefersDarkMode = darkMode
        currentUser = user
    }
    
    func updateBiometricAuthPreference(enabled: Bool) {
        guard var user = currentUser else { return }
        user.useBiometricAuth = enabled
        currentUser = user
    }
}

// MARK: - Journal Entry Methods Extension
extension AppState {
    func fetchEntries() -> AnyPublisher<[JournalEntry], JournalError> {
        guard let userId = currentUser?.id else {
            return Fail(error: JournalError.unauthorized).eraseToAnyPublisher()
        }
        
        return journalService.fetchEntries(forUserId: userId)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchEntry(withId id: String) -> AnyPublisher<JournalEntry, JournalError> {
        journalService.fetchEntry(withId: id)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func createEntry(content: String, mood: Mood, tags: [String]) -> AnyPublisher<JournalEntry, JournalError> {
        guard let userId = currentUser?.id else {
            return Fail(error: JournalError.unauthorized).eraseToAnyPublisher()
        }
        
        let entry = JournalEntry(
            id: nil, userId: userId,
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            mood: mood,
            tags: tags
        )
        
        return journalService.createEntry(entry: entry)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError> {
        var updatedEntry = entry
        updatedEntry.updatedAt = Date()
        
        return journalService.updateEntry(entry: updatedEntry)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func deleteEntry(withId id: String) -> AnyPublisher<Void, JournalError> {
        journalService.deleteEntry(withId: id)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
