//
//  JournalEntryEditorView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

struct JournalEntryEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Callback when an entry is saved
    var onSave: ((JournalEntry) -> Void)?
    
    // For editing an existing entry
    var existingEntry: JournalEntry?
    
    // State
    @State private var content: String = ""
    @State private var selectedMood: Mood = .neutral
    @State private var entryDate: Date = Date()
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingDiscardAlert = false
    @State private var autoSaveTimer: Timer?
    @State private var lastSavedContent: String = ""
    
    // For autosave draft
    private let autoSaveInterval: TimeInterval = 30 // seconds
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date picker
                    DatePicker("editor.date".localized, selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal)
                    
                    Divider()
                    
                    // Mood selector
                    VStack(alignment: .leading) {
                        Text("editor.moodQuestion".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(Mood.allCases) { mood in
                                    MoodButton(
                                        mood: mood,
                                        isSelected: selectedMood == mood,
                                        onSelect: { selectedMood = mood }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                    
                    // Tags
                    VStack(alignment: .leading) {
                        Text("editor.tags".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        TagView(tag: tag, onRemove: { removeTag(tag) })
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 5)
                        }
                        
                        HStack {
                            TextField("editor.addTag.placeholder".localized, text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit {
                                    addTag()
                                }

                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .accessibilityLabel(Text("general.add".localized)) // Updated key
                            }
                            .disabled(newTag.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // Journal content
                    VStack(alignment: .leading) {
                        Text("editor.journalEntry".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(5)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .overlay(
                                Text("editor.journalEntry.placeholder".localized) // Added key
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .opacity(content.isEmpty ? 1 : 0) // Show placeholder when empty
                            )
                            .onChange(of: content) {
                                // Reset the autosave timer when content changes
                                resetAutoSaveTimer()
                            }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(existingEntry == nil ? "editor.title.new".localized : "editor.title.edit".localized) // Updated keys
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.cancel".localized) {
                        if content != lastSavedContent {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveEntry) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("general.save".localized)
                        }
                    }
                    .disabled(content.isEmpty || isLoading)
                }
            }
            .alert(isPresented: $showingDiscardAlert) {
                Alert(
                    title: Text("editor.discardAlert.title".localized), // Updated key
                    message: Text("editor.discardAlert.message".localized), // Updated key
                    primaryButton: .destructive(Text("editor.discardAlert.discard".localized)) { // Updated key
                        dismiss()
                    },
                    secondaryButton: .cancel(Text("editor.discardAlert.keepEditing".localized)) // Updated key
                )
            }
            .alert(isPresented: Binding(
                get: { !errorMessage.isEmpty },
                set: { if !$0 { errorMessage = "" } }
            )) {
                Alert(
                    title: Text("general.error.title".localized),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("general.ok".localized)) {
                        errorMessage = ""
                    }
                )
            }
            .onAppear {
                setupInitialValues()
                startAutoSaveTimer()
            }
            .onDisappear {
                stopAutoSaveTimer()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialValues() {
        if let entry = existingEntry {
            content = entry.content
            selectedMood = entry.mood
            entryDate = entry.createdAt
            tags = entry.tags
            lastSavedContent = entry.content
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveEntry() {
        isLoading = true
        errorMessage = ""
        
        if let entry = existingEntry {
            // Update existing entry
            var updatedEntry = entry
            updatedEntry.content = content
            updatedEntry.mood = selectedMood
            updatedEntry.tags = tags
            updatedEntry.updatedAt = Date()
            
            appState.updateEntry(entry: updatedEntry)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.message
                    }
                }, receiveValue: { updatedEntry in
                    lastSavedContent = content
                    onSave?(updatedEntry)
                    dismiss()
                })
                .store(in: &cancellables)
        } else {
            // Create new entry
            appState.createEntry(content: content, mood: selectedMood, tags: tags)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.message
                    }
                }, receiveValue: { newEntry in
                    lastSavedContent = content
                    onSave?(newEntry)
                    dismiss()
                })
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Autosave
    
    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            if !content.isEmpty && content != lastSavedContent {
                saveDraft()
            }
        }
    }
    
    private func resetAutoSaveTimer() {
        stopAutoSaveTimer()
        startAutoSaveTimer()
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func saveDraft() {
        // In a real app, we would save to local storage or backend
        // For this demo, we'll just update the lastSavedContent
        lastSavedContent = content
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Mood Button
struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack {
            Text(mood.emoji)
                .font(.system(size: 30))
                .padding(10)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            Text(mood.description.localized) // Updated to use localized description
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .padding(.vertical, 5)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Tag View
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .padding(.leading, 10)
                .padding(.trailing, 5)
                .padding(.vertical, 5)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 5)
        }
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(15)
    }
}

struct JournalEntryEditorView_Previews: PreviewProvider {
    static var previews: some View {
        JournalEntryEditorView()
            .environmentObject(AppState())
    }
}
