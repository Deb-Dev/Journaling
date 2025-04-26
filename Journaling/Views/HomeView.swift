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
        NavigationStack(path: $appState.router.path) {
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
                                Text("home.recentEntries.title".localized)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(entries.prefix(5)) { entry in
                                        EntryRowView(entry: entry)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedEntryId = entry.id ?? ""
                                                isShowingEntryDetail = true
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("home.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        isShowingNewEntrySheet = true
                        appState.router.showNewEntrySheet()
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("home.newEntry.button".localized))
                }
            }
            .sheet(isPresented: $isShowingNewEntrySheet, onDismiss: {
                appState.router.dismissSheet()
            }) {
                JournalEntryEditorView(onSave: { newEntry in
                    fetchEntries()
                    isShowingNewEntrySheet = false
                })
            }
            .navigationDestination(for: JournalEntry.self) { entry in
                JournalEntryDetailView(entry: entry, onDelete: {
                    fetchEntries()
                    appState.router.navigateBack()
                }, onUpdate: {
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
            .errorAlert(errorMessage: $errorMessage)
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
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.message
                }
            }, receiveValue: { fetchedEntries in
                self.entries = fetchedEntries
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

            Text("home.loading.message".localized)
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
            
            Text("home.emptyState.title".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("home.emptyState.message".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreateEntry) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)

                    Text("home.createFirstEntry.button".localized)
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
            Text("home.stats.title".localized)
                .font(.headline)

            HStack(spacing: 25) {
                StatItemView(
                    icon: "book.fill",
                    value: "\(entryCount)",
                    label: "home.stats.totalEntries".localized
                )
                
                // Calculate streak based on entries (in a real app)
                StatItemView(
                    icon: "flame.fill",
                    value: "3",
                    label: "home.stats.dayStreak".localized
                )
                
                // Calculate most common mood (in a real app)
                StatItemView(
                    icon: "face.smiling",
                    value: "😌",
                    label: "home.stats.commonMood".localized
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
        .standardCard()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
