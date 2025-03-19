
//  GoogleSignInHelper.swift
//  Dine Halal
//  Created by Joanne on 3/7/25.

import UIKit
import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

// This extension makes UIKit work with SwiftUI as is not integrated manually working with SwiftUI. 
extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return UIViewController()
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            return UIViewController()
        }
        
        return root
    }
}

// Create this as a utility to call from your SwiftUI views
class SignInHelper {
    static func signInWithGoogle(completion: @escaping (Bool, String?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(false, "No client ID found")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false, "No root view controller found")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                completion(false, "Failed to get user data")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                completion(true, authResult?.user.email)
            }
        }
    }
}
