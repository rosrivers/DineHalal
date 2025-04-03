//
//  SignInView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/5/25.
//  Edited to implement create account with username/password by Chelsea Bhuiyan 3/28/25.
import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignedIn = false
    @State private var errorMessage: String = ""  // To store any sign-in error message
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
            Spacer()

            Image("Icon") // Logo on top
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)

            Text("DineHalal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.darkBrown)
                

            Text("Halal dining made simple and reliable")
                .font(.subheadline)
                .foregroundColor(.darkBrown)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.darkBrown)
                TextField("Enter your email", text: $email)
                    .padding()
                    .background(Color.accent.opacity(0.7))
                    .cornerRadius(8)
                    .foregroundColor(.darkBrown.opacity(0.8))

                Text("Password")
                    .font(.headline)
                    .foregroundColor(.darkBrown)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.accent.opacity(0.7))
                    .cornerRadius(8)
                    .foregroundColor(.darkBrown.opacity(0.8))

                Button(action: {
                    sendPasswordReset()
                }) {
                    Text("Forgot Password?")
                        .font(.system(size: 16))
                        .foregroundColor(.accent)
                }

                Button(action: {
                    // Handle Email/Password sign-in
                    signInWithEmailPassword()
                }) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent)
                        .foregroundColor(.darkBrown)
                        .cornerRadius(10)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 10)
                }
            }
            .padding()
            .background(.mud)
            .cornerRadius(10)
            .padding(.all, 30)

            HStack {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.or)
                    .padding(.trailing, 5)

                Text("Or")
                    .foregroundColor(.or)
                    .padding(.horizontal, 5)

                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.or)
                    .padding(.leading, 5)
            }

            Button(action: {
                // Handle Google Sign-In action
                handleGoogleSignIn()
            }) {
                HStack(spacing: 12) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                    Text("Continue with Google")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.accent)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.darkBrown, lineWidth: 2)
                )
            }
            .padding()

            NavigationLink(value: "SignUp") {
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.or)

                    Text("Create one")
                        .foregroundColor(.mud)
                        .underline()
                }
            }
            .padding(.bottom)

            Spacer()
        }
        .padding()
        .background(Color("AccentColor"))
        .ignoresSafeArea()
        .navigationDestination(for: String.self) { value in
            if value == "SignUp" {
                SignUp(path: $path)
            }
        }
        .fullScreenCover(isPresented: $isSignedIn) {
            ContentView()  // Navigate to the main screen once signed in
        }
    }

    // Sign in with Email and Password
    private func signInWithEmailPassword() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription  // Display error message
                print("Error signing in with email/password: \(error.localizedDescription)")
                return
            }

            // On successful login
            print("User signed in with Email/Password")
            isSignedIn = true  // Trigger the fullScreenCover to go to ContentView
        }
    }
    
    // Forgot Password 
    private func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                print("Error sending password reset email: \(error.localizedDescription)")
            } else {
                errorMessage = "Password reset email sent successfully. Check your inbox."
                print("Password reset email sent successfully.")
            }
        }
    }

    // Google Sign-In handler
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingVC = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }

            guard let user = signInResult?.user else {
                print("Error: Failed to get user.")
                return
            }

            let idToken = user.idToken?.tokenString ?? ""
            let accessToken = user.accessToken.tokenString

            guard !idToken.isEmpty else {
                print("Error: Missing ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                            accessToken: accessToken)
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("Error signing in with Firebase: \(error.localizedDescription)")
                } else {
                    print("Firebase sign-in successful!")
                    isSignedIn = true
                }
            }
        }
    }
}
