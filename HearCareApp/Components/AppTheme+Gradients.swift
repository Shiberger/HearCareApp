//
//  AppTheme+Gradients.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 8/5/2568 BE.
//

import SwiftUI

extension AppTheme {
    // Brighter pastel colors with increased saturation
    struct Gradients {
        // Original pastel colors but with increased saturation and brightness
        static let pastelBlue = Color(red: 174/255, green: 198/255, blue: 1.0)      // Increased blue component
        static let pastelGreen = Color(red: 181/255, green: 1.0, blue: 215/255)     // Increased green component
        static let pastelYellow = Color(red: 1.0, green: 240/255, blue: 179/255)    // Increased red component
        static let pastelPurple = Color(red: 0.95, green: 0.85, blue: 1.0)          // Increased saturation
        static let pastelRed = Color(red: 1.0, green: 180/255, blue: 180/255)       // Same but appears brighter
        static let pastelOrange = Color(red: 1.0, green: 210/255, blue: 170/255)    // Same but appears brighter
        
        // Main background gradient - brighter version
        static var mainBackground: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [
                    pastelBlue.opacity(0.8),     // Increased opacity from 0.6
                    pastelGreen.opacity(0.7)     // Increased opacity from 0.5
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Login screen gradient - brighter version
        static var loginBackground: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [
                    pastelBlue.opacity(0.9),    // Increased opacity from 0.8
                    pastelGreen.opacity(0.7)    // Increased opacity from 0.6
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Secondary background gradient - for variety
        static var secondaryBackground: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [
                    pastelPurple.opacity(0.8),
                    pastelBlue.opacity(0.7)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// Extension to access gradients using View modifiers
extension View {
    func mainGradientBackground() -> some View {
        self.background(
            AppTheme.Gradients.mainBackground
                .ignoresSafeArea()
        )
    }
    
    func loginGradientBackground() -> some View {
        self.background(
            AppTheme.Gradients.loginBackground
                .ignoresSafeArea()
        )
    }
    
    func secondaryGradientBackground() -> some View {
        self.background(
            AppTheme.Gradients.secondaryBackground
                .ignoresSafeArea()
        )
    }
}
