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
                        Button("onboarding.skip.button".localized) {
                            saveAndCompleteOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("general.error.title".localized),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("general.ok".localized)) {
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

            Text("onboarding.welcome.title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("onboarding.welcome.description".localized)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            Button(action: onContinue) {
                Text("onboarding.getStarted.button".localized)
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
                Text("onboarding.personalization.title".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("onboarding.personalization.subtitle".localized)
                    .font(.body)

                VStack(alignment: .leading, spacing: 10) {
                    Text("onboarding.personalization.name.label".localized)
                        .font(.headline)

                    TextField("onboarding.personalization.name.placeholder".localized, text: $name)
                        .textFieldStyle()
                        .padding(.horizontal, 0)
                }
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("onboarding.personalization.goals.label".localized)
                        .font(.headline)

                    Text("onboarding.personalization.goals.description".localized)
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
                    Text("general.continue".localized)
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
                Text("onboarding.notifications.title".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("onboarding.notifications.subtitle".localized)
                    .font(.body)

                Toggle("onboarding.notifications.enable.toggle".localized, isOn: $enableNotifications)
                    .font(.headline)
                    .padding(.top, 10)

                if enableNotifications {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("onboarding.notifications.time.label".localized)
                            .font(.headline)

                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("general.continue".localized)
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

            Text("onboarding.complete.title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("onboarding.complete.subtitle".localized)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            Button(action: onGetStarted) {
                Text("onboarding.complete.button".localized)
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}
