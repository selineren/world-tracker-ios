//
//  ChangePasswordView.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isSubmitting = false
    
    // MARK: - Validation
    
    /// Check if the form is valid and ready for submission
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6 &&
        currentPassword != newPassword &&
        !isSubmitting
    }
    
    /// Validation error message shown below password fields
    private var validationHint: String? {
        // Don't show hints until user starts typing
        guard !newPassword.isEmpty || !confirmPassword.isEmpty else {
            return nil
        }
        
        if newPassword.count > 0 && newPassword.count < 6 {
            return "Password must be at least 6 characters"
        }
        
        if !confirmPassword.isEmpty && newPassword != confirmPassword {
            return "Passwords do not match"
        }
        
        if !newPassword.isEmpty && !currentPassword.isEmpty && newPassword == currentPassword {
            return "New password must be different from current password"
        }
        
        return nil
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Current Password Section
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Verify Identity")
                } footer: {
                    Text("Enter your current password to continue")
                }
                
                // MARK: - New Password Section
                Section {
                    SecureField("New Password", text: $newPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("New Password")
                } footer: {
                    if let validationHint {
                        Text(validationHint)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Password must be at least 6 characters")
                    }
                }
                
                // MARK: - Submit Section
                Section {
                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isSubmitting ? "Changing Password..." : "Change Password")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid)
                }
                
                // MARK: - Error Section
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } header: {
                        Text("Error")
                    }
                }
                
                // MARK: - Success Section
                if let successMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(successMessage)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
    
    // MARK: - Password Change Logic
    
    /// Execute the password change workflow
    /// 1. Reauthenticate with current password
    /// 2. Update to new password
    /// 3. Show success and dismiss
    private func changePassword() async {
        // Clear previous messages
        errorMessage = nil
        successMessage = nil
        isSubmitting = true
        
        defer {
            isSubmitting = false
        }
        
        do {
            // Step 1: Reauthenticate with current password
            try await authService.reauthenticate(currentPassword: currentPassword)
            
            // Step 2: Update to new password
            try await authService.updatePassword(newPassword: newPassword)
            
            // Success
            successMessage = "Password changed successfully!"
            
            // Auto-dismiss after brief success message (1.5 seconds)
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
            
        } catch let error as NSError {
            // Map Firebase errors to user-friendly messages
            errorMessage = friendlyErrorMessage(from: error)
        }
    }
    
    // MARK: - Error Handling
    
    /// Convert Firebase error codes to user-friendly messages
    /// - Parameter error: The error from Firebase Auth
    /// - Returns: A user-friendly error message
    private func friendlyErrorMessage(from error: NSError) -> String {
        // Firebase Auth errors use domain "FIRAuthErrorDomain"
        if error.domain == "FIRAuthErrorDomain" {
            switch error.code {
            case 17009: // ERROR_WRONG_PASSWORD
                return "Current password is incorrect"
            case 17004: // ERROR_INVALID_EMAIL (but often means wrong password in reauthentication)
                return "Current password is incorrect"
            case 17026: // ERROR_WEAK_PASSWORD
                return "New password is too weak. Please choose a stronger password"
            case 17020: // ERROR_NETWORK_REQUEST_FAILED
                return "Network error. Please check your connection and try again"
            case 17999: // ERROR_INVALID_CREDENTIAL
                return "Current password is incorrect"
            case 17011: // ERROR_USER_NOT_FOUND
                return "User session expired. Please sign in again"
            case 17014: // ERROR_USER_MISMATCH
                return "Authentication error. Please try again"
            case 17995: // ERROR_REQUIRES_RECENT_LOGIN
                return "Session expired. Please sign out and sign back in"
            default:
                // For unknown Firebase errors, check the error message
                let message = error.localizedDescription.lowercased()
                
                // Parse common error messages
                if message.contains("credential") && (message.contains("malformed") || message.contains("expired")) {
                    return "Current password is incorrect"
                } else if message.contains("password") && message.contains("weak") {
                    return "New password is too weak. Please choose a stronger password"
                } else if message.contains("network") || message.contains("connection") {
                    return "Network error. Please check your connection and try again"
                } else {
                    // Generic fallback without the confusing "Failed to change password:" prefix
                    return "Unable to change password. Please try again or contact support"
                }
            }
        } else {
            // For non-Firebase errors
            return error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    ChangePasswordView()
        .environmentObject(AuthService())
}
