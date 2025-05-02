//
//  ThemeManager.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// ThemeManager.swift
import SwiftUI

struct AppTheme {
    // Colors
    static let primaryColor = Color("PrimaryColor")
    static let secondaryColor = Color("SecondaryColor")
    static let accentColor = Color("AccentColor")
    static let backgroundColor = Color("BackgroundColor")
    static let cardColor = Color("CardColor")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // Typography
    struct Typography {
        static let largeTitle = Font.custom("SFProDisplay-Bold", size: 34)
        static let title1 = Font.custom("SFProDisplay-Bold", size: 28)
        static let title2 = Font.custom("SFProDisplay-Bold", size: 22)
        static let title3 = Font.custom("SFProDisplay-SemiBold", size: 20)
        static let headline = Font.custom("SFProDisplay-SemiBold", size: 17)
        static let body = Font.custom("SFProDisplay-Regular", size: 17)
        static let callout = Font.custom("SFProDisplay-Regular", size: 16)
        static let subheadline = Font.custom("SFProDisplay-Regular", size: 15)
        static let footnote = Font.custom("SFProDisplay-Regular", size: 13)
        static let caption = Font.custom("SFProDisplay-Regular", size: 12)
    }
    
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // Shadows
    static func cardShadow() -> some View {
        return RoundedRectangle(cornerRadius: Radius.medium)
            .fill(backgroundColor)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Extension for View modifiers
extension View {
    func primaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryColor)
            .cornerRadius(AppTheme.Radius.medium)
    }
    
    func secondaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.primaryColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(AppTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(AppTheme.primaryColor, lineWidth: 1)
            )
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(AppTheme.cardShadow())
            .padding(.horizontal)
    }
}
