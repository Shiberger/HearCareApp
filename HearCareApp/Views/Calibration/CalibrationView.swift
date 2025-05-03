//
//  CalibrationView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import SwiftUI

struct CalibrationView: View {
    @ObservedObject private var calibrationService = CalibrationService.shared
    @StateObject private var audioService = AudioService()
    @State private var currentStep = 0
    @State private var sliderValue: Float = 0.5
    @State private var isPlaying = false
    @State private var selectedEar: AudioService.Ear = .right
    @State private var showingHeadphoneWarning = false
    @State private var showingCompletionAlert = false
    
    // Steps for calibration process
    private let steps = [
        "Introduction",
        "Headphone Check",
        "Level Adjustment",
        "Confirmation",
        "Completion"
    ]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header
            Text("Device Calibration")
                .font(AppTheme.Typography.title2)
                .padding(.top)
            
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? AppTheme.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, AppTheme.Spacing.small)
            
            // Current step label
            Text(steps[currentStep])
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.primaryColor)
                .padding(.bottom)
            
            // Content area
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Step-specific content
                    getContentForStep(currentStep)
                }
                .padding()
            }
            
            Spacer()
            
            // Navigation buttons
            getNavigationButtons()
        }
        .padding()
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start calibration process
            calibrationService.startCalibration(with: audioService)
        }
        .onDisappear {
            // Stop any playing tones
            calibrationService.stopTone()
        }
        .alert(isPresented: $showingHeadphoneWarning) {
            Alert(
                title: Text("Headphones Recommended"),
                message: Text("For accurate calibration and testing, please use headphones. Do you want to continue without headphones?"),
                primaryButton: .default(Text("Continue Anyway")) {
                    currentStep += 1
                },
                secondaryButton: .cancel(Text("I'll Get Headphones"))
            )
        }
    }
    
    // MARK: - Step-specific content
    
    @ViewBuilder
    private func getContentForStep(_ step: Int) -> some View {
        switch step {
        case 0:
            introductionStepContent
        case 1:
            headphoneCheckStepContent
        case 2:
            levelAdjustmentStepContent
        case 3:
            confirmationStepContent
        case 4:
            completionStepContent
        default:
            EmptyView()
        }
    }
    
    private var introductionStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "tuningfork")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Welcome to Calibration")
                .font(AppTheme.Typography.title3)
            
            Text("Calibration helps ensure your hearing test results are accurate by adjusting for your specific device and headphones.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                calibrationInfoRow(number: 1, text: "Find a quiet environment")
                calibrationInfoRow(number: 2, text: "Use headphones for best results")
                calibrationInfoRow(number: 3, text: "Set your device volume to around 50%")
                calibrationInfoRow(number: 4, text: "This process takes about 2 minutes")
            }
            .padding(.vertical)
            
            Text("Your device: \(UIDevice.current.model)")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    private var headphoneCheckStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Headphone Check")
                .font(AppTheme.Typography.title3)
            
            Text("Please connect headphones to your device for accurate calibration and testing.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack {
                Image(systemName: calibrationService.headphoneModel == "No headphones detected" ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(calibrationService.headphoneModel == "No headphones detected" ? .red : .green)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading) {
                    Text(calibrationService.headphoneModel == "No headphones detected" ? "No Headphones Detected" : "Headphones Connected")
                        .font(AppTheme.Typography.headline)
                    
                    if calibrationService.headphoneModel != "No headphones detected" {
                        Text(calibrationService.headphoneModel)
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            Text("Headphones ensure that sound is delivered directly to your ears at consistent levels. Using device speakers can result in less accurate test results.")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
        }
    }
    
    private var levelAdjustmentStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Adjust Reference Level")
                .font(AppTheme.Typography.title3)
            
            Text("You will hear a reference tone at 1000 Hz. Adjust the slider until the tone is just barely audible - at the softest level you can hear clearly.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            // Ear selection
            earSelectionView
                .padding(.vertical)
            
            // Tone controls
            VStack(spacing: AppTheme.Spacing.medium) {
                Button(action: toggleTone) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                        Text(isPlaying ? "Stop Tone" : "Play Reference Tone")
                            .font(AppTheme.Typography.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isPlaying ? Color.red : AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.medium)
                }
                
                // Volume adjustment slider
                Text("Adjust the level")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                VStack {
                    Slider(value: $sliderValue, in: 0.01...1.0) { editing in
                        if !editing && isPlaying {
                            // Update the playing tone when slider is released
                            calibrationService.playCalibrationTone(volume: sliderValue, ear: selectedEar)
                        }
                    }
                    
                    HStack {
                        Text("Softer")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("Louder")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            
            Text("This calibration tone is set at a reference level of 40 dB. Adjusting it to be just audible helps us determine the correct volume settings for your device.")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
        }
    }
    
    private var confirmationStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Confirm Calibration Level")
                .font(AppTheme.Typography.title3)
            
            Text("Let's verify your calibration setting. We'll play the reference tone at the level you selected. You should be able to hear it clearly, but it should still be soft.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            // Ear selection
            earSelectionView
                .padding(.vertical)
            
            // Confirmation controls
            VStack(spacing: AppTheme.Spacing.medium) {
                Button(action: toggleTone) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                        Text(isPlaying ? "Stop Tone" : "Play Calibration Tone")
                            .font(AppTheme.Typography.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isPlaying ? Color.red : AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.medium)
                }
                
                // Display selected level
                HStack {
                    Text("Selected Level:")
                        .font(AppTheme.Typography.body)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", sliderValue))
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.primaryColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            
            // Confirmation questions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Can you answer these questions:")
                    .font(AppTheme.Typography.subheadline)
                
                Text("1. Is the tone clearly audible but still soft?")
                    .font(AppTheme.Typography.body)
                
                Text("2. Would you be able to detect this tone in a quiet room?")
                    .font(AppTheme.Typography.body)
                
                Text("If you answered 'yes' to both questions, your calibration is good. If not, go back and adjust the level.")
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var completionStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Calibration Complete!")
                .font(AppTheme.Typography.title3)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Device:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(UIDevice.current.model)
                        .font(AppTheme.Typography.body)
                }
                
                Divider()
                
                HStack {
                    Text("Headphones:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(calibrationService.headphoneModel)
                        .font(AppTheme.Typography.body)
                }
                
                Divider()
                
                HStack {
                    Text("Calibration Level:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", sliderValue))
                        .font(AppTheme.Typography.body)
                }
                
                Divider()
                
                HStack {
                    Text("Date:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(Date(), style: .date)
                        .font(AppTheme.Typography.body)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            Text("Your device is now calibrated for accurate hearing tests. Remember to recalibrate if you change headphones or if it's been more than 3 months since your last calibration.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
            
            Text("Calibration improves the accuracy of your hearing tests by ensuring that the sounds are played at the correct levels for your specific device and headphones.")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.small)
        }
    }
    
    // MARK: - Helper Views
    
    private var earSelectionView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Select Ear")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.large) {
                Button(action: {
                    selectedEar = .left
                    if isPlaying {
                        calibrationService.playCalibrationTone(volume: sliderValue, ear: .left)
                    }
                }) {
                    VStack {
                        Image(systemName: "ear.fill")
                            .font(.system(size: 28))
                            .foregroundColor(selectedEar == .left ? .blue : .gray)
                        
                        Text("Left Ear")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(selectedEar == .left ? .blue : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(selectedEar == .left ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(selectedEar == .left ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: {
                    selectedEar = .right
                    if isPlaying {
                        calibrationService.playCalibrationTone(volume: sliderValue, ear: .right)
                    }
                }) {
                    VStack {
                        Image(systemName: "ear.fill")
                            .font(.system(size: 28))
                            .foregroundColor(selectedEar == .right ? .red : .gray)
                        
                        Text("Right Ear")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(selectedEar == .right ? .red : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(selectedEar == .right ? Color.red.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(selectedEar == .right ? Color.red : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private func calibrationInfoRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(AppTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.primaryColor))
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    
    @ViewBuilder
    private func getNavigationButtons() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Back button
            if currentStep > 0 {
                Button(action: {
                    if isPlaying {
                        toggleTone()
                    }
                    currentStep -= 1
                }) {
                    Text("Back")
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
            } else {
                // Empty spacer for consistent layout
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Next/Finish button
            Button(action: {
                handleNextButtonTap()
            }) {
                Text(currentStep == steps.count - 1 ? "Finish" : "Next")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor)
                    .cornerRadius(AppTheme.Radius.medium)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, AppTheme.Spacing.large)
    }
    
    // MARK: - Actions
    
    private func handleNextButtonTap() {
        // Stop any playing tone
        if isPlaying {
            toggleTone()
        }
        
        switch currentStep {
        case 0:
            // Intro -> Headphone Check
            currentStep += 1
            
        case 1:
            // Headphone Check -> Level Adjustment
            // Check if headphones are connected, warn if not
            if calibrationService.headphoneModel == "No headphones detected" {
                showingHeadphoneWarning = true
            } else {
                currentStep += 1
            }
            
        case 2:
            // Level Adjustment -> Confirmation
            currentStep += 1
            
        case 3:
            // Confirmation -> Completion
            // Save calibration settings
            calibrationService.setCalibrationLevel(sliderValue)
            currentStep += 1
            
        case 4:
            // Completion -> Finish
            showingCompletionAlert = true
            
            // Navigate back or dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Return to previous screen
                // This would typically use a navigation binding or dismiss action
                // For now, we'll just show an alert
            }
            
        default:
            break
        }
    }
    
    private func toggleTone() {
        if isPlaying {
            calibrationService.stopTone()
            isPlaying = false
        } else {
            calibrationService.playCalibrationTone(volume: sliderValue, ear: selectedEar)
            isPlaying = true
        }
    }
}
