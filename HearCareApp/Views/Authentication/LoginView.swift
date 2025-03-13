//
//  LoginView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 20) {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text("HearCare")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Test and monitor your hearing health")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                authService.signInWithGoogle()
            }) {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text("Sign in with Google")
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
                .foregroundColor(.black)
            }
            .disabled(authService.isAuthenticating)
            
            if authService.isAuthenticating {
                ProgressView()
                    .padding()
            }
            
            if let error = authService.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .padding()
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}
