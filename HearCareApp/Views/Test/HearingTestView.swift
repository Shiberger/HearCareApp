//
//  HearingTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//  Updated with noise level check on 22/4/2568 BE.
//  Refactored to fix type-checking issues and accessibility
//

import SwiftUI

struct HearingTestView: View {
    @StateObject private var testManager = HearingTestManager()
    @State private var testStage: TestStage = .microphonePermission
    @State private var selectedEar: AudioService.Ear = .right
    @State private var microphonePermissionGranted = false
    @State private var showingNoiseAlert = false
    @State private var showingDebugInfo = false
    @ObservedObject private var soundService = AmbientSoundService.shared
    
    // Debug state
    @State private var debugLogMessages: [String] = []
    
    enum TestStage {
        case microphonePermission
        case instructions
        case preparation
        case testing
        case results
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Use switch to determine which view to display
            getMainContentForStage(testStage)
        }
        .navigationTitle("Hearing Test")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if testStage == .testing {
                    Menu {
                        Button("Stop Test") {
                            addDebugLog("User manually stopped test")
                            testManager.stopTest()
                            testStage = .instructions
                        }
                        
                        Toggle("Show Debug Info", isOn: $showingDebugInfo)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .overlay(
            ZStack {
                if showingNoiseAlert {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    NoiseAlertView(
                        isPresented: $showingNoiseAlert,
                        onTestAnyway: {
                            addDebugLog("User proceeding despite noise")
                            proceedToNextStage()
                        }
                    )
                }
            }
        )
    }
    
    // MARK: - Content Router
    
    private func getMainContentForStage(_ stage: TestStage) -> some View {
        switch stage {
        case .microphonePermission:
            return AnyView(
                MicrophonePermissionView(permissionGranted: $microphonePermissionGranted)
                    .onChange(of: microphonePermissionGranted) { granted in
                        if granted {
                            addDebugLog("Microphone permission granted")
                            soundService.startMonitoring()
                            testStage = .instructions
                        }
                    }
            )
        case .instructions:
            return AnyView(instructionsView)
        case .preparation:
            return AnyView(preparationView)
        case .testing:
            return AnyView(testingView)
        case .results:
            return AnyView(resultsView)
        }
    }
    
    // MARK: - Logging Helper
    
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        
        // Add to our debug log array
        debugLogMessages.append(logMessage)
        
        // Keep only the most recent 100 messages
        if debugLogMessages.count > 100 {
            debugLogMessages.removeFirst(debugLogMessages.count - 100)
        }
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Test illustration
                Image("hearing_test_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(.top, AppTheme.Spacing.large)
                
                // Title
                Text("Hearing Test Instructions")
                    .font(AppTheme.Typography.title2)
                    .padding(.horizontal)
                
                // Ambient noise monitor
                AmbientSoundMonitorView()
                    .padding(.horizontal)
                
                // Before you begin card
                createBeforeYouBeginCard()
                
                // How it works card
                createHowItWorksCard()
                
                Spacer(minLength: AppTheme.Spacing.extraLarge)
                
                // Begin test button
                PrimaryButton(title: "Begin Test", icon: "play.fill") {
                    addDebugLog("Begin Test button tapped")
                    checkEnvironmentNoise()
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
    }
    
    private func createBeforeYouBeginCard() -> some View {
        InfoCard(title: "Before You Begin", icon: "checkmark.circle") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                instructionRow(number: 1, text: "Find a quiet environment")
                instructionRow(number: 2, text: "Put on headphones (recommended)")
                instructionRow(number: 3, text: "Set your device volume to 50-70%")
                instructionRow(number: 4, text: "The test will take approximately 5-8 minutes")
            }
        }
    }
    
    private func createHowItWorksCard() -> some View {
        InfoCard(title: "How It Works", icon: "ear") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                instructionRow(number: 1, text: "You will hear a series of tones at different frequencies")
                instructionRow(number: 2, text: "Tap 'Yes' if you can hear the tone, even if it's very faint")
                instructionRow(number: 3, text: "Tap 'No' if you don't hear anything")
                instructionRow(number: 4, text: "The test will alternate between right and left ears")
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
    
    // MARK: - Environment Noise Check
    
    private func checkEnvironmentNoise() {
        // Ensure we're monitoring
        if !soundService.isMonitoring {
            soundService.startMonitoring()
            
            // Give the service a moment to get accurate readings
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                evaluateNoiseLevel()
            }
        } else {
            evaluateNoiseLevel()
        }
    }
    
    private func evaluateNoiseLevel() {
        let noiseLevel = Int(soundService.currentDecibels)
        let status = soundService.ambientNoiseLevel.rawValue
        
        addDebugLog("Evaluating noise: \(noiseLevel) dB (\(status))")
        
        if soundService.ambientNoiseLevel == .excessive {
            // Show noise alert
            showingNoiseAlert = true
        } else {
            // Environment is acceptable, proceed to preparation
            proceedToNextStage()
        }
    }
    
    // Helper method to proceed to the next stage
    private func proceedToNextStage() {
        // Determine which stage to go to next
        if testStage == .instructions {
            addDebugLog("Moving to preparation stage")
            testStage = .preparation
        } else if testStage == .preparation {
            addDebugLog("Moving to testing stage")
            testStage = .testing
        }
    }
    
    // MARK: - Preparation View
    
    private var preparationView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            // Instructions header
            prepInstructionsHeader
            
            // Ambient noise monitor
            AmbientSoundMonitorView()
                .padding(.horizontal)
            
            Spacer()
            
            // Ear selection
            earSelectionSection
            
            Spacer()
            
            // Start test button
            PrimaryButton(title: "Start Test", icon: "play.fill") {
                let ear = selectedEar == .right ? "Right" : "Left"
                addDebugLog("Starting test with \(ear) ear")
                
                // One final environment check before starting test
                if soundService.ambientNoiseLevel == .excessive {
                    showingNoiseAlert = true
                } else {
                    testStage = .testing
                }
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
    
    private var prepInstructionsHeader: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
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
        }
    }
    
    private var earSelectionSection: some View {
        VStack {
            Text("The test will start with your right ear")
                .font(AppTheme.Typography.headline)
                .padding(.bottom)
            
            EarSelectionView(selectedEar: .constant(.right)) // Force constant binding to right ear
                .disabled(true) // Optional: disable interaction
        }
        .padding()
    }
    
    // MARK: - Testing View
    
    private var testingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Progress section
            testProgressSection
            
            // Debug info section - conditionally shown
            if showingDebugInfo {
                testDebugInfoSection
            } else {
                // Basic info when debug is off
                HStack {
                    Text("Current Level: \(Int(testManager.currentDBLevel)) dB")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Current status text
            testStatusText
            
            // Audio visualization
            testAudioVisualization
            
            // Response buttons
            testResponseButtons
            
            Spacer()
            
            // Frequency indicator
            VStack {
                Text("\(Int(testManager.currentFrequency)) Hz")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .padding()
        .onAppear {
            // Start the test when the view appears
            if testManager.testStatus != .testing {
                addDebugLog("Starting hearing test")
                testManager.startTest(startingEar: selectedEar)
            }
            
            // Disable ambient sound monitoring during the test
            soundService.stopMonitoring()
        }
        .onChange(of: testManager.testStatus) { newStatus in
            addDebugLog("Test status changed: \(newStatus)")
            if newStatus == .complete {
                testStage = .results
            }
        }
    }
    
    private var testProgressSection: some View {
        VStack {
            // Progress bar
            ProgressView(value: CGFloat(testManager.progress))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryColor))
                .padding(.horizontal)
            
            // Progress info
            HStack {
                Text("Progress: \(Int(testManager.progress * 100))%")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                // Current ear indicator
                let earText = testManager.currentEar == .right ? "Right" : "Left"
                let earColor = testManager.currentEar == .right ? Color.blue : Color.red
                
                Text("Testing \(earText) Ear")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(earColor)
            }
            .padding(.horizontal)
        }
    }
    
    private var testDebugInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Frequency: \(Int(testManager.currentFrequency)) Hz")
                .font(.caption)
            Text("Level: \(Int(testManager.currentDBLevel)) dB")
                .font(.caption)
            Text("Status: \(String(describing: testManager.testStatus))")
                .font(.caption)
            Text("Ear: \(testManager.currentEar == .right ? "Right" : "Left")")
                .font(.caption)
            Text("Playing: \(testManager.isPlaying ? "Yes" : "No")")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var testStatusText: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if testManager.isPlaying {
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
    }
    
    private var testAudioVisualization: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                .frame(width: 200, height: 200)
            
            // Inner circle
            let fillColor = testManager.currentEar == .right ?
                Color.blue.opacity(0.1) : Color.red.opacity(0.1)
            
            Circle()
                .fill(fillColor)
                .frame(width: 180, height: 180)
            
            // Animation rings when playing
            if testManager.isPlaying {
                ForEach(0..<3, id: \.self) { index in
                    createAnimatedRing(index: index)
                }
            }
            
            // Ear icon
            let earColor = testManager.currentEar == .right ? Color.blue : Color.red
            let earRotation = testManager.currentEar == .right ?
                Angle(degrees: 0) : Angle(degrees: 180)
            
            Image(systemName: "ear.fill")
                .font(.system(size: 60))
                .foregroundColor(earColor)
                .rotationEffect(earRotation)
        }
    }
    
    private func createAnimatedRing(index: Int) -> some View {
        let ringColor = testManager.currentEar == .right ?
            Color.blue.opacity(0.2) : Color.red.opacity(0.2)
        let size = CGFloat(140 + (index * 30))
        
        return Circle()
            .stroke(ringColor, lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(testManager.isPlaying ? 1.0 : 0.8)
            .opacity(testManager.isPlaying ? 0.6 : 0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3),
                value: testManager.isPlaying
            )
    }
    
    private var testResponseButtons: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            // No button
            Button(action: {
                if testManager.isPlaying {
                    addDebugLog("User response: NO")
                    testManager.respondToTone(heard: false)
                }
            }) {
                Text("No")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(Color.red)
                    .cornerRadius(AppTheme.Radius.medium)
            }
            .disabled(!testManager.isPlaying)
            .opacity(testManager.isPlaying ? 1.0 : 0.5)
            
            // Yes button
            Button(action: {
                if testManager.isPlaying {
                    addDebugLog("User response: YES")
                    testManager.respondToTone(heard: true)
                }
            }) {
                Text("Yes")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(Color.green)
                    .cornerRadius(AppTheme.Radius.medium)
            }
            .disabled(!testManager.isPlaying)
            .opacity(testManager.isPlaying ? 1.0 : 0.5)
        }
        .padding(.top, AppTheme.Spacing.large)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            
            // Header text
            VStack(spacing: 8) {
                Text("Test Completed!")
                    .font(AppTheme.Typography.title2)
                
                Text("Your results are ready")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Test summary
            createTestSummary()
            
            Spacer()
            
            // View results button
            NavigationLink(
                destination: DetailedResultsView(testResults: testManager.getUserResponses())
                    .onAppear {
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
            // Save results as soon as the results view appears
            addDebugLog("Results view appeared - saving test data")
            saveTestResults()
            
            // Restart ambient sound monitoring for future tests
            soundService.startMonitoring()
        }
    }
    
    private func createTestSummary() -> some View {
        let responses = testManager.getUserResponses()
        let rightEarCount = responses.filter { $0.ear == .right }.count
        let leftEarCount = responses.filter { $0.ear == .left }.count
        let heardCount = responses.filter { $0.volumeHeard != Float.infinity }.count
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Test Summary:")
                .font(AppTheme.Typography.headline)
                .padding(.bottom, 4)
            
            Text("• \(responses.count) responses recorded")
            Text("• \(rightEarCount) right ear measurements")
            Text("• \(leftEarCount) left ear measurements")
            Text("• \(heardCount) 'heard' responses")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppTheme.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Data Saving
    
    private func saveTestResults() {
        addDebugLog("Processing and saving test results...")
        let responses = testManager.getUserResponses()
        addDebugLog("Total responses: \(responses.count)")
        
        // Create a FirestoreService instance
        let firestoreService = FirestoreService()
        
        // Process the test responses
        let resultsProcessor = ResultsProcessor()
        let processedResults = resultsProcessor.processResults(from: responses)
        
        // Log results
        addDebugLog("Right ear: \(processedResults.rightEarClassification.displayName)")
        addDebugLog("Left ear: \(processedResults.leftEarClassification.displayName)")
        
        // Create data for Firestore
        let rightEarData = processedResults.rightEarHearingLevel.map {
            ["frequency": $0.key, "hearingLevel": $0.value]
        }
        
        let leftEarData = processedResults.leftEarHearingLevel.map {
            ["frequency": $0.key, "hearingLevel": $0.value]
        }
        
        // Create a test result document
        let testResult: [String: Any] = [
            "testDate": Date(),
            "rightEarClassification": processedResults.rightEarClassification.displayName,
            "leftEarClassification": processedResults.leftEarClassification.displayName,
            "recommendations": processedResults.recommendations,
            "rightEarData": rightEarData,
            "leftEarData": leftEarData
        ]
        
        // Save the test result to Firestore
        firestoreService.saveTestResultForCurrentUser(testResult) { result in
            switch result {
            case .success:
                addDebugLog("Test results saved successfully to Firestore")
            case .failure(let error):
                addDebugLog("Failed to save: \(error.localizedDescription)")
            }
        }
    }
}
