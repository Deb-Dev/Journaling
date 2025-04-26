//
//  Publisher+Extensions.swift
//  Journaling
//
//  Created on 2025-04-21.
//

import Foundation
import Combine

extension Publisher {
    /// Safely handles memory management in sink operations by using weak reference to self
    /// - Parameters:
    ///   - weakSelf: The weak reference to capture
    ///   - receiveCompletion: The completion handler
    ///   - receiveValue: The value handler
    /// - Returns: A cancellable subscription
    func sink<T: AnyObject>(
        weakly weakSelf: T,
        receiveCompletion: @escaping ((T, Subscribers.Completion<Self.Failure>) -> Void),
        receiveValue: @escaping ((T, Self.Output) -> Void)
    ) -> AnyCancellable {
        return sink(
            receiveCompletion: { [weak weakSelf] completion in
                guard let strongSelf = weakSelf else { return }
                receiveCompletion(strongSelf, completion)
            },
            receiveValue: { [weak weakSelf] value in
                guard let strongSelf = weakSelf else { return }
                receiveValue(strongSelf, value)
            }
        )
    }
}
