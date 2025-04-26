// filepath: /Users/debchow/Documents/coco/Journaling/Journaling/Services/FirestoreJournalService.swift
// 
//  FirestoreJournalService.swift
//  Journaling
//
//  Created on 2025-04-17.
//

import Foundation
import Combine
import FirebaseFirestore

/// A service that handles journal entry operations using Firebase Firestore
final class FirestoreJournalService: JournalServiceProtocol {
    
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Helpers
    
    /// Helper method to get the journal entries collection reference
    private func entriesCollection() -> CollectionReference {
        return db.collection("journalEntries")
    }
    
    /// Helper method to get a document reference for a specific entry
    private func documentReference(for entryId: String) -> DocumentReference {
        return entriesCollection().document(entryId)
    }
    
    deinit {
        // Remove all active listeners when the service is deallocated
        removeAllListeners()
    }
    
    private func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - JournalServiceProtocol Implementation
    
    func fetchEntries(forUserId userId: String) -> AnyPublisher<[JournalEntry], JournalError> {
        // Use non-realtime fetch with retry capability
        return entriesCollection()
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocumentsPublisher(maxRetries: 2)
            .mapError { error -> JournalError in
                print("Error fetching entries: \(error.localizedDescription)")
                return .databaseError(error.localizedDescription)
            }
            .flatMap { (snapshot) -> AnyPublisher<[JournalEntry], JournalError> in
                do {
                    let entries = try snapshot.documents.compactMap { document -> JournalEntry? in
                        try document.data(as: JournalEntry.self)
                    }
                    return Just(entries)
                        .setFailureType(to: JournalError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("Error decoding entries: \(error.localizedDescription)")
                    return Fail(error: .decodingError)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetches entries with realtime updates
    func observeEntries(forUserId userId: String) -> AnyPublisher<[JournalEntry], JournalError> {
        return Future<[JournalEntry], JournalError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            // Remove previous listener if exists
            if let existingListener = self.listeners["entries-\(userId)"] {
                existingListener.remove()
            }
            
            // Create and store new listener
            let listener = self.entriesCollection()
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        print("Error fetching entries: \(error.localizedDescription)")
                        promise(.failure(.databaseError(error.localizedDescription)))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    do {
                        let entries = try documents.compactMap { document -> JournalEntry? in
                            try document.data(as: JournalEntry.self)
                        }
                        promise(.success(entries))
                    } catch {
                        print("Error decoding entries: \(error.localizedDescription)")
                        promise(.failure(.decodingError))
                    }
                }
            
            self.listeners["entries-\(userId)"] = listener
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEntry(withId id: String) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            let docRef = self.documentReference(for: id)
            
            docRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching entry: \(error.localizedDescription)")
                    promise(.failure(.databaseError(error.localizedDescription)))
                    return
                }
                
                guard let document = document, document.exists else {
                    promise(.failure(.notFound))
                    return
                }
                
                do {
                    let entry = try document.data(as: JournalEntry.self)
                    promise(.success(entry))
                } catch {
                    print("Error decoding entry: \(error.localizedDescription)")
                    promise(.failure(.decodingError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            do {
                // If entry has an empty ID, generate a new one
                var newEntry = entry
                if newEntry.id?.isEmpty ?? true {
                    newEntry.id = UUID().uuidString
                }
                
                try self.documentReference(for: newEntry.id ?? "").setData(from: newEntry) { error in
                    if let error = error {
                        print("Error creating entry: \(error.localizedDescription)")
                        promise(.failure(.databaseError(error.localizedDescription)))
                    } else {
                        promise(.success(newEntry))
                    }
                }
            } catch {
                print("Error encoding entry: \(error.localizedDescription)")
                promise(.failure(.decodingError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            guard let id = entry.id, !id.isEmpty else {
                promise(.failure(.invalidData("Entry ID is empty")))
                return
            }
            
            do {
                try self.documentReference(for: entry.id ?? "").setData(from: entry, merge: true) { error in
                    if let error = error {
                        print("Error updating entry: \(error.localizedDescription)")
                        promise(.failure(.databaseError(error.localizedDescription)))
                    } else {
                        promise(.success(entry))
                    }
                }
            } catch {
                print("Error encoding entry: \(error.localizedDescription)")
                promise(.failure(.decodingError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEntry(withId id: String) -> AnyPublisher<Void, JournalError> {
        return Future<Void, JournalError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            self.documentReference(for: id).delete { error in
                if let error = error {
                    print("Error deleting entry: \(error.localizedDescription)")
                    promise(.failure(.databaseError(error.localizedDescription)))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
