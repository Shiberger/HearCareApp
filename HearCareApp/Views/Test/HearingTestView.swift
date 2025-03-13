//
//  HearingTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI

struct HearingTestView: View {
    @StateObject private var audioService = AudioService()
    @State private var testStage: TestStage = .instructions
    @State private var selectedEar: AudioService.Ear = .right
    @State private var progress: CGFloat = 0.0
    @State private var shouldShowHearingButtons = false
    @State private var currentFrequencyIndex = 0
    @State private var currentVolumeLevel = 0
    @State private var currentEarIndex = 0
    
    // Define volume levels from lowest to highest
    private let volumeLevels: [Float] = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    private let frequencies: [Float] = [250, 500, 1000, 2000, 4000, 8000]
    private let maxSteps = 12 // 6 frequencies for each ear
    
    enum TestStage {
        case instructions
        case preparation
        case testing
        case results
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch testStage {
            case .instructions:
                instructionsView
            case .preparation:
                preparationView
            case .testing:
                testingView
            case .results:
                resultsView
            }
        }
        .navigationTitle("Hearing Test")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if testStage == .testing {
                    Button("Stop Test") {
                        audioService.stop()
                        testStage = .instructions
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Views based on Figma design
    
    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Image("hearing_test_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(.top, AppTheme.Spacing.large)
                
                Text("Hearing Test Instructions")
                    .font(AppTheme.Typography.title2)
                    .padding(.horizontal)
                
                InfoCard(title: "Before You Begin", icon: "checkmark.circle") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        instructionRow(number: 1, text: "Find a quiet environment")
                        instructionRow(number: 2, text: "Put on headphones (recommended)")
                        instructionRow(number: 3, text: "Set your device volume to 50-70%")
                        instructionRow(number: 4, text: "The test will take approximately 5-8 minutes")
                    }
                }
                
                InfoCard(title: "How It Works", icon: "ear") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        instructionRow(number: 1, text: "You will hear a series of tones at different frequencies")
                        instructionRow(number: 2, text: "Tap 'Yes' if you can hear the tone, even if it's very faint")
                        instructionRow(number: 3, text: "Tap 'No' if you don't hear anything")
                        instructionRow(number: 4, text: "The test will alternate between right and left ears")
                    }
                }
                
                Spacer(minLength: AppTheme.Spacing.extraLarge)
                
                PrimaryButton(title: "Begin Test", icon: "play.fill") {
                    testStage = .preparation
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
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
    
    private var preparationView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .padding()
            
            Text("Prepare for your hearing test")
                .font(AppTheme.Typography.title3)
                .multilineTextAlignment(.center)
            
            Text("Make sure you're wearing headphones and are in a quiet environment.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.extraLarge)
            
            Spacer()
            
            VStack {
                Text("Select which ear to test first")
                    .font(AppTheme.Typography.headline)
                    .padding(.bottom)
                
                EarSelectionView(selectedEar: $selectedEar)
            }
            .padding()
            
            Spacer()
            
            PrimaryButton(title: "Start Test", icon: "play.fill") {
                testStage = .testing
                startTest()
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
    
    private var testingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Progress indicator
            VStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryColor))
                    .padding(.horizontal)
                
                HStack {
                    Text("Progress: \(Int(progress * 100))%")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Testing \(selectedEar == .right ? "Right" : "Left") Ear")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedEar == .right ? .blue : .red)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Current frequency and ear indicator
            VStack(spacing: AppTheme.Spacing.medium) {
                if audioService.isPlaying {
                    Text("Listen carefully")
                        .font(AppTheme.Typography.title3)
                    
                    Text("Do you hear this tone?")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Get ready")
                        .font(AppTheme.Typography.title3)
                    
                    Text("Next tone coming soon...")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Audio visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(selectedEar == .right ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                if audioService.isPlaying {
                    // Animated rings when sound is playing
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(selectedEar == .right ? Color.blue.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 2)
                            .frame(width: CGFloat(140 + (index * 30)), height: CGFloat(140 + (index * 30)))
                            .scaleEffect(audioService.isPlaying ? 1.0 : 0.8)
                            .opacity(audioService.isPlaying ? 0.6 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: audioService.isPlaying
                            )
                    }
                }
                
                Image(systemName: selectedEar == .right ? "ear.fill" : "ear.fill")
                    .font(.system(size: 60))
                    .foregroundColor(selectedEar == .right ? .blue : .red)
                    .rotationEffect(selectedEar == .right ? .zero : .degrees(180))
            }
            
            // Response buttons
            if shouldShowHearingButtons {
                HStack(spacing: AppTheme.Spacing.large) {
                    Button(action: {
                        respondToTone(heard: false)
                    }) {
                        Text("No")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.red)
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                    
                    Button(action: {
                        respondToTone(heard: true)
                    }) {
                        Text("Yes")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.green)
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                }
                .padding(.top, AppTheme.Spacing.large)
            }
            
            Spacer()
            
            // Frequency indicator
            if audioService.isPlaying {
                VStack {
                    Text("\(Int(audioService.currentFrequency)) Hz")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    // Debug info - can be removed in production
                    if let volume = volumeLevels[safe: currentVolumeLevel] {
                        Text("Volume: \(Int(volume * 100))%")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
        .padding()
    }
    
    // In HearingTestView.swift, update the resultsView

    private var resultsView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            
            Text("Test Completed!")
                .font(AppTheme.Typography.title2)
            
            Text("Your results are being processed")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            ProgressView()
                .padding()
            
            Spacer()
            
            NavigationLink(
                destination: DetailedResultsView(testResults: audioService.userResponses)
                    .onAppear {
                        // Save test results to Firestore when viewing results
                        saveTestResults()
                    }
            ) {
                Text("View Detailed Results")
                    .primaryButton()
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .padding()
        .onAppear {
            // Alternative: Save test results as soon as the results view appears
            saveTestResults()
        }
    }

    // Add this function to HearingTestView.swift
    private func saveTestResults() {
        // Create a FirestoreService instance
        let firestoreService = FirestoreService()
        
        // Process the test results
        let resultsProcessor = ResultsProcessor()
        let processedResults = resultsProcessor.processResults(from: audioService.userResponses)
        
        // Create a test result document
        var testResult: [String: Any] = [
            "testDate": Date(),
            "rightEarClassification": processedResults.rightEarClassification.displayName,
            "leftEarClassification": processedResults.leftEarClassification.displayName,
            "recommendations": processedResults.recommendations,
            "rightEarData": processedResults.rightEarHearingLevel.map { [
                "frequency": $0.key,
                "hearingLevel": $0.value
            ]},
            "leftEarData": processedResults.leftEarHearingLevel.map { [
                "frequency": $0.key,
                "hearingLevel": $0.value
            ]}
        ]
        
        // Save the test result to Firestore
        firestoreService.saveTestResultForCurrentUser(testResult) { result in
            switch result {
            case .success:
                print("Test results saved successfully to Firestore")
            case .failure(let error):
                print("Failed to save test results: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Test Logic
    
    // Start with the LOWEST volume (important!) and increase until heard
    private func startTest() {
        // Reset all test variables
        progress = 0.0
        currentFrequencyIndex = 0
        currentVolumeLevel = 0  // Start with the lowest volume
        currentEarIndex = 0
        
        // Set initial ear based on user selection
        if selectedEar == .right {
            currentEarIndex = 0
        } else {
            currentEarIndex = 1
        }
        
        // Reset responses
        audioService.userResponses = []
        
        // Start the test sequence
        playCurrentTone()
    }
    
    private func playCurrentTone() {
        // Update progress (based on frequency progression, not volume)
        let totalFrequencies = frequencies.count * 2 // 6 frequencies for each ear
        let completedFrequencies = (currentEarIndex * frequencies.count) + currentFrequencyIndex
        progress = CGFloat(completedFrequencies) / CGFloat(totalFrequencies)
        
        // Get current frequency
        let frequency = frequencies[currentFrequencyIndex]
        
        // Get current ear
        selectedEar = currentEarIndex == 0 ? .right : .left
        
        // Get current volume
        let volume = volumeLevels[currentVolumeLevel]
        
        shouldShowHearingButtons = false
        
        // Short delay before playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            audioService.generateTone(frequency: frequency, volume: volume, ear: selectedEar)
            
            // Show response buttons after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shouldShowHearingButtons = true
            }
            
            // Auto-timeout after 5 seconds if no response
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if audioService.isPlaying {
                    respondToTone(heard: false)
                }
            }
        }
    }
    
    private func respondToTone(heard: Bool) {
        audioService.stop()
        shouldShowHearingButtons = false
        
        if heard {
            // User heard the tone - record response with current settings
            let currentVolume = volumeLevels[currentVolumeLevel]
            let currentFrequency = frequencies[currentFrequencyIndex]
            audioService.recordResponse(
                heard: true,
                frequency: currentFrequency,
                volumeHeard: currentVolume,
                ear: selectedEar
            )
            
            // Move to the next frequency
            moveToNextFrequency()
        } else {
            // User didn't hear the tone - try a higher volume
            if currentVolumeLevel < volumeLevels.count - 1 {
                // Increase volume and try again with the same frequency
                currentVolumeLevel += 1
                
                // Play the same frequency at higher volume
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    playCurrentTone()
                }
            } else {
                // Maximum volume reached but still not heard
                // Record "not heard" at max volume
                let currentFrequency = frequencies[currentFrequencyIndex]
                audioService.recordResponse(
                    heard: false,
                    frequency: currentFrequency,
                    volumeHeard: Float.infinity, // Special value to indicate "not heard"
                    ear: selectedEar
                )
                
                // Move to the next frequency
                moveToNextFrequency()
            }
        }
    }
    
    private func moveToNextFrequency() {
        // Reset volume for next frequency
        currentVolumeLevel = 0
        
        // Move to next frequency
        currentFrequencyIndex += 1
        
        // Check if we've completed all frequencies for current ear
        if currentFrequencyIndex >= frequencies.count {
            currentFrequencyIndex = 0 // Reset frequency index
            currentEarIndex += 1 // Move to next ear
            
            // Check if we've completed both ears
            if currentEarIndex >= 2 {
                // Test complete
                testStage = .results
                return
            }
        }
        
        // Play the next tone
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            playCurrentTone()
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// This extension assumes you'll update the AudioService to handle this method
extension AudioService {
    func recordResponse(heard: Bool, frequency: Float, volumeHeard: Float, ear: Ear) {
        let response = TestResponse(
            frequency: frequency,
            volumeHeard: volumeHeard,
            ear: ear,
            timestamp: Date()
        )
        userResponses.append(response)
    }
}
