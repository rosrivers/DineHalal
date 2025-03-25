
///  Dine_HalalApp.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.

import SwiftUI
import Firebase
import FirebaseFirestore
import GoogleSignIn

@main
struct DineHalalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationState = NavigationStateManager()
    
    init() {
        FirebaseApp.configure() // Configuring Firebase for when the app launches
        
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView() // Start with Splash Screen
                .environmentObject(navigationState)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
