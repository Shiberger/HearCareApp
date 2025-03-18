//
//  AuthenticationService+Extensions.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 18/3/2568 BE.
//

import Foundation
import FirebaseAuth

// Extension to the existing AuthenticationService class
extension AuthenticationService {
    // Method to refresh user data when profile information is updated
    func refreshUserData() {
        // Force refresh the current user data from Firebase
        Auth.auth().currentUser?.reload { [weak self] error in
            if let error = error {
                print("Error refreshing user data: \(error.localizedDescription)")
                return
            }
            
            // Update the local user property with the refreshed data
            self?.user = Auth.auth().currentUser
        }
    }
}
