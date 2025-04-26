//
//  AppStateTests.swift
//  JournalingTests
//
//  Created on 2025-04-21.
//

import XCTest
import Combine
@testable import Journaling

final class AppStateTests: XCTestCase {
    var appState: AppState!
    var mockAuthService: MockAuthService!
    var mockJournalService: MockJournalService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockJournalService = MockJournalService()
        appState = AppState(authService: mockAuthService, journalService: mockJournalService)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        appState = nil
        mockAuthService = nil
        mockJournalService = nil
        super.tearDown()
    }
    
    func testFetchEntriesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch entries successfully")
        
        // Set up mock data that the service will return
        let mockEntries = [
            JournalEntry(id: "1", userId: "user1", content: "Test entry 1"),
            JournalEntry(id: "2", userId: "user1", content: "Test entry 2")
        ]
        mockJournalService.mockEntries = mockEntries
        
        // When
        appState.fetchEntries()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { entries in
                    // Then
                    XCTAssertEqual(entries.count, 2)
                    XCTAssertEqual(entries[0].id, "1")
                    XCTAssertEqual(entries[1].id, "2")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateEntrySuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Create entry successfully")
        let newEntry = JournalEntry(userId: "user1", content: "New test entry")
        
        // When
        appState.createEntry(newEntry)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { entry in
                    // Then
                    XCTAssertNotNil(entry.id)
                    XCTAssertEqual(entry.content, "New test entry")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteEntrySuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Delete entry successfully")
        
        // When
        appState.deleteEntry(withId: "test-id")
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
