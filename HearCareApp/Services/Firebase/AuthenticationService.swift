//
//  AuthenticationService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// AuthenticationService.swift
import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import WebKit

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticating = false
    @Published var error: Error?
    
    // Create a singleton instance
    static let shared = AuthenticationService()
    
    // Make the initializer private to enforce singleton pattern
    init() {
        self.user = Auth.auth().currentUser
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    var currentUser: User? {
        return user
    }
    
    func signInWithGoogle() {
        isAuthenticating = true
        error = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])
            isAuthenticating = false
            return
        }
        
        // First clear any existing website data to avoid issues with previous sessions
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>,
                                              modifiedSince: date) {
            self.continueGoogleSignIn(clientID: clientID)
        }
    }

    private func continueGoogleSignIn(clientID: String) {
        let configuration = GIDConfiguration(clientID: clientID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            isAuthenticating = false
            return
        }
        
        // Use signIn(withPresenting:) method for a fresh sign-in
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            self.isAuthenticating = false
            
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                self.error = error
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication token not found"])
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                
                self.user = authResult?.user
                
                // Create or update user profile in Firestore
                self.updateUserProfileAfterSignIn(user: authResult?.user)
            }
        }
    }
    
    private func updateUserProfileAfterSignIn(user: User?) {
        guard let user = user else {
            print("Error: No user provided to updateUserProfileAfterSignIn")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking user document: \(error.localizedDescription)")
                // Don't fail the sign-in process for Firestore errors
                return
            }
            
            // Create or update user data
            var userData: [String: Any] = [
                "email": user.email ?? "",
                "lastLogin": Timestamp(date: Date())
            ]
            
            if let displayName = user.displayName {
                userData["name"] = displayName
            }
            
            if let photoURL = user.photoURL?.absoluteString {
                userData["photoURL"] = photoURL
            }
            
            // If user document doesn't exist, create it with additional fields
            if snapshot?.exists != true {
                userData["createdAt"] = Timestamp(date: Date())
                userData["hearingConditions"] = [] as [String] // Explicitly type as [String]
            }
            
            // Set or update the user document
            userRef.setData(userData, merge: true) { error in
                if let error = error {
                    print("Error updating user document: \(error.localizedDescription)")
                } else {
                    print("User profile successfully updated in Firestore")
                    // Notify the UI that the profile is fully ready if needed
                    // self.profileSetupComplete = true
                }
            }
        }
    }
    
    func signOut() {
        // Clear any errors first
        error = nil
        
        do {
            // Keep track of the current user before signing out
            let currentUser = Auth.auth().currentUser
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Explicitly disconnect from Google (not just sign out)
            // This will revoke access and clear tokens
            GIDSignIn.sharedInstance.disconnect { [weak self] disconnectError in
                if let disconnectError = disconnectError {
                    print("Error disconnecting from Google: \(disconnectError.localizedDescription)")
                    // Don't fail the sign-out process for disconnect errors
                }
                
                // Clear any web session cookies
                let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage])
                let date = Date(timeIntervalSince1970: 0)
                WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>,
                                                      modifiedSince: date) {
                    print("Cleared WKWebsiteDataStore")
                }
                
                // Update UI state
                DispatchQueue.main.async {
                    self?.user = nil
                }
            }
        } catch let error {
            print("Error signing out from Firebase: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // Method to check if a user is signed in
    func isUserSignedIn() -> Bool {
        return user != nil
    }
    
    // Method to clear any authentication errors
    func clearError() {
        error = nil
    }
}
