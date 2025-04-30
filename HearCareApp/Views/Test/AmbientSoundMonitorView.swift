//
//  AmbientSoundMonitorView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 22/4/2568 BE.
//  Updated with improved calibration and visualization

import SwiftUI

struct AmbientSoundMonitorView: View {
    @ObservedObject var soundService = AmbientSoundService.shared
    @State private var showingInfoPopover = false
    
    // Define reference noise levels for better context
    private let referenceNoises: [(level: Int, description: String)] = [
        (10, "Breathing"),
        (20, "Whisper"),
        (30, "Quiet library"),
        (40, "Quiet office"),
        (50, "Conversation"),
        (60, "Busy restaurant"),
        (70, "Vacuum cleaner"),
        (80, "City traffic"),
        (90, "Motorcycle"),
        (100, "Concert")
    ]
    
    // Threshold limits for visual feedback
    private let acceptableLimit: Float = 35.0
    private let moderateLimit: Float = 50.0
    private let excessiveLimit: Float = 65.0
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header with title and info button
            HStack {
                Image(systemName: soundService.ambientNoiseLevel.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(soundService.ambientNoiseLevel.color))
                
                Text("Ambient Noise Level")
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Button(action: {
                    showingInfoPopover = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .popover(isPresented: $showingInfoPopover) {
                    noiseInfoView
                        .frame(width: 300, height: 350)
                        .padding()
                }
                
                Text(soundService.ambientNoiseLevel.rawValue)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(Color(soundService.ambientNoiseLevel.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(Color(soundService.ambientNoiseLevel.color).opacity(0.2))
                    )
            }
            
            // Advanced sound level meter with thresholds
            VStack(spacing: 2) {
                // Main meter
                ZStack(alignment: .leading) {
                    // Background track with threshold markers
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 16)
                        .cornerRadius(AppTheme.Radius.small)
                        .overlay(
                            HStack(spacing: 0) {
                                // Create threshold markers
                                createThresholdMarkers()
                            }
                        )
                    
                    // Fill based on current decibel level with gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green,
                                    Color.green.opacity(0.8),
                                    Color.yellow.opacity(0.9),
                                    Color.orange,
                                    Color.red
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: calculateWidth(), height: 16)
                        .cornerRadius(AppTheme.Radius.small)
                    
                    // Current level indicator
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 20)
                        .offset(x: calculateWidth() - 1)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 0)
                }
                
                // Scale labels
                HStack(spacing: 0) {
                    Text("0")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("25")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("50")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("75")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("100 dB")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(height: 16)
            }
            
            // Current noise information
            VStack(spacing: 4) {
                HStack {
                    Text("\(Int(soundService.currentDecibels)) dB")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(levelColor())
                    
                    Text("(\(getSimilarNoiseDescription()))")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                }
                
                HStack {
                    Text(soundService.ambientNoiseLevel.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            
            // Suitability indicator
            if soundService.isEnvironmentSuitableForTesting() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Environment is suitable for testing")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.top, 4)
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    
                    Text("Environment is too noisy for accurate testing")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            soundService.startMonitoring()
        }
        .onChange(of: soundService.permissionStatus) { newStatus in
            // If permission changes during view lifetime, update monitoring
            if newStatus == .granted && !soundService.isMonitoring {
                soundService.startMonitoring()
            }
        }
    }
    
    // Noise info popover content
    private var noiseInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Noise Measurement")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text("HearCare uses your device's microphone to measure ambient noise levels. For accurate hearing tests, you should be in an environment with noise levels below 35 dB.")
                .font(.callout)
            
            Divider()
                .padding(.vertical, 4)
            
            Text("Reference Noise Levels:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(referenceNoises, id: \.level) { noise in
                        HStack {
                            Text("\(noise.level) dB:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(noise.description)
                                .font(.caption)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            Text("Note: This is an approximate measurement and can vary between different devices.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    // Create threshold markers for the sound meter
    private func createThresholdMarkers() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Acceptable threshold
                Rectangle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: calculateThresholdPosition(threshold: acceptableLimit, in: geometry.size.width), height: 16)
                
                // Moderate threshold line
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 16)
                    .offset(x: calculateThresholdPosition(threshold: moderateLimit, in: geometry.size.width) - 1)
                
                // Excessive threshold line
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: 16)
                    .offset(x: calculateThresholdPosition(threshold: excessiveLimit, in: geometry.size.width) - 1)
            }
        }
    }
    
    // Calculate position for threshold markers
    private func calculateThresholdPosition(threshold: Float, in width: CGFloat) -> CGFloat {
        let maxValue: Float = 100.0
        let position = CGFloat(min(threshold / maxValue, 1.0)) * width
        return position
    }
    
    // Calculate the width of the filled portion of the progress bar
    private func calculateWidth() -> CGFloat {
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 40 // Adjust for padding
        let progress = CGFloat(min(soundService.currentDecibels / 100.0, 1.0))
        return maxWidth * progress
    }
    
    // Determine the color based on the current noise level
    private func levelColor() -> Color {
        switch soundService.ambientNoiseLevel {
        case .acceptable:
            return Color.green
        case .moderate:
            return Color.yellow
        case .excessive:
            return Color.red
        }
    }
    
    // Get a description of a similar noise at the current level
    private func getSimilarNoiseDescription() -> String {
        let currentLevel = Int(soundService.currentDecibels)
        
        // Find the closest reference noise
        let sortedByDistance = referenceNoises.sorted {
            abs($0.level - currentLevel) < abs($1.level - currentLevel)
        }
        
        if let closestNoise = sortedByDistance.first {
            return closestNoise.description
        }
        
        return "Unknown"
    }
}

// Preview with environment states for development
struct AmbientSoundMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for acceptable noise level
            let acceptableService = mockSoundService(level: 25, status: .acceptable)
            AmbientSoundMonitorView(soundService: acceptableService)
                .previewDisplayName("Acceptable Noise")
            
            // Preview for moderate noise level
            let moderateService = mockSoundService(level: 45, status: .moderate)
            AmbientSoundMonitorView(soundService: moderateService)
                .previewDisplayName("Moderate Noise")
            
            // Preview for excessive noise level
            let excessiveService = mockSoundService(level: 75, status: .excessive)
            AmbientSoundMonitorView(soundService: excessiveService)
                .previewDisplayName("Excessive Noise")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
    
    // Helper function to create mock sound services for previews
    static func mockSoundService(level: Float, status: AmbientSoundService.NoiseLevel) -> AmbientSoundService {
        let mockService = AmbientSoundService()
        mockService.currentDecibels = level
        mockService.ambientNoiseLevel = status
        mockService.isMonitoring = true
        mockService.permissionStatus = .granted
        return mockService
    }
}
