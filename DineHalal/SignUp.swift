//
//  SignUp.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/15/25.
//
import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn

struct SignUp: View {
    @Binding var path: NavigationPath
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var reenterPassword: String = ""
    @State private var isSignedIn = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                Image("Icon") // App logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.darkBrown)

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("First Name")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    TextField("Enter your first name", text: $firstName)
                        .padding()
                        .background(Color.accent.opacity(0.7))
                        .cornerRadius(8)

                    Text("Last Name")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    TextField("Enter your last name", text: $lastName)
                        .padding()
                        .background(Color.accent.opacity(0.7))
                        .cornerRadius(8)

                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color.accent.opacity(0.7))
                        .cornerRadius(8)

                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    SecureField("Create a password", text: $password)
                        .padding()
                        .background(Color.accent.opacity(0.7))
                        .cornerRadius(8)

                    Text("Re-enter Password")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    SecureField("Re-enter your password", text: $reenterPassword)
                        .padding()
                        .background(Color.accent.opacity(0.7))
                        .cornerRadius(8)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: {
                        handleSignUp()
                    }) {
                        Text("Create Account")
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

                // Navigation to Sign In
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.or)

                    Button(action: {
                        path.removeLast()
                    }) {
                        Text("Sign In")
                            .foregroundColor(.mud)
                            .underline()
                    }
                }
                .padding(.bottom)

                Spacer()
            }
            .fullScreenCover(isPresented: $isSignedIn) {
                ContentView()
            }
        }
        .padding()
        .background(Color("AccentColor"))
        .ignoresSafeArea()
    }

    private func handleSignUp() {
        if password == reenterPassword {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorMessage = "Error signing up: \(error.localizedDescription)"
                    return
                }

                print("Account created successfully!")
                // After successful sign up, sign the user in
                self.isSignedIn = true
            }
        } else {
            self.errorMessage = "Passwords do not match!"
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
                    self.isSignedIn = true
                }
            }
        }
    }
}

