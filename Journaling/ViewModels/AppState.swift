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
import FirebaseAuth
import UserNotifications

/// Main state container for the app
class AppState: ObservableObject {
    // Dependencies
    private let authService: AuthServiceProtocol
    private let journalService: JournalServiceProtocol
    
    // Navigation router
    @Published var router = NavigationRouter()
    
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
        
        // Check if onboarding has been completed
        isOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print("Is onboarding needed: \(isOnboarding), UserDefaults value: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
        
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
                    
                    // If user is logged in, restore their notification settings
                    if let user = user, user.notificationsEnabled {
                        self.restoreNotificationSettings(user: user)
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
        
        // Update both locally and in Firestore
        return updateUserInFirestore(updatedUser)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.currentUser = updatedUser
            })
            .eraseToAnyPublisher()
    }
    
    /// Updates user data in Firestore
    private func updateUserInFirestore(_ user: User) -> AnyPublisher<Void, JournalError> {
//        guard let userId = user.id else {
//            return Fail(error: JournalError.unauthorized).eraseToAnyPublisher()
//        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        do {
            let userData = try user.asDictionary()
            
            return userRef.setDataPublisher(userData)
                .mapError { error -> JournalError in
                    print("Error updating user profile: \(error.localizedDescription)")
                    return .databaseError(error.localizedDescription)
                }
                .map { _ in () }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: JournalError.invalidData(error.localizedDescription))
                .eraseToAnyPublisher()
        }
    }
    
    func completeOnboarding() {
        isOnboarding = false
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize() // Force synchronize to ensure value is saved
        print("Onboarding completed. UserDefaults value set to: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
    }
    
    // MARK: - Settings Methods
    
    func updateNotificationPreferences(enabled: Bool, reminderTime: Date) {
        guard var user = currentUser else { return }
        user.notificationsEnabled = enabled
        user.reminderTime = reminderTime
        
        // Update user locally first for responsive UI
        currentUser = user
        
        // Persist changes to Firestore
        updateUserInFirestore(user)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error updating notification preferences: \(error.message)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Schedule or cancel notifications based on user preference
        if enabled {
            scheduleJournalReminder(at: reminderTime)
        } else {
            cancelAllNotifications()
        }
    }
    
    func updateThemePreference(darkMode: Bool) {
        guard var user = currentUser else { return }
        user.prefersDarkMode = darkMode
        
        // Update local state
        currentUser = user
        
        // Persist to Firestore
        updateUserInFirestore(user)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error updating theme preference: \(error.message)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func updateBiometricAuthPreference(enabled: Bool) {
        guard var user = currentUser else { return }
        user.useBiometricAuth = enabled
        
        // Update local state
        currentUser = user
        
        // Persist to Firestore
        updateUserInFirestore(user)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error updating biometric auth preference: \(error.message)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// Restores notification settings when the app is launched or user logs in
    private func restoreNotificationSettings(user: User) {
        if user.notificationsEnabled {
            print("Restoring notification at time: \(user.reminderTime)")
            scheduleJournalReminder(at: user.reminderTime)
        } else {
            cancelAllNotifications()
        }
    }
    
    /// Schedules a daily journal reminder notification at the specified time
    private func scheduleJournalReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        
        // First, clear existing notifications to avoid duplicates
        center.removeAllPendingNotificationRequests()
        
        // Request notification permission if not already granted
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if !granted {
                print("Notification permission denied")
                return
            }
            
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Journaling Reminder".localized
            content.body = "Take a moment to reflect on your day by writing in your journal.".localized
            content.sound = .default
            content.badge = 1
            
            // Extract hour and minute from the reminder time
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            
            // Create a daily trigger at the specified time
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: "journalReminder",
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Successfully scheduled notification for \(hour):\(minute)")
                    
                    // For debugging: List all pending notifications
                    center.getPendingNotificationRequests { requests in
                        print("Pending notifications: \(requests.count)")
                        for request in requests {
                            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                                print("Notification scheduled at: \(trigger.dateComponents)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Cancels all pending notifications
    private func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
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
