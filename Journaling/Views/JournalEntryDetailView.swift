//
//  JournalEntryDetailView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

struct JournalEntryDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let entry: JournalEntry
    let onDelete: () -> Void
    let onUpdate: () -> Void
    
    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteAlert = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with date and mood
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.createdAt.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if entry.updatedAt != entry.createdAt {
                            Text("Edited \(entry.updatedAt.relativeTime())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(entry.mood.emoji)
                        .font(.title)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
                .padding(.horizontal)
                
                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Content
                Text(entry.content)
                    .padding(.horizontal)
                    .padding(.bottom, 50)
            }
            .padding(.vertical)
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isShowingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { isShowingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            JournalEntryEditorView(onSave: { _ in
                onUpdate()
            }, existingEntry: entry)
        }
        .alert("Delete Entry", isPresented: $isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                }
            )
        }
    }
    
    private func deleteEntry() {
        isLoading = true
        errorMessage = ""
        
        appState.deleteEntry(withId: entry.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { _ in
                onDelete()
            })
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct JournalEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            JournalEntryDetailView(
                entry: JournalEntry(
                    userId: "mock-user",
                    content: "This is a sample journal entry with multiple paragraphs of content to demonstrate how the detail view displays longer text entries. It might include reflections on the day, personal thoughts, or memorable moments.\n\nThe formatting should handle line breaks and paragraphs properly to make the content readable and pleasant to review.",
                    mood: .content,
                    tags: ["reflection", "gratitude"]
                ),
                onDelete: {},
                onUpdate: {}
            )
            .environmentObject(AppState())
        }
    }
}
