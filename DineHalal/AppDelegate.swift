
///  AppDelegate.swift
///  Dine Halal
///  Created by Joanne on 3/7/25.




import UIKit
import Firebase
import FirebaseFirestore
import GoogleSignIn
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        /// Initialize Google Maps
        GMSServices.provideAPIKey("AIzaSyD0d33gYQ-n6wwJeCeUzPL1S4GjDD_GQbk")
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    /// Add support for universal links
    func application(_ application: UIApplication,
                    continue userActivity: NSUserActivity,
                    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let incomingURL = userActivity.webpageURL {
            return GIDSignIn.sharedInstance.handle(incomingURL)
        }
        return false
    }
}
