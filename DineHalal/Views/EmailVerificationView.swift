///  EmailVerificationView.swift
///  Dine Halal
///
///  Created by Rosa Rivera on 4/5/25.

import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    var onVerified: () -> Void  // NEW: Callback to signal that email verification is complete.
    
    @State private var emailSent = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Verification")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("DarkBrown"))
                    
                Text("Please check your email for a verification link.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(Color("Mud"))
                    
                if emailSent {
                    Text("A new verification link has been sent.")
                        .foregroundColor(.green)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: resendVerificationEmail) {
                    Text("Resend Email")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("DBB77F"))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                
                // NEW: Button to check if the email has been verified.
                Button(action: {
                    Auth.auth().currentUser?.reload { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                        } else if Auth.auth().currentUser?.isEmailVerified == true {
                            // Email is verified: call the callback and dismiss this view.
                            onVerified()
                            dismiss()
                        } else {
                            errorMessage = "Email not verified yet. Please check your inbox."
                        }
                    }
                }) {
                    Text("I've verified my email")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mud)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user is currently signed in."
            return
        }
        user.sendEmailVerification { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                emailSent = true
            }
        }
    }
}
