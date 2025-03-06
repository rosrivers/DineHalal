//
//  SignInView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/5/25.
//

import SwiftUI

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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom)

                Text("Password")
                    .font(.headline)
                    .foregroundColor(.darkBrown)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Spacer()
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.brown.opacity(0.2))
            .cornerRadius(10)

            Button(action: {
                // Handle sign-in action
            }) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brown)
                    .foregroundColor(.darkBrown)
                    .cornerRadius(10)
            }
            .padding()

            Divider()
                .padding()

            Button(action: {
                // Handle Google Sign-In
            }) {
                HStack {
                    Image(systemName: "globe") // Use a Google icon if available
                    Text("Continue with Google")
                        .font(.headline)
                        .foregroundColor(.darkBrown)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.brown.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .padding()
        .background(Color("AccentColor"))
        .ignoresSafeArea()
    }
}
