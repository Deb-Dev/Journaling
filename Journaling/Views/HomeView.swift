//
//  HomeView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var entries: [JournalEntry] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isShowingNewEntrySheet = false
    @State private var isShowingEntryDetail = false
    @State private var selectedEntryId: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading && entries.isEmpty {
                    LoadingView()
                } else if entries.isEmpty {
                    EmptyStateView(
                        onCreateEntry: { isShowingNewEntrySheet = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Stats Card
                            StatsCardView(entryCount: entries.count)
                                .padding(.horizontal)
                            
                            // Recent Entries
                            VStack(alignment: .leading) {
                                Text("Recent Entries")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(entries.prefix(5)) { entry in
                                    EntryRowView(entry: entry)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedEntryId = entry.id
                                            isShowingEntryDetail = true
                                        }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Reflect")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingNewEntrySheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewEntrySheet) {
                JournalEntryEditorView(onSave: { newEntry in
                    fetchEntries()
                })
            }
            .navigationDestination(isPresented: $isShowingEntryDetail) {
                if let entry = entries.first(where: { $0.id == selectedEntryId }) {
                    JournalEntryDetailView(entry: entry, onDelete: {
                        fetchEntries()
                        isShowingEntryDetail = false
                    }, onUpdate: {
                        fetchEntries()
                    })
                }
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
            .onAppear {
                fetchEntries()
            }
        }
    }
    
    private func fetchEntries() {
        isLoading = true
        errorMessage = ""
        
        appState.fetchEntries()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { fetchedEntries in
                entries = fetchedEntries
            })
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading your journal entries...")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 20)
            
            Spacer()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onCreateEntry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor.opacity(0.6))
            
            Text("Your Journal Awaits")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start documenting your thoughts and feelings by creating your first journal entry.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreateEntry) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    
                    Text("Create Your First Entry")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
            
            Spacer()
        }
    }
}

// MARK: - Stats Card View
struct StatsCardView: View {
    let entryCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal Stats")
                .font(.headline)
            
            HStack(spacing: 25) {
                StatItemView(
                    icon: "book.fill",
                    value: "\(entryCount)",
                    label: "Total Entries"
                )
                
                // Calculate streak based on entries (in a real app)
                StatItemView(
                    icon: "flame.fill",
                    value: "3",
                    label: "Day Streak"
                )
                
                // Calculate most common mood (in a real app)
                StatItemView(
                    icon: "face.smiling",
                    value: "😌",
                    label: "Common Mood"
                )
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Entry Row View
struct EntryRowView: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.createdAt.formatted())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if entry.tags.count > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(5)
                                }
                            }
                        }
                        .frame(height: 26)
                    }
                }
                
                Spacer()
                
                Text(entry.mood.emoji)
                    .font(.title2)
            }
            
            Text(entry.content)
                .lineLimit(3)
                .font(.body)
                .padding(.top, 2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
