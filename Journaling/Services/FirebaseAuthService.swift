// filepath: /Users/debchow/Documents/coco/Journaling/Journaling/Services/FirebaseAuthService.swift
//
//  FirebaseAuthService.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine

class FirebaseAuthService: AuthServiceProtocol {
    private var cancellables = Set<AnyCancellable>()
    
    // Subject to emit auth state changes
    private let authStateSubject = PassthroughSubject<User?, Never>()
    
    init() {
        // Listen for authentication state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                // User is signed in
                let user = self.mapFirebaseUser(firebaseUser)
                self.authStateSubject.send(user)
            } else {
                // User is signed out
                self.authStateSubject.send(nil)
            }
        }
    }
    
    // MARK: - Authentication State Changes
    
    func authStateChanges() -> AnyPublisher<User?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Current User
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        return mapFirebaseUser(firebaseUser)
    }
    
    // MARK: - Sign In
    
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
                
                let user = self.mapFirebaseUser(firebaseUser)
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Sign Up
    
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
                    let user = self.mapFirebaseUser(firebaseUser, name: name)
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Reset Password
    
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
    
    // MARK: - Sign Out
    
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
    
    // MARK: - Helper Methods
    
    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User, name: String? = nil) -> User {
        // In a real app, you'd fetch additional user data from Firestore here
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
        default:
            print("Unmapped Firebase error: \(nsError.code) - \(error.localizedDescription)")
            return .unknown
        }
    }
}
