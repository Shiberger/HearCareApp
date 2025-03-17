//
//  HearingTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI

struct HearingTestView: View {
    @StateObject private var testManager = HearingTestManager()
    @State private var testStage: TestStage = .instructions
    @State private var selectedEar: AudioService.Ear = .right
    
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
                        testManager.stopTest()
                        testStage = .instructions
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Instructions View
    
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
    
    // MARK: - Preparation View
    
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
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
    
    // MARK: - Testing View (Fixed to prevent UI flashing)
    
    private var testingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Progress indicator
            VStack {
                ProgressView(value: CGFloat(testManager.progress))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryColor))
                    .padding(.horizontal)
                
                HStack {
                    Text("Progress: \(Int(testManager.progress * 100))%")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Testing \(testManager.currentEar == .right ? "Right" : "Left") Ear")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(testManager.currentEar == .right ? .blue : .red)
                }
                .padding(.horizontal)
            }
            
            // Debug info
            Text(testManager.debugInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Current dB level indicator
            HStack {
                Text("Current Level: \(Int(testManager.currentDBLevel)) dB")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Current frequency and ear indicator
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
            
            // Audio visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(testManager.currentEar == .right ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                if testManager.isPlaying {
                    // Animated rings when sound is playing
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(testManager.currentEar == .right ? Color.blue.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 2)
                            .frame(width: CGFloat(140 + (index * 30)), height: CGFloat(140 + (index * 30)))
                            .scaleEffect(testManager.isPlaying ? 1.0 : 0.8)
                            .opacity(testManager.isPlaying ? 0.6 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: testManager.isPlaying
                            )
                    }
                }
                
                Image(systemName: "ear.fill")
                    .font(.system(size: 60))
                    .foregroundColor(testManager.currentEar == .right ? .blue : .red)
                    .rotationEffect(testManager.currentEar == .right ? .zero : .degrees(180))
            }
            
            // Response buttons (always visible now)
            HStack(spacing: AppTheme.Spacing.large) {
                Button(action: {
                    if testManager.isPlaying {
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
                
                Button(action: {
                    if testManager.isPlaying {
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
            
            Spacer()
            
            // Frequency indicator (always visible)
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
                testManager.startTest(startingEar: selectedEar)
            }
        }
        .onChange(of: testManager.testStatus) { newStatus in
            if newStatus == .complete {
                testStage = .results
            }
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            
            Text("Test Completed!")
                .font(AppTheme.Typography.title2)
            
            Text("Your results are ready")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
            
            NavigationLink(
                destination: DetailedResultsView(testResults: testManager.getUserResponses())
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
            // Save results as soon as the results view appears
            saveTestResults()
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveTestResults() {
        // Create a FirestoreService instance
        let firestoreService = FirestoreService()
        
        // Process the test responses
        let resultsProcessor = ResultsProcessor()
        let processedResults = resultsProcessor.processResults(from: testManager.getUserResponses())
        
        // Create a test result document
        let testResult: [String: Any] = [
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
}
