//
//  CalibrationCheckView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import SwiftUI

struct CalibrationCheckView: View {
    @StateObject private var testManager = HearingTestManager()
    @State private var calibrationStatus: HearingTestManager.CalibrationStatus = .calibrated
    @State private var navigateToCalibration = false
    @State private var navigateToTest = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Icon
            Image(systemName: getStatusIcon())
                .font(.system(size: 60))
                .foregroundColor(getStatusColor())
                .padding()
            
            // Title
            Text("Calibration Check")
                .font(AppTheme.Typography.title2)
                .multilineTextAlignment(.center)
            
            // Status message
            Text(calibrationStatus.message)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Device info
            calibrationInfoCard
                .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: AppTheme.Spacing.medium) {
                // Calibration button
                NavigationLink(destination: CalibrationView(), isActive: $navigateToCalibration) {
                    Button(action: {
                        navigateToCalibration = true
                    }) {
                        HStack {
                            Image(systemName: "tuningfork")
                            Text(getCalibrateButtonText())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.Radius.medium)
                    }
                }
                .padding(.horizontal)
                
                // Skip/Continue button
                if calibrationStatus != .needsCalibration {
                    NavigationLink(destination: HearingTestView(), isActive: $navigateToTest) {
                        Button(action: {
                            navigateToTest = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right")
                                Text(getContinueButtonText())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(AppTheme.textPrimary)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Calibration Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check calibration status when view appears
            calibrationStatus = testManager.checkCalibrationStatus()
        }
    }
    
    // MARK: - Helper Views
    
    private var calibrationInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Calibration status
            HStack {
                Text("Calibration Status:")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(getStatusText())
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(getStatusColor())
            }
            
            Divider()
            
            // Device info
            HStack {
                Text("Device:")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(UIDevice.current.model)
                    .font(AppTheme.Typography.body)
            }
            
            Divider()
            
            // Headphone info
            HStack {
                Text("Headphones:")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(CalibrationService.shared.headphoneModel)
                    .font(AppTheme.Typography.body)
            }
            
            // Only show calibration date if calibrated
            if let date = CalibrationService.shared.calibrationDate {
                Divider()
                
                HStack {
                    Text("Last Calibration:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(date, style: .date)
                        .font(AppTheme.Typography.body)
                }
                
                if let days = testManager.daysSinceCalibration {
                    Text("\(days) days ago")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(days > 90 ? .orange : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    
    private func getStatusIcon() -> String {
        switch calibrationStatus {
        case .calibrated:
            return "checkmark.circle.fill"
        case .needsCalibration:
            return "exclamationmark.triangle.fill"
        case .needsRecalibration:
            return "arrow.triangle.2.circlepath"
        case .recommendRecalibration:
            return "clock.fill"
        }
    }
    
    private func getStatusColor() -> Color {
        switch calibrationStatus {
        case .calibrated:
            return .green
        case .needsCalibration:
            return .red
        case .needsRecalibration:
            return .red
        case .recommendRecalibration:
            return .orange
        }
    }
    
    private func getStatusText() -> String {
        switch calibrationStatus {
        case .calibrated:
            return "Calibrated"
        case .needsCalibration:
            return "Not Calibrated"
        case .needsRecalibration:
            return "Needs Recalibration"
        case .recommendRecalibration:
            return "Recalibration Recommended"
        }
    }
    
    private func getCalibrateButtonText() -> String {
        switch calibrationStatus {
        case .calibrated:
            return "Recalibrate Device"
        case .needsCalibration:
            return "Calibrate Device"
        case .needsRecalibration:
            return "Recalibrate Device"
        case .recommendRecalibration:
            return "Recalibrate Device"
        }
    }
    
    private func getContinueButtonText() -> String {
        switch calibrationStatus {
        case .calibrated:
            return "Continue to Test"
        case .needsCalibration:
            return "" // No continue option
        case .needsRecalibration:
            return "Continue Anyway"
        case .recommendRecalibration:
            return "Continue Without Recalibrating"
        }
    }
}
