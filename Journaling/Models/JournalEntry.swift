// 
//  JournalEntry.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import Foundation
import FirebaseFirestore

enum Mood: String, CaseIterable, Codable, Identifiable {
    case happy
    case content
    case neutral
    case sad
    case anxious
    case angry
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .content: return "😌"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .anxious: return "😰"
        case .angry: return "😡"
        }
    }
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .content: return "Content"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .angry: return "Angry"
        }
    }
}

struct JournalEntry: Codable, Identifiable {
    @DocumentID var id: String?
    
    var userId: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var mood: Mood
    var tags: [String]
    var isFavorite: Bool = false
    
    init(id: String?,
         userId: String,
         content: String = "",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         mood: Mood = .neutral,
         tags: [String] = [],
         isFavorite: Bool = false)
    {
        self.id = id
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mood = mood
        self.tags = tags
        self.isFavorite = isFavorite
    }
}

// Extension to group entries by date for the calendar view
extension Array where Element == JournalEntry {
    func groupByDate() -> [Date: [JournalEntry]] {
        let calendar = Calendar.current
        var groupedEntries: [Date: [JournalEntry]] = [:]
        
        for entry in self {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: entry.createdAt)
            if let date = calendar.date(from: dateComponents) {
                if groupedEntries[date] != nil {
                    groupedEntries[date]?.append(entry)
                } else {
                    groupedEntries[date] = [entry]
                }
            }
        }
        
        return groupedEntries
    }
}
