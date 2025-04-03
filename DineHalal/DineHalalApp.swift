
///  Dine_HalalApp.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.


import SwiftUI
import Firebase
import FirebaseFirestore
import GoogleSignIn
import GoogleMaps


@main
struct DineHalalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationState = NavigationStateManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(navigationState)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
