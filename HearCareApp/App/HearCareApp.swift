//
//  HearCareApp.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// App/HearCareApp.swift
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
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
