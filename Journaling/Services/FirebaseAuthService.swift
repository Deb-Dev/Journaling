// 
//  FirebaseAuthService.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Implementation of AuthServiceProtocol using Firebase Authentication
class FirebaseAuthService: AuthServiceProtocol {
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let authStateSubject = PassthroughSubject<User?, Never>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        // Clean up auth state listener to prevent memory leaks
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication State Handling
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                // User is signed in
                let basicUser = self.createBasicUser(from: firebaseUser)
                self.fetchUserFromFirestore(firebaseUser.uid, basicUser: basicUser)
            } else {
                // User is signed out
                self.authStateSubject.send(nil)
            }
        }
    }
    
    func authStateChanges() -> AnyPublisher<User?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Current User
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        // Check if we already have cached user data with correct preferences
        if let cachedUserData = UserDefaults.standard.data(forKey: "cachedUserData-\(firebaseUser.uid)") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                let cachedUser = try decoder.decode(User.self, from: cachedUserData)
                
                // Still fetch the latest data in background, but return cached data immediately
                fetchUserFromFirestore(firebaseUser.uid, basicUser: cachedUser)
                return cachedUser
            } catch {
                print("Error decoding cached user: \(error.localizedDescription)")
            }
        }
        
        // If no cached data available, create a basic user and return it
        let basicUser = createBasicUser(from: firebaseUser)
        
        // Fetch complete user data from Firestore (this happens asynchronously)
        fetchUserFromFirestore(firebaseUser.uid, basicUser: basicUser)
        
        return basicUser
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) -> AnyPublisher<User, AuthError> {
        return Future<User, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    let authError = self.mapFirebaseError(error)
                    promise(.failure(authError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(.unknown))
                    return
                }
                
                // Create user from Firebase auth data
                let user = self.createBasicUser(from: firebaseUser)
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String, name: String) -> AnyPublisher<User, AuthError> {
        return Future<User, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    let authError = self.mapFirebaseError(error)
                    promise(.failure(authError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(.unknown))
                    return
                }
                
                // Update display name
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error updating display name: \(error.localizedDescription)")
                    }
                    
                    // Even if there's an error updating the display name, we'll create the user
                    // and store the name in Firestore later
                    let user = self.createBasicUser(from: firebaseUser, name: name)
                    
                    // Save user data to Firestore
                    self.saveUserToFirestore(user)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in }
                        )
                        .store(in: &self.cancellables)
                    
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError> {
        return Future<Void, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    let authError = self.mapFirebaseError(error)
                    promise(.failure(authError))
                    return
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                print("Error signing out: \(error.localizedDescription)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Void, AuthError> {
        return Future<Void, AuthError> { [weak self] promise in
            guard let self = self, let user = Auth.auth().currentUser else {
                promise(.failure(.unknown))
                return
            }
            
            // Delete user from Firebase Authentication
            user.delete { error in
                if let error = error {
                    let authError = self.mapFirebaseError(error)
                    promise(.failure(authError))
                    return
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a basic user from Firebase auth data
    private func createBasicUser(from firebaseUser: FirebaseAuth.User, name: String? = nil) -> User {
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: name ?? firebaseUser.displayName ?? "",
            journalingGoals: "",
            notificationsEnabled: true,
            reminderTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            useBiometricAuth: false,
            prefersDarkMode: false
        )
    }
    
    /// Saves user data to Firestore
    private func saveUserToFirestore(_ user: User) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.id)
            
            do {
                // Convert User struct to dictionary
                var userData = try user.asDictionary()
                
                // Convert Date to Firestore Timestamp for proper storage
                if let reminderTime = userData["reminderTime"] as? Date {
                    userData["reminderTime"] = Timestamp(date: reminderTime)
                }
                
                userRef.setData(userData, merge: true) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetches complete user data from Firestore and updates the auth state
    private func fetchUserFromFirestore(_ userId: String, basicUser: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                // Still publish the basic user data if there's an error
                self.authStateSubject.send(basicUser)
                return
            }
            
            if let document = document, document.exists {
                // Document exists, parse the data
                if let data = document.data() {
                    // Convert Firestore timestamp to Date for reminderTime field
                    var reminderTime = basicUser.reminderTime
                    
                    // Handle reminderTime conversion from various possible types
                    if let reminderObj = data["reminderTime"] {
                        print("DEBUG: reminderTime found in Firestore with type: \(type(of: reminderObj))")
                        
                        if let reminderTimestamp = reminderObj as? Timestamp {
                            // Handle Firestore Timestamp type
                            print("DEBUG: Successfully cast to Timestamp")
                            reminderTime = reminderTimestamp.dateValue()
                            print("DEBUG: Converted Timestamp to Date: \(reminderTime)")
                        } else if let millisecondsSince1970 = reminderObj as? NSNumber {
                            // Handle case where reminderTime is stored as a number (milliseconds since 1970)
                            let timeInterval = TimeInterval(millisecondsSince1970.doubleValue / 1000)
                            reminderTime = Date(timeIntervalSince1970: timeInterval)
                            print("DEBUG: Converted NSNumber to Date: \(reminderTime)")
                        } else if let secondsSince1970 = reminderObj as? Int {
                            // Handle case where reminderTime is stored as Int seconds
                            reminderTime = Date(timeIntervalSince1970: TimeInterval(secondsSince1970))
                            print("DEBUG: Converted Int seconds to Date: \(reminderTime)")
                        } else {
                            print("DEBUG: Failed to convert reminderTime - unknown type: \(type(of: reminderObj))")
                        }
                    } else {
                        print("DEBUG: No reminderTime field found in Firestore document")
                    }
                    
                    // Create a user with complete data from Firestore
                    let user = User(
                        id: userId,
                        email: basicUser.email,
                        name: data["name"] as? String ?? basicUser.name,
                        journalingGoals: data["journalingGoals"] as? String ?? "",
                        notificationsEnabled: data["notificationsEnabled"] as? Bool ?? false,
                        reminderTime: reminderTime,
                        useBiometricAuth: data["useBiometricAuth"] as? Bool ?? false,
                        prefersDarkMode: data["prefersDarkMode"] as? Bool ?? false
                    )
                    
                    // Cache the user data locally for faster retrieval on next app launch
                    self.cacheUserData(user)
                    
                    // Send the complete user data
                    self.authStateSubject.send(user)
                    print("Loaded user from Firestore - notifications: \(user.notificationsEnabled), time: \(user.reminderTime)")
                } else {
                    // Document exists but is empty, send the basic user
                    self.authStateSubject.send(basicUser)
                }
            } else {
                // Document doesn't exist, create it with basic user data
                self.saveUserToFirestore(basicUser)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Error creating user document: \(error.localizedDescription)")
                            }
                        },
                        receiveValue: { _ in
                            print("Created new user document in Firestore")
                        }
                    )
                    .store(in: &self.cancellables)
                
                // Send the basic user data
                self.authStateSubject.send(basicUser)
            }
        }
    }
    
    /// Caches user data locally for faster retrieval on next app launch
    private func cacheUserData(_ user: User) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let userData = try encoder.encode(user)
            UserDefaults.standard.set(userData, forKey: "cachedUserData-\(user.id)")
            print("User data cached successfully with reminderTime: \(user.reminderTime)")
        } catch {
            print("Error caching user data: \(error.localizedDescription)")
        }
    }
    
    /// Maps Firebase Auth errors to our app's AuthError type
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidEmail.rawValue:
            return .invalidCredentials
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .userAlreadyExists
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return .unknown
        default:
            print("Unmapped Firebase error: \(nsError.code) - \(error.localizedDescription)")
            return .unknown
        }
    }
}
