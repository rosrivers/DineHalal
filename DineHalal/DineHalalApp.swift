
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
    @StateObject private var favorites = Favorites()
    
    // Create verification service
    @StateObject private var verificationService = VerificationService()
    
    // Create places service that uses the verification service
    @StateObject private var placesService: PlacesService
    
    // Initialize with proper setup
    init() {
        // Use _placesService to set the wrapped value, referencing the existing verificationService
        _placesService = StateObject(wrappedValue:
            PlacesService(verificationService: VerificationService()))
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(navigationState)
                .environmentObject(favorites)
                .environmentObject(verificationService)
                .environmentObject(placesService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
