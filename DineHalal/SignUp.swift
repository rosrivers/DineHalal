///  SignUp.swift
///  Dine Halal
///  Created by Iman Ikram on 3/15/25.
///  modified by rosa on 04/05/25.

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
    
    // updated by rosa: state variable to control when the email verification view should be shown.
    @State private var showEmailVerification = false  // NEW: Added to trigger email verification screen after registration.

    var body: some View {
        ScrollView {
            VStack (spacing: 0.5){
                //Spacer()
                //Image("Icon") // App logo
                    //.resizable()
                    //.scaledToFit()
                    //.frame(width: 150, height: 150)

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.darkBrown)
                    .padding(.top, 30)

                //Spacer()

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
                            .background(Color.accent)
                            .foregroundColor(.darkBrown)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.mud)
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
                    .background(Color.accent)
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
            // NEW: Present the EmailVerificationView full screen when email verification is needed.
            .fullScreenCover(isPresented: $showEmailVerification) {
                EmailVerificationView(onVerified: {   // NEW: Pass the callback that triggers transition to HomeScreen.
                    self.showEmailVerification = false
                    self.isSignedIn = true  // NEW: When email is verified, set isSignedIn to true.
                })
            }
        }
        .padding()
        .background(Color("AccentColor"))
        .ignoresSafeArea()
        // NEW: When isSignedIn becomes true, present the HomeScreen.
        .fullScreenCover(isPresented: $isSignedIn) {
            HomeScreen()  // NEW: Changed destination to HomeScreen.
        }
    }

    private func handleSignUp() {
        if password == reenterPassword {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorMessage = "Error signing up: \(error.localizedDescription)"
                    return
                }

                print("Account created successfully!")
                // NEW: After account creation, send a verification email.
                guard let user = Auth.auth().currentUser else { return }
                user.sendEmailVerification { error in
                    if let error = error {
                        self.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                    } else {
                        print("Verification email sent!")
                        self.showEmailVerification = true  // NEW: Trigger email verification screen.
                    }
                }
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
                    // NEW: After Google sign-in, send verification email and show the verification screen.
                    guard let user = Auth.auth().currentUser else { return }
                    user.sendEmailVerification { error in
                        if let error = error {
                            print("Failed to send verification email: \(error.localizedDescription)")
                        } else {
                            print("Verification email sent!")
                            self.showEmailVerification = true
                        }
                    }
                }
            }
        }
    }
}

// NEW: Preview for SignUp using a constant binding for NavigationPath.
struct SignUp_Previews: PreviewProvider {
    static var previews: some View {
        SignUp(path: .constant(NavigationPath()))
    }
}
