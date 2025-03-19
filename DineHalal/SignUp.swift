//
//  SignUp.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/15/25.
//

import SwiftUI

struct SignUp: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignIn = false  // Track navigation to Sign In

    var body: some View {
        NavigationView {
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
                    Text("Name")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                    TextField("Enter your name", text: $name)
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

                    Button(action: {
                        // Handle sign-up action
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
                    // Handle Google Sign-Up
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
                        showSignIn = true
                    }) {
                        Text("Sign In")
                            .foregroundColor(.mud)
                            .underline()
                    }
                }
                .padding(.bottom)

                .navigationDestination(for: String.self) { value in
                    if value == "SignInView" {
                        SignInView()
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color("AccentColor"))
            .ignoresSafeArea()
        }
    }
}
