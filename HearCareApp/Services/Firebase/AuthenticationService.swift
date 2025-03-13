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
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])
            isAuthenticating = false
            return
        }
        
        let configuration = GIDConfiguration(clientID: clientID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            isAuthenticating = false
            return
        }
        
        // Fixed GIDSignIn method call
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error
                self.isAuthenticating = false
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication token not found"])
                self.isAuthenticating = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                self.isAuthenticating = false
                
                if let error = error {
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
        guard let user = user else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking user document: \(error.localizedDescription)")
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
                userData["hearingConditions"] = [] as [String] // Fixed: Explicitly type as [String]
            }
            
            // Set or update the user document
            userRef.setData(userData, merge: true) { error in
                if let error = error {
                    print("Error updating user document: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            
            // Fixed: Correct method for signing out of Google
            GIDSignIn.sharedInstance.disconnect { error in
                if let error = error {
                    print("Error disconnecting from Google: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.user = nil
            }
        } catch let error {
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
