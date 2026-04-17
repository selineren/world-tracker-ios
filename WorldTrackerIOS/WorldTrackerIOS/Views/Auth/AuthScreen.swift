//
//  AuthScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Top Spacer (Adaptive)
                Spacer()
                    .frame(height: 60)
                
                // MARK: - Branding Header
                VStack(spacing: 16) {
                    // App Logo
                    AppLogoView()
                    
                    // App Name
                    Text("WorldTracker")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    // Tagline
                    Text("Track your travels around the world")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
                
                // MARK: - Input Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color(.separator), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color(.separator), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)
                
                // MARK: - Error Message
                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.08))
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // MARK: - Primary Action Button
                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        
                        Text(isCreatingAccount ? "Create Account" : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundStyle(.white)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(email.isEmpty || password.isEmpty || isSubmitting)
                .opacity((email.isEmpty || password.isEmpty || isSubmitting) ? 0.6 : 1.0)
                .padding(.horizontal, 32)
                .padding(.top, errorMessage == nil ? 32 : 16)
                
                // MARK: - Secondary Toggle Action
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCreatingAccount.toggle()
                        errorMessage = nil
                    }
                } label: {
                    Text(isCreatingAccount 
                         ? "Already have an account? **Sign in**"
                         : "Need an account? **Sign up**")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .disabled(isSubmitting)
                .padding(.top, 24)
                .padding(.horizontal, 32)
                
                // MARK: - Bottom Spacer
                Spacer()
                    .frame(height: 60)
            }
            .frame(maxWidth: 500) // Max width for larger devices
            .frame(maxWidth: .infinity) // Center on wide screens
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        
        defer {
            isSubmitting = false
        }

        do {
            if isCreatingAccount {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
            
            // No need to manually call sync here - WorldTrackerIOSApp.handleAuthStateChange()
            // will automatically trigger appState.handleSignIn() which includes sync
        } catch {
            withAnimation(.easeInOut(duration: 0.3)) {
                errorMessage = friendlyErrorMessage(from: error)
            }
        }
    }
    
    /// Convert Firebase authentication errors to user-friendly messages
    /// - Parameter error: The error from Firebase Auth
    /// - Returns: A clear, actionable error message for the user
    private func friendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        // Firebase Auth errors use domain "FIRAuthErrorDomain"
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            // Sign In Errors
            case 17008: // ERROR_INVALID_EMAIL
                return "Please enter a valid email address"
            case 17009: // ERROR_WRONG_PASSWORD
                return "Incorrect password. Please try again"
            case 17011: // ERROR_USER_NOT_FOUND
                return "No account found with this email"
            case 17012: // ERROR_USER_DISABLED
                return "This account has been disabled"
            case 17020: // ERROR_NETWORK_REQUEST_FAILED
                return "Network error. Please check your internet connection"
            
            // Sign Up Errors
            case 17007: // ERROR_EMAIL_ALREADY_IN_USE
                return "An account with this email already exists"
            case 17026: // ERROR_WEAK_PASSWORD
                return "Password is too weak. Use at least 6 characters"
            
            // General Errors
            case 17999: // ERROR_INVALID_CREDENTIAL
                return "Invalid email or password"
            case 17010: // ERROR_INVALID_API_KEY
                return "Configuration error. Please contact support"
            case 17014: // ERROR_USER_MISMATCH
                return "Authentication error. Please try again"
                
            default:
                // Check error message for common patterns
                let message = nsError.localizedDescription.lowercased()
                
                if message.contains("malformed") || message.contains("credential") {
                    return "Invalid email or password format"
                } else if message.contains("expired") {
                    return "Session expired. Please try again"
                } else if message.contains("network") || message.contains("connection") {
                    return "Network error. Please check your internet connection"
                } else if message.contains("too many requests") {
                    return "Too many attempts. Please wait a moment and try again"
                } else {
                    return "Authentication failed. Please check your credentials"
                }
            }
        }
        
        // For non-Firebase errors
        let message = nsError.localizedDescription.lowercased()
        if message.contains("network") || message.contains("internet") || message.contains("connection") {
            return "Network error. Please check your internet connection"
        }
        
        // Fallback to original error message
        return error.localizedDescription
    }
}

// MARK: - App Logo View

/// Displays the app logo with a fallback to a globe icon
struct AppLogoView: View {
    var body: some View {
        // Try to load the logo from Assets
        // If "AppLogo" asset doesn't exist, show gradient globe fallback
        if let uiImage = UIImage(named: "AppLogo") {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22.5, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        } else {
            // Fallback: gradient globe icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
        }
    }
}

