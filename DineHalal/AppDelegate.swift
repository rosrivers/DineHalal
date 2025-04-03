
///  AppDelegate.swift
///  Dine Halal
///  Created by Joanne on 3/7/25.

import UIKit
import Firebase
import GoogleSignIn
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Google Maps
        GMSServices.provideAPIKey(APIKeys.mapsKey)
        
        //  Maps initialization
        Thread.sleep(forTimeInterval: 0.1)
        
        // SThen Firebase
        FirebaseApp.configure()
        
        //  Google Sign In
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
