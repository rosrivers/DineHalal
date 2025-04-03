
///  AuthView.swift
///  Dine Halal
///  Created by Joanne on 3/7/25.

import SwiftUI
import Firebase

struct LoginView: View {
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Button("Sign in with Google") {
                isLoading = true
                
                SignInHelper.signInWithGoogle { success, message in
                    isLoading = false
                    
                    if success {
                        print("Successfully signed in: \(message ?? "")")
                        /// Navigate to your next screen or update app state
                    } else {
                        errorMessage = message ?? "Unknown error"
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if isLoading {
                ProgressView()
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }
}
