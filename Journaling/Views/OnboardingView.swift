//
//  OnboardingView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case personalization = 1
    case notifications = 2
    case complete = 3
}

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var name: String = ""
    @State private var journalingGoals: String = ""
    @State private var enableNotifications: Bool = true
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                if currentStep != .complete {
                    ProgressView(value: Double(currentStep.rawValue), total: Double(OnboardingStep.allCases.count - 2))
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // Step content
                switch currentStep {
                case .welcome:
                    OnboardingWelcomeView(onContinue: { currentStep = .personalization })
                case .personalization:
                    OnboardingPersonalizationView(
                        name: $name,
                        journalingGoals: $journalingGoals,
                        onContinue: { currentStep = .notifications }
                    )
                case .notifications:
                    OnboardingNotificationsView(
                        enableNotifications: $enableNotifications,
                        reminderTime: $reminderTime,
                        onContinue: saveAndCompleteOnboarding
                    )
                case .complete:
                    OnboardingCompleteView(onGetStarted: {
                        appState.completeOnboarding()
                    })
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentStep != .welcome && currentStep != .complete {
                        Button(action: goBackOneStep) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep != .complete {
                        Button("Skip") {
                            saveAndCompleteOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
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
        }
        .onAppear {
            // Pre-populate with user data if available
            if let user = appState.currentUser {
                name = user.name
                journalingGoals = user.journalingGoals
                enableNotifications = user.notificationsEnabled
                reminderTime = user.reminderTime
            }
        }
    }
    
    private func goBackOneStep() {
        if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
        }
    }
    
    private func saveAndCompleteOnboarding() {
        isLoading = true
        
        // Update the user profile
        appState.updateUserProfile(name: name, journalingGoals: journalingGoals)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.message
                    isLoading = false
                }
            }, receiveValue: { _ in
                // Update notification preferences
                appState.updateNotificationPreferences(enabled: enableNotifications, reminderTime: reminderTime)
                
                // Move to completion step
                currentStep = .complete
                isLoading = false
            })
            .store(in: &cancelables)
    }
    
    @State private var cancelables = Set<AnyCancellable>()
}

// MARK: - Welcome Step
struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Welcome to Reflect")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your personal journaling companion for mindfulness and self-reflection.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Personalization Step
struct OnboardingPersonalizationView: View {
    @Binding var name: String
    @Binding var journalingGoals: String
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Personalize Your Experience")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Let's make Reflect yours. Tell us a bit about yourself and your journaling goals.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Name")
                        .font(.headline)
                    
                    TextField("Enter your name", text: $name)
                        .textFieldStyle()
                        .padding(.horizontal, 0)
                }
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Journaling Goals")
                        .font(.headline)
                    
                    Text("What would you like to achieve with journaling?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $journalingGoals)
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .primaryButtonStyle()
                }
                .disabled(name.isEmpty)
                .padding(.vertical, 20)
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Notifications Step
struct OnboardingNotificationsView: View {
    @Binding var enableNotifications: Bool
    @Binding var reminderTime: Date
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Reminder Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Never miss a journaling session with daily reminders.")
                    .font(.body)
                
                Toggle("Enable Daily Reminders", isOn: $enableNotifications)
                    .font(.headline)
                    .padding(.top, 10)
                
                if enableNotifications {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reminder Time")
                            .font(.headline)
                        
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .primaryButtonStyle()
                }
                .padding(.vertical, 20)
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Complete Step
struct OnboardingCompleteView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Reflect journal is ready for your thoughts, feelings, and reflections.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: onGetStarted) {
                Text("Start Journaling")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}
