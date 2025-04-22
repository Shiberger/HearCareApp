//
//  HearCareApp.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct HearCareApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            if authService.user != nil {
                HomeView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}

// AppDelegate implementation for Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize GIDSignIn
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Failed to restore previous Google Sign-In: \(error.localizedDescription)")
            }
        }
        
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Opening URL: \(url.absoluteString)")
        
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Add handling for other URL schemes if needed
        
        return false
    }
}
