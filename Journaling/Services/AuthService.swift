// 
//  AuthService.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import Foundation
import Combine

enum AuthError: Error {
    case invalidCredentials
    case networkError
    case userAlreadyExists
    case weakPassword
    case unknown
    
    var message: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 8 characters with numbers and special characters."
        case .unknown:
            return "An unknown error occurred. Please try again later."
        }
    }
}

protocol AuthServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, AuthError>
    func signup(email: String, password: String, name: String) -> AnyPublisher<User, AuthError>
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError>
    func logout() -> AnyPublisher<Void, Never>
    func getCurrentUser() -> User?
}

/// Mock implementation of AuthService for testing and development
class MockAuthService: AuthServiceProtocol {
    private var mockUser: User?
    
    init(preAuthenticatedUser: User? = nil) {
        self.mockUser = preAuthenticatedUser
    }
    
    func login(email: String, password: String) -> AnyPublisher<User, AuthError> {
        // Simulate network delay
        return Future<User, AuthError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Basic validation
                guard !email.isEmpty, !password.isEmpty else {
                    promise(.failure(.invalidCredentials))
                    return
                }
                
                // Simple mock authentication logic
                if email == "test@example.com" && password == "password123" {
                    let user = User(
                        id: "mock-user-id",
                        email: email,
                        name: "Test User",
                        journalingGoals: "Write daily for reflection",
                        notificationsEnabled: true,
                        reminderTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                        useBiometricAuth: false,
                        prefersDarkMode: false
                    )
                    self.mockUser = user
                    promise(.success(user))
                } else {
                    promise(.failure(.invalidCredentials))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String, name: String) -> AnyPublisher<User, AuthError> {
        return Future<User, AuthError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Basic validation
                guard !email.isEmpty, !name.isEmpty else {
                    promise(.failure(.invalidCredentials))
                    return
                }
                
                if password.count < 8 {
                    promise(.failure(.weakPassword))
                    return
                }
                
                // For testing, we'll consider "used@example.com" as already taken
                if email == "used@example.com" {
                    promise(.failure(.userAlreadyExists))
                    return
                }
                
                // Success case
                let user = User(
                    id: "mock-user-id",
                    email: email,
                    name: name,
                    journalingGoals: "",
                    notificationsEnabled: true,
                    reminderTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                    useBiometricAuth: false,
                    prefersDarkMode: false
                )
                self.mockUser = user
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError> {
        return Future<Void, AuthError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Basic validation
                guard !email.isEmpty else {
                    promise(.failure(.invalidCredentials))
                    return
                }
                
                // For testing purposes, any valid email is accepted
                if email.contains("@") && email.contains(".") {
                    promise(.success(()))
                } else {
                    promise(.failure(.invalidCredentials))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mockUser = nil
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User? {
        return mockUser
    }
}
