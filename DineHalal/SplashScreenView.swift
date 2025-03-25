//
//  SplashScreenView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/5/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var path = NavigationPath() // Maintain navigation state
    
    var body: some View {
        NavigationStack(path: $path) {
            if isActive {
                SignInView(path: $path) // Pass navigation path
            } else {
                VStack {
                    Image("Icon") // App Logo
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AccentColor"))
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
}
