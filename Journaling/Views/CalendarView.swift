//
//  CalendarView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var entries: [JournalEntry] = []
    @State private var entriesByDate: [Date: [JournalEntry]] = [:]
    @State private var selectedDate: Date = Date()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedEntryId: String = ""
    @State private var isShowingEntryDetail = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Month calendar view
                CalendarMonthView(
                    selectedDate: $selectedDate,
                    entriesByDate: entriesByDate,
                    monthOffset: 0
                )
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 10)
                
                // Entries for selected date
                VStack(alignment: .leading) {
                    if let dateEntries = getEntriesForSelectedDate(), !dateEntries.isEmpty {
                        Text("calendar.entries".localized(with: dateEntries.count) + " on \(selectedDate.formatted(date: .long, time: .omitted))") // Updated localization
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(dateEntries) { entry in
                                    EntryListItemView(entry: entry)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedEntryId = entry.id ?? ""
                                            isShowingEntryDetail = true
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            
                            Image(systemName: "calendar.badge.exclamationmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.secondary)

                            Text("calendar.noEntries.title".localized + " on \(selectedDate.formatted(date: .long, time: .omitted))") // Updated localization
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)

                            Button(action: {
                                // TODO: Implement creating a new entry for the selected date
                            }) {
                                Text("home.newEntry.button".localized) // Reusing key
                                    .primaryButtonStyle()
                                    .padding(.horizontal, 40)
                                    .padding(.top, 20)
                            }

                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("calendar.title".localized) // Updated key
            .navigationBarTitleDisplayMode(.inline)
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
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { fetchedEntries in
                entries = fetchedEntries
                entriesByDate = fetchedEntries.groupByDate()
            })
            .store(in: &cancellables)
    }
    
    private func getEntriesForSelectedDate() -> [JournalEntry]? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        guard let date = calendar.date(from: components) else { return nil }
        return entriesByDate[date]
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Calendar Month View
struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let entriesByDate: [Date: [JournalEntry]]
    let monthOffset: Int
    
    @State private var month: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(monthTitle)
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 10)
            
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            hasEntries: hasEntriesForDate(date),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    } else {
                        // Empty cell for days not in current month
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            if let initialMonth = calendar.date(byAdding: .month, value: monthOffset, to: Date()) {
                month = initialMonth
            }
        }
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: month) {
            month = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: month) {
            month = newMonth
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        
        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)!
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        let daysInMonth = calendar.component(.day, from: lastDayOfMonth)
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Fill out the last week if necessary
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            days += Array(repeating: nil, count: remainingDays)
        }
        
        return days
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    private func hasEntriesForDate(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let dateKey = calendar.date(from: components) else { return false }
        return entriesByDate[dateKey] != nil && !entriesByDate[dateKey]!.isEmpty
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasEntries: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        VStack {
            Text(dayNumber)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .fill(hasEntries ? Color.accentColor : Color.clear)
                        .frame(width: 6, height: 6)
                        .padding(.top, 24),
                    alignment: .bottom
                )
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isToday {
            return Color.secondary.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
}

// MARK: - Entry List Item View
struct EntryListItemView: View {
    let entry: JournalEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.createdAt.formattedTime())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(entry.content)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(entry.mood.emoji)
                .font(.title3)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppState())
    }
}
