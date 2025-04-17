//
//  FirebaseAuthService.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import Foundation
import Combine
import Firebase
import FirebaseAuth

/// Implementation of the AuthService protocol using Firebase Authentication
class FirebaseAuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    
    private var authStateSubscription: AuthStateDidChangeListenerHandle?
    private var authStatePublisher = PassthroughSubject<User?, Never>()
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let authStateSubscription = authStateSubscription {
            Auth.auth().removeStateDidChangeListener(authStateSubscription)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        authStateSubscription = Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                let appUser = self.mapFirebaseUserToAppUser(firebaseUser)
                self.authStatePublisher.send(appUser)
            } else {
                self.authStatePublisher.send(nil)
            }
        }
    }
    
    private func mapFirebaseUserToAppUser(_ firebaseUser: FirebaseAuth.User) -> User {
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "",
            journalingGoals: "", // These fields aren't stored in Firebase Auth
            notificationsEnabled: true,
            reminderTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            useBiometricAuth: false,
            prefersDarkMode: false
        )
    }
    
    // MARK: - AuthServiceProtocol Implementation
    
    func login(email: String, password: String) -> AnyPublisher<User, AuthError> {
        return Future<User, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    let authError = self.mapFirebaseErrorToAuthError(error)
                    promise(.failure(authError))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    promise(.failure(.unknown))
                    return
                }
                
                let appUser = self.mapFirebaseUserToAppUser(firebaseUser)
                promise(.success(appUser))
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
                    let authError = self.mapFirebaseErrorToAuthError(error)
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
                    
                    // Return the user regardless of profile update success
                    // (name will be updated when auth state changes if profile update succeeds)
                    let appUser = self.mapFirebaseUserToAppUser(firebaseUser)
                    promise(.success(appUser))
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
                    let authError = self.mapFirebaseErrorToAuthError(error)
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
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        return mapFirebaseUserToAppUser(firebaseUser)
    }
    
    // MARK: - Helper Methods
    
    private func mapFirebaseErrorToAuthError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        let errorCode = AuthErrorCode(_bridgedNSError: nsError)?.code
        
        switch errorCode {
        case .wrongPassword, .userNotFound, .invalidEmail:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .userAlreadyExists
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknown
        }
    }
}

// MARK: - Auth State Publisher Extension

extension FirebaseAuthService {
    /// Returns a publisher that emits the current user when auth state changes
    func authStateChanges() -> AnyPublisher<User?, Never> {
        return authStatePublisher.eraseToAnyPublisher()
    }
}
