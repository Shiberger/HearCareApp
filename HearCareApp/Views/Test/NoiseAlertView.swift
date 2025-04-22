//
//  NoiseAlertView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 22/4/2568 BE.
//  Fixed UI layout and button functionality issues.
//

import SwiftUI

struct NoiseAlertView: View {
    @ObservedObject var soundService = AmbientSoundService.shared
    @Binding var isPresented: Bool
    var onTestAnyway: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            HStack {
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal)
            
            Image(systemName: "volume.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Environment Too Noisy")
                .font(AppTheme.Typography.title3)
                .multilineTextAlignment(.center)
            
//            Text("The current noise level (\(Int(soundService.currentDecibels)) dB) is too high for accurate hearing testing.")
//                .font(AppTheme.Typography.body)
//                .foregroundColor(AppTheme.textSecondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
            
            // Tips to reduce noise
//            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//                Text("Tips to reduce noise:")
//                    .font(AppTheme.Typography.headline)
//                    .padding(.bottom, 4)
//                
//                tipRow(number: 1, text: "Move to a quieter room or location")
//                tipRow(number: 2, text: "Turn off fans, air conditioners, and other appliances")
//                tipRow(number: 3, text: "Close windows and doors to reduce outside noise")
//                tipRow(number: 4, text: "Wait for a quieter time if there's temporary noise")
//            }
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
//                    .fill(Color.red.opacity(0.1))
//            )
//            .padding(.horizontal)
            
            // Noise level monitor
            AmbientSoundMonitorView()
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Button(action: {
                    // Call the provided action before dismissing
                    onTestAnyway()
                    isPresented = false
                }) {
                    Text("Test Anyway")
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
                
                Button(action: {
                    // Check if environment is now acceptable
                    if soundService.isEnvironmentSuitableForTesting() {
                        isPresented = false
                    }
                    // Otherwise, keep showing the alert as the environment is still too noisy
                }) {
                    Text("Retry")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(AppTheme.Radius.medium)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.medium) // Add bottom padding to avoid cut-off
        }
        .padding(.vertical, AppTheme.Spacing.large)
        .background(AppTheme.backgroundColor)
        .cornerRadius(AppTheme.Radius.large)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 40) // Add vertical padding to avoid taking up the entire screen
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the alert
    }
    
    private func tipRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(AppTheme.Typography.body)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.red))
                .alignmentGuide(.leading) { $0[.leading] }
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
}

struct NoiseAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            NoiseAlertView(isPresented: .constant(true), onTestAnyway: {})
        }
    }
}
