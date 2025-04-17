// 
//  User.swift
//  Journaling
//
//  Created on 2025-04-15.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String
    var email: String
    var name: String
    var journalingGoals: String
    var notificationsEnabled: Bool
    var reminderTime: Date
    var useBiometricAuth: Bool
    var prefersDarkMode: Bool
    
    init(id: String = UUID().uuidString,
         email: String = "",
         name: String = "",
         journalingGoals: String = "",
         notificationsEnabled: Bool = true,
         reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
         useBiometricAuth: Bool = false,
         prefersDarkMode: Bool = false) {
        self.id = id
        self.email = email
        self.name = name
        self.journalingGoals = journalingGoals
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.useBiometricAuth = useBiometricAuth
        self.prefersDarkMode = prefersDarkMode
    }
}
