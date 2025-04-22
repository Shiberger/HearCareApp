//
//  MicrophonePermissionView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 22/4/2568 BE.
//

import SwiftUI

struct MicrophonePermissionView: View {
    @ObservedObject var soundService = AmbientSoundService.shared
    @Binding var permissionGranted: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .padding(.bottom, AppTheme.Spacing.large)
            
            Text("Microphone Access Required")
                .font(AppTheme.Typography.title2)
                .multilineTextAlignment(.center)
            
            Text("To ensure accurate hearing test results, we need to check your environment's noise level. Please grant microphone access when prompted.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                benefitRow(icon: "checkmark.circle.fill", text: "Ensures test accuracy by measuring background noise")
                benefitRow(icon: "checkmark.circle.fill", text: "Provides guidance to find a quiet environment")
                benefitRow(icon: "checkmark.circle.fill", text: "Helps produce more reliable hearing test results")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal)
            
            Text("We only use your microphone for ambient noise detection. No audio is recorded or stored.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.medium)
            
            Spacer()
            
            Button(action: {
                requestPermission()
            }) {
                Text("Continue")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor)
                    .cornerRadius(AppTheme.Radius.medium)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, AppTheme.Spacing.large)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .onAppear {
            // Check current permission status
            checkPermissionStatus()
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
    
    private func checkPermissionStatus() {
        soundService.checkPermissionStatus()
        permissionGranted = soundService.permissionStatus == .granted
    }
    
    private func requestPermission() {
        soundService.requestMicrophonePermission { granted in
            permissionGranted = granted
        }
    }
}

struct MicrophonePermissionView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophonePermissionView(permissionGranted: .constant(false))
    }
}
