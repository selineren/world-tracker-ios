//
//  DeleteAccountView.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var password = ""
    @State private var confirmationText = ""
    @State private var errorMessage: String?
    @State private var isDeleting = false
    
    // MARK: - Validation
    
    /// Check if the form is valid and ready for submission
    /// Requires both password and exact "DELETE" confirmation
    private var isFormValid: Bool {
        !password.isEmpty &&
        confirmationText == "DELETE" &&
        !isDeleting
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Warning Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("This Action is Permanent")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                        
                        Text("Deleting your account will:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Remove all your travel data", systemImage: "xmark.circle")
                            Label("Delete your account permanently", systemImage: "xmark.circle")
                            Label("Cannot be recovered or undone", systemImage: "xmark.circle")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Password Section
                Section {
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Verify Identity")
                } footer: {
                    Text("Enter your password to continue")
                }
                
                // MARK: - Confirmation Section
                Section {
                    TextField("Type DELETE to confirm", text: $confirmationText)
                        .autocorrectionDisabled()
                } header: {
                    Text("Type DELETE to Confirm")
                } footer: {
                    if confirmationText.isEmpty {
                        Text("Type exactly: DELETE")
                    } else if confirmationText != "DELETE" {
                        Text("Must match exactly: DELETE")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Confirmation accepted")
                            .foregroundStyle(.green)
                    }
                }
                
                // MARK: - Delete Button Section
                Section {
                    Button(role: .destructive) {
                        Task {
                            await deleteAccount()
                        }
                    } label: {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isDeleting ? "Deleting Account..." : "Delete My Account")
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
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isDeleting)
                }
            }
        }
    }
    
    // MARK: - Deletion Logic
    
    /// Execute the account deletion workflow
    /// 1. Reauthenticate with password
    /// 2. Delete Firestore data
    /// 3. Delete Firebase Auth account
    /// 4. Dismiss sheet after successful deletion
    private func deleteAccount() async {
        // Clear previous error
        errorMessage = nil
        isDeleting = true
        
        defer {
            isDeleting = false
        }
        
        do {
            try await authService.deleteAccount(currentPassword: password)
            
            // Dismiss the sheet immediately after successful deletion
            // The auth state listener will handle sign-out and data cleanup in the background
            dismiss()
            
        } catch let error as NSError {
            // Map Firebase errors to user-friendly messages
            errorMessage = friendlyErrorMessage(from: error)
        }
    }
    
    // MARK: - Error Handling
    
    /// Convert Firebase error codes to user-friendly messages for account deletion
    /// - Parameter error: The error from Firebase Auth or Firestore
    /// - Returns: A user-friendly error message
    private func friendlyErrorMessage(from error: NSError) -> String {
        // Firebase Auth errors use domain "FIRAuthErrorDomain"
        if error.domain == "FIRAuthErrorDomain" {
            switch error.code {
            case 17009: // ERROR_WRONG_PASSWORD
                return "Password is incorrect. Please try again"
            case 17004: // ERROR_INVALID_EMAIL (can mean wrong password in reauthentication)
                return "Password is incorrect. Please try again"
            case 17020: // ERROR_NETWORK_REQUEST_FAILED
                return "Network error. Please check your connection and try again"
            case 17999: // ERROR_INVALID_CREDENTIAL
                return "Password is incorrect. Please try again"
            case 17011: // ERROR_USER_NOT_FOUND
                return "User session expired. Please sign in again"
            case 17014: // ERROR_USER_MISMATCH
                return "Authentication error. Please try again"
            case 17995: // ERROR_REQUIRES_RECENT_LOGIN
                return "Session expired. Please sign out and sign back in to delete your account"
            default:
                // For unknown Firebase errors, check the error message
                let message = error.localizedDescription.lowercased()
                
                // Parse common error patterns
                if message.contains("credential") && (message.contains("malformed") || message.contains("expired")) {
                    return "Password is incorrect. Please try again"
                } else if message.contains("network") || message.contains("connection") {
                    return "Network error. Please check your connection and try again"
                } else if message.contains("recent") && message.contains("login") {
                    return "Session expired. Please sign out and sign back in to delete your account"
                } else {
                    // Generic fallback for account deletion
                    return "Unable to delete account. Please try again or contact support"
                }
            }
        } else if error.domain == "FIRFirestoreErrorDomain" {
            // Firestore errors during visit data deletion
            switch error.code {
            case 7: // Permission denied
                return "Permission error. Please try signing out and back in"
            case 14: // Unavailable (often network/offline)
                return "Network error. Please check your connection and try again"
            default:
                let message = error.localizedDescription.lowercased()
                if message.contains("network") || message.contains("offline") || message.contains("connection") {
                    return "Network error. Please check your connection and try again"
                } else {
                    return "Unable to delete account data. Please try again or contact support"
                }
            }
        } else {
            // For non-Firebase errors, check for network issues
            let message = error.localizedDescription.lowercased()
            if message.contains("network") || message.contains("internet") || message.contains("connection") {
                return "Network error. Please check your connection and try again"
            } else {
                return error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DeleteAccountView()
        .environmentObject(AuthService())
}
