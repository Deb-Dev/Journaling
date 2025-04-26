//
//  Firestore+Combine.swift
//  Journaling
//
//  Created on 2025-04-21.
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - Firestore Combine Extensions

extension Query {
    /// Gets documents with retry mechanism
    /// - Parameter maxRetries: Maximum number of retries (default: 2)
    /// - Returns: Publisher that emits QuerySnapshot or error
    func getDocumentsPublisher(maxRetries: Int = 2) -> AnyPublisher<QuerySnapshot, Error> {
        return Future<QuerySnapshot, Error> { promise in
            self.getDocuments { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                } else if let snapshot = snapshot {
                    promise(.success(snapshot))
                } else {
                    promise(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                }
            }
        }
        .retry(maxRetries)
        .eraseToAnyPublisher()
    }
}

extension DocumentReference {
    /// Gets document with retry mechanism
    /// - Parameter maxRetries: Maximum number of retries (default: 2)
    /// - Returns: Publisher that emits DocumentSnapshot or error
    func getDocumentPublisher(maxRetries: Int = 2) -> AnyPublisher<DocumentSnapshot, Error> {
        return Future<DocumentSnapshot, Error> { promise in
            self.getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                } else if let snapshot = snapshot {
                    promise(.success(snapshot))
                } else {
                    promise(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                }
            }
        }
        .retry(maxRetries)
        .eraseToAnyPublisher()
    }
    
    /// Sets document data with retry mechanism
    /// - Parameters:
    ///   - data: Document data
    ///   - maxRetries: Maximum number of retries (default: 2)
    /// - Returns: Publisher that completes or emits error
    func setDataPublisher(_ data: [String: Any], maxRetries: Int = 2) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            self.setData(data) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .retry(maxRetries)
        .eraseToAnyPublisher()
    }
    
    /// Updates document with retry mechanism
    /// - Parameters:
    ///   - data: Fields to update
    ///   - maxRetries: Maximum number of retries (default: 2)
    /// - Returns: Publisher that completes or emits error
    func updateDataPublisher(_ data: [String: Any], maxRetries: Int = 2) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            self.updateData(data) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .retry(maxRetries)
        .eraseToAnyPublisher()
    }
    
    /// Deletes document with retry mechanism
    /// - Parameter maxRetries: Maximum number of retries (default: 2)
    /// - Returns: Publisher that completes or emits error
    func deleteDocumentPublisher(maxRetries: Int = 2) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            self.delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .retry(maxRetries)
        .eraseToAnyPublisher()
    }
}
