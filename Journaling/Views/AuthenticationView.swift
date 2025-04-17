//
//  AuthenticationView.swift
//  Journaling
//
//  Created on 2025-04-16.
//

import SwiftUI
import Combine

enum AuthenticationState {
    case welcome
    case login
    case signup
    case forgotPassword
}

struct AuthenticationView: View {
    @EnvironmentObject private var appState: AppState
    @State private var authState: AuthenticationState = .welcome
    
    var body: some View {
        NavigationStack {
            VStack {
                switch authState {
                case .welcome:
                    WelcomeView(onLoginTapped: { authState = .login },
                                onSignupTapped: { authState = .signup })
                case .login:
                    LoginView(onForgotPassword: { authState = .forgotPassword },
                              onCreateAccount: { authState = .signup },
                              onBackTapped: { authState = .welcome })
                case .signup:
                    SignupView(onLoginTapped: { authState = .login },
                               onBackTapped: { authState = .welcome })
                case .forgotPassword:
                    ForgotPasswordView(onBackTapped: { authState = .login })
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onLoginTapped: () -> Void
    let onSignupTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and App Name
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                
                Text("Reflect")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text("Your Daily Journal Companion")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Benefits
            VStack(spacing: 15) {
                BenefitRow(icon: "calendar", text: "Track your thoughts daily")
                BenefitRow(icon: "chart.bar.fill", text: "Monitor your mood patterns")
                BenefitRow(icon: "tag.fill", text: "Organize with custom tags")
                BenefitRow(icon: "bell.fill", text: "Set reminders to journal")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: onLoginTapped) {
                    Text("Log In")
                        .primaryButtonStyle()
                }
                .accessibilityButton(label: "Log In", hint: "Tap to log in to your account")
                
                Button(action: onSignupTapped) {
                    Text("Create Account")
                        .secondaryButtonStyle()
                }
                .accessibilityButton(label: "Create Account", hint: "Tap to create a new account")
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    
    let onForgotPassword: () -> Void
    let onCreateAccount: () -> Void
    let onBackTapped: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Welcome Back")
                .font(.system(size: 28, weight: .bold))
            
            Text("Log in to continue your journaling journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .email)
                    .textFieldStyle()
                    .submitLabel(.next)
                
                SecureField("Password", text: $password)
                    .focused($focusedField, equals: .password)
                    .textFieldStyle()
                    .submitLabel(.go)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            HStack {
                Spacer()
                Button(action: onForgotPassword) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                .padding(.trailing)
            }
            
            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log In")
                }
            }
            .disabled(isLoading || !isValidInput)
            .primaryButtonStyle()
            .padding(.horizontal, 30)
            .padding(.top, 10)
            
            Spacer()
            
            HStack {
                Text("Don't have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: onCreateAccount) {
                    Text("Sign Up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if isValidInput {
                    login()
                }
            case .none:
                break
            }
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() {
        errorMessage = ""
        isLoading = true
        
        appState.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { _ in
                // Success is handled by the app state changing isAuthenticated
            })
            .store(in: &cancelableSubscriptions)
    }
    
    // Store Combine subscriptions
    @State private var cancelableSubscriptions = Set<AnyCancellable>()
}

// MARK: - Signup View
struct SignupView: View {
    @EnvironmentObject private var appState: AppState
    
    let onLoginTapped: () -> Void
    let onBackTapped: () -> Void
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Create Account")
                .font(.system(size: 28, weight: .bold))
            
            Text("Start your journaling journey today")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                TextField("Full Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .textFieldStyle()
                    .submitLabel(.next)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .email)
                    .textFieldStyle()
                    .submitLabel(.next)
                
                SecureField("Password", text: $password)
                    .focused($focusedField, equals: .password)
                    .textFieldStyle()
                    .submitLabel(.next)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .textFieldStyle()
                    .submitLabel(.go)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Button(action: signup) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                }
            }
            .disabled(isLoading || !isValidInput)
            .primaryButtonStyle()
            .padding(.horizontal, 30)
            .padding(.top, 10)
            
            Spacer()
            
            HStack {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: onLoginTapped) {
                    Text("Log In")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
        .onSubmit {
            switch focusedField {
            case .name:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if isValidInput {
                    signup()
                }
            case .none:
                break
            }
        }
    }
    
    private var isValidInput: Bool {
        !name.isEmpty && email.isValidEmail && password.count >= 8 && password == confirmPassword
    }
    
    private func signup() {
        errorMessage = ""
        isLoading = true
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        appState.signup(email: email, password: password, name: name)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { _ in
                // Success is handled by the app state changing isAuthenticated
            })
            .store(in: &cancelableSubscriptions)
    }
    
    // Store Combine subscriptions
    @State private var cancelableSubscriptions = Set<AnyCancellable>()
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject private var appState: AppState
    
    let onBackTapped: () -> Void
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Reset Password")
                .font(.system(size: 28, weight: .bold))
            
            if isSuccess {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Password Reset Email Sent")
                        .font(.headline)
                    
                    Text("Check your email for instructions on how to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: onBackTapped) {
                        Text("Back to Login")
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }
            } else {
                Text("Enter your email address and we'll send you instructions to reset your password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle()
                    .submitLabel(.go)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Reset Password")
                    }
                }
                .disabled(isLoading || !email.isValidEmail)
                .primaryButtonStyle()
                .padding(.horizontal, 30)
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func resetPassword() {
        errorMessage = ""
        isLoading = true
        
        appState.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.message
                }
            }, receiveValue: { _ in
                isSuccess = true
            })
            .store(in: &cancelableSubscriptions)
    }
    
    // Store Combine subscriptions
    @State private var cancelableSubscriptions = Set<AnyCancellable>()
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AppState())
    }
}
