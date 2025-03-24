//
//  SignInView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/5/25.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignedIn = false  // Track sign-in state
    @State private var path = NavigationPath()  // For NavigationStack

    var body: some View {
        NavigationStack(path: $path) { // Use NavigationStack for modern navigation
            VStack {
                Spacer()

                Image("Icon") // Logo on top
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

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

                    HStack {
                        Spacer()
                        Text("Forgot Password?")
                            .font(.system(size: 16))
                            .foregroundColor(.accent)
                    }

                    Button(action: {
                        // Handle sign-in action
                    }) {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.accent)
                            .foregroundColor(.darkBrown)
                            .cornerRadius(10)
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
                    //Text("Navigated to SignUp!")
                    SignUp()
                }
            }
            .fullScreenCover(isPresented: $isSignedIn) {
                //HomeScreen()
                ContentView()
            }
        }
    }

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
