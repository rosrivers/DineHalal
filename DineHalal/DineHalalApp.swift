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
    
    /// Create location manager - user location - restaurants are fetched based on user location.
    @StateObject private var locationManager = LocationManager()
    
    /// Create verification service
    @StateObject private var verificationService: VerificationService
    
    /// Create places service that uses the verification service
    @StateObject private var placesService: PlacesService
    
    // Initialize with proper setup
    init() {
        // Set consistent tab bar color
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        tabBarAppearance.barTintColor = UIColor.systemBackground
        
        /// verification service instance
        let verificationServiceInstance = VerificationService()
        
        /// StateObjects Instances
        _verificationService = StateObject(wrappedValue: verificationServiceInstance)
        _placesService = StateObject(wrappedValue: PlacesService(verificationService: verificationServiceInstance))
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(navigationState)
                .environmentObject(favorites)
                .environmentObject(verificationService)
                .environmentObject(placesService)
                .environmentObject(locationManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
