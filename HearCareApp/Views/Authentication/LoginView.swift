//
//  LoginView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI
import GoogleSignIn
import WebKit

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var retryCount = 0
    @State private var showingRetryAlert = false
    
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
                authService.clearError() // Clear any previous errors
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
                VStack {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    
                    if retryCount < 3 {
                        Button("Retry Sign In") {
                            retryCount += 1
                            resetAuthenticationState()
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
            
            // Add a "More Options" button for troubleshooting
            Button(action: {
                showingRetryAlert = true
            }) {
                Text("Need help signing in?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color("BackgroundColor").ignoresSafeArea())
        .alert(isPresented: $showingRetryAlert) {
            Alert(
                title: Text("Sign-in Options"),
                message: Text("Would you like to try signing in again or reset the authentication process?"),
                primaryButton: .default(Text("Reset & Retry")) {
                    resetAuthenticationState()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    private func resetAuthenticationState() {
        // Clear web data with the correct WKWebsiteDataType constants
        let websiteDataTypes = Set([
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache
        ])
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes,
                                              modifiedSince: Date(timeIntervalSince1970: 0)) {
            // Now try the sign-in again
            DispatchQueue.main.async {
                authService.clearError()
                authService.signInWithGoogle()
            }
        }
    }
}
