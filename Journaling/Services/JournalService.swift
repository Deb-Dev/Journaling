// 
//  JournalService.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import Foundation
import Combine

enum JournalError: Error, LocalizedError {
    case unauthorized
    case networkError
    case notFound
    case unknown
    case decodingError
    case databaseError(String)
    case invalidData(String)
    
    var message: String {
        switch self {
        case .unauthorized:
            return "You need to be logged in to perform this action."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .notFound:
            return "The requested journal entry could not be found."
        case .decodingError:
            return "There was an error processing the data. Please try again."
        case .databaseError(let details):
            return "Database error: \(details)"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .unknown:
            return "An unknown error occurred. Please try again later."
        }
    }
    
    var errorDescription: String? {
        return message
    }
}

protocol JournalServiceProtocol {
    func fetchEntries(forUserId userId: String) -> AnyPublisher<[JournalEntry], JournalError>
    func fetchEntry(withId id: String) -> AnyPublisher<JournalEntry, JournalError>
    func createEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError>
    func updateEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError>
    func deleteEntry(withId id: String) -> AnyPublisher<Void, JournalError>
}

/// Mock implementation of JournalService for testing and development
class MockJournalService: JournalServiceProtocol {
    // Local storage for mock data
    private var entries: [JournalEntry] = []
    
    init(mockEntries: [JournalEntry] = []) {
        self.entries = mockEntries
        
        // If no mock entries were provided, create some sample data
        if mockEntries.isEmpty {
            createSampleEntries()
        }
    }
    
    private func createSampleEntries() {
        let userId = "mock-user-id"
        let calendar = Calendar.current
        let today = Date()
        
        // Create a variety of entries over the past two weeks
        for day in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Not every day has an entry
                if day % 2 == 0 || arc4random_uniform(2) == 1 {
                    let entry = JournalEntry(
                        id: nil, userId: userId,
                        content: "Sample journal entry for \(dateFormatter.string(from: date)). This is what a longer journal entry might look like with several sentences of content. It could include thoughts, feelings, and reflections on the day.",
                        createdAt: date,
                        updatedAt: date,
                        mood: Mood.allCases.randomElement() ?? .neutral,
                        tags: getRandomTags()
                    )
                    entries.append(entry)
                }
            }
        }
    }
    
    private func getRandomTags() -> [String] {
        let allTags = ["work", "family", "health", "gratitude", "ideas", "goals", "reflection", "learning"]
        let count = Int(arc4random_uniform(4)) // 0-3 tags
        return Array(allTags.shuffled().prefix(count))
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    func fetchEntries(forUserId userId: String) -> AnyPublisher<[JournalEntry], JournalError> {
        return Future<[JournalEntry], JournalError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let userEntries = self.entries.filter { $0.userId == userId }
                promise(.success(userEntries.sorted(by: { $0.createdAt > $1.createdAt })))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEntry(withId id: String) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let entry = self.entries.first(where: { $0.id == id }) {
                    promise(.success(entry))
                } else {
                    promise(.failure(.notFound))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var newEntry = entry
                newEntry.id = UUID().uuidString
                self.entries.append(newEntry)
                promise(.success(newEntry))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateEntry(entry: JournalEntry) -> AnyPublisher<JournalEntry, JournalError> {
        return Future<JournalEntry, JournalError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    var updatedEntry = entry
                    updatedEntry.updatedAt = Date()
                    self.entries[index] = updatedEntry
                    promise(.success(updatedEntry))
                } else {
                    promise(.failure(.notFound))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEntry(withId id: String) -> AnyPublisher<Void, JournalError> {
        return Future<Void, JournalError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let index = self.entries.firstIndex(where: { $0.id == id }) {
                    self.entries.remove(at: index)
                    promise(.success(()))
                } else {
                    promise(.failure(.notFound))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
