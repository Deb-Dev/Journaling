// filepath: /Users/debchow/Documents/coco/Journaling/Journaling/Utilities/String+Localization.swift
//
//  String+Localization.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
