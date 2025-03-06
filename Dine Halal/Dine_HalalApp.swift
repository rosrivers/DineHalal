
//  Dine_HalalApp.swift
//  Dine Halal
//  Created by Joanne on 3/5/25.

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct Dine_HalalApp: App {
    init() {
        FirebaseApp.configure() // Configuring Firebase
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView() // Start with Splash Screen
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url) // Handle URL callback
                }
        }
    }
    
}
