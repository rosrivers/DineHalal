//
//  SplashScreenView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/5/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            SignInView() // Navigate to Sign-In Page after splash
        } else {
            VStack {
                Image("Icon") // Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AccentColor")) // Add this color in Assets
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

