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

    var body: some View {
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
                    .cornerRadius(8) //
                    .foregroundColor(.darkBrown.opacity(0.8)) // Placeholder color not changing!
                  

                Text("Password")
                    .font(.headline)
                    .foregroundColor(.darkBrown)
                SecureField("Password", text: $password )
                    .padding()
                    .background(Color.accent.opacity(0.7))
                    .cornerRadius(8)
                    .foregroundColor(.darkBrown.opacity(0.8)) // Placeholder color not changing!
                    

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
            .padding(.all, 30) // Margin around the entire box (you can adjust this value)


            HStack {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.or)
                    .padding(.trailing, 5) // Space between the line and "Or"
                
                Text("Or")
                    .foregroundColor(.or) // Set color of "Or" text
                    .padding(.horizontal, 5) // Padding around "Or"
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.or)
                    .padding(.leading, 5) // Space between the line and "Or"
            }

            Button(action: {
                // Handle Google Sign-In action - updated (Jo)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let presentingVC = windowScene.windows.first?.rootViewController else {
                      return
                  }
                  
                  GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
                      if let error = error {
                          print("Error signing in: \(error.localizedDescription)")
                          return
                      }
                      
                      // Successfully signed in
                      guard let user = signInResult?.user else {
                          print("Error: Failed to get user.")
                          return
                      }
                      
                      let userName = user.profile?.name ?? "No name"
                      let userEmail = user.profile?.email ?? "No email"
                      print("User signed in: \(userName), \(userEmail)")

                      // Get the tokens directly since they're not optional
                      let idToken = user.idToken?.tokenString ?? ""
                      let accessToken = user.accessToken.tokenString
                      
                      // Only proceed if we have a valid idToken
                      guard !idToken.isEmpty else {
                          print("Error: Missing ID token.")
                          return
                      }

                      let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                  accessToken: accessToken)
                      Auth.auth().signIn(with: credential) { result, error in
                          if let error = error {
                              print("Error signing in with Firebase: \(error.localizedDescription)")
                          } else {
                              print("Firebase sign-in successful!")
                          }
                      }
                  }
            }){
                HStack(spacing: 12) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26) // Adjust size as needed
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
                            .stroke(Color.darkBrown, lineWidth: 2) // Border color and width
                    )
            }
            .padding()

            Spacer()
        }
        .padding()
        .background(Color("AccentColor"))
        .ignoresSafeArea()
    }
}
