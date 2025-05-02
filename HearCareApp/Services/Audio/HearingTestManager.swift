//
//  HearingTestManager.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 14/3/2568 BE.
//

import Foundation
import AVFoundation

class HearingTestManager: ObservableObject {
    // Main service to generate tones
//    private let audioService = AudioService()
    private lazy var audioService: AudioService = {
        return AudioService()
    }()
    
    // Published properties for UI
    @Published var isPlaying = false
    @Published var currentFrequency: Float = 0
    @Published var currentEar: AudioService.Ear = .right
    @Published var progress: Float = 0.0
    @Published var testStatus: TestStatus = .ready
    @Published var shouldShowHearingButtons = true // Always show buttons
    @Published var currentDBLevel: Float = 0 // Expose dB level for UI
    @Published var debugInfo: String = "" // For debugging
    
    // Response timeout configuration
    private let responseTimeoutDuration: TimeInterval = 5.0  // Longer timeout - 5 seconds
    private var responseTimeoutWorkItem: DispatchWorkItem?
    
    // Hughson-Westlake protocol parameters
    // Starting with 1kHz as per standard protocol
    private let standardFrequencySequence: [Float] = [500, 1000, 2000, 4000, 8000]
    
    private let dbHLLevels: [Float] = [
        -10, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45,
        50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100
    ]
    
    // Calibration map from dB HL to device volume (0-1)
    private let dbHLToDeviceVolume: [Float: Float] = [
        -10: 0.05, -5: 0.06, 0: 0.07, 5: 0.09, 10: 0.11,
        15: 0.13, 20: 0.16, 25: 0.20, 30: 0.24, 35: 0.29,
        40: 0.35, 45: 0.41, 50: 0.48, 55: 0.55, 60: 0.61,
        65: 0.67, 70: 0.72, 75: 0.77, 80: 0.82, 85: 0.86,
        90: 0.90, 95: 0.95, 100: 1.0
    ]
    
    // Test state variables
    private var currentFrequencyIndex = 0
    private var dbLevelIndex = 0
    private var responseCount = 0
    private var positiveResponseCount = 0
    private var lastLevel: Float = 0 // To track level changes
    private var testPhase: TestPhase = .familiarization
    private var testResults: [AudioService.TestResponse] = []
    private var rightEarThresholds: [Float: Float] = [:]
    private var leftEarThresholds: [Float: Float] = [:]
    
    enum TestStatus {
        case ready
        case testing
        case complete
    }
    
    enum TestPhase: String {
        case familiarization = "Familiarization"
        case descending = "Descending"
        case ascending = "Ascending"
        case confirmation = "Confirmation"
    }
    
    // MARK: - Test Control Methods
    
    func startTest(startingEar: AudioService.Ear) {
        // Initialize test variables
        currentEar = startingEar
        progress = 0.0
        currentFrequencyIndex = 0
        testResults = []
        rightEarThresholds = [:]
        leftEarThresholds = [:]
        testStatus = .testing
        testPhase = .familiarization
        
        // Start with first frequency in sequence (1000 Hz)
        currentFrequency = standardFrequencySequence[currentFrequencyIndex]
        
        // Start familiarization at 40 dB for most people to hear
        dbLevelIndex = dbHLLevels.firstIndex(of: 40) ?? 10
        currentDBLevel = dbHLLevels[dbLevelIndex]
        lastLevel = currentDBLevel
        
        responseCount = 0
        positiveResponseCount = 0
        
        // updateDebugInfo()
        // Begin first tone
        playTone()
    }
    
    func playTone() {
        // Cancel any existing timeout
        cancelResponseTimeout()
        
        isPlaying = false
        
        // Convert dB HL to device volume
        let deviceVolume = dbHLToDeviceVolume[currentDBLevel] ?? 0.5
        
        // Short delay before playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.audioService.generateTone(
                frequency: self.currentFrequency,
                volume: deviceVolume,
                ear: self.currentEar
            )
            
            self.isPlaying = true
            // self.updateDebugInfo()
            
            // Set a timeout for response - using a DispatchWorkItem that can be cancelled
            self.setResponseTimeout()
        }
    }
    
    private func setResponseTimeout() {
        // Create a new timeout work item
        let timeoutWork = DispatchWorkItem { [weak self] in
            guard let self = self, self.isPlaying else { return }
            
            // Only auto-respond if still playing
            self.respondToTone(heard: false)
        }
        
        self.responseTimeoutWorkItem = timeoutWork
        
        // Schedule the timeout
        DispatchQueue.main.asyncAfter(
            deadline: .now() + responseTimeoutDuration,
            execute: timeoutWork
        )
    }
    
    private func cancelResponseTimeout() {
        responseTimeoutWorkItem?.cancel()
        responseTimeoutWorkItem = nil
    }
    
    func stopTest() {
        cancelResponseTimeout()
        audioService.stop()
        isPlaying = false
        testStatus = .ready
    }
    
    func getUserResponses() -> [AudioService.TestResponse] {
        return testResults
    }
    
    // MARK: - Test Logic Methods
    
    // Fix the respondToTone method to properly record hearing thresholds
    func respondToTone(heard: Bool) {
        // Cancel the response timeout
        cancelResponseTimeout()
        
        // Stop the tone
        audioService.stop()
        isPlaying = false
        
        // Record the response for debugging
        print("Response at \(currentFrequency) Hz, \(currentDBLevel) dB: \(heard ? "Heard" : "Not heard")")
        
        // Process response according to test phase
        switch testPhase {
        case .familiarization:
            handleFamiliarizationResponse(heard: heard)
        case .descending:
            handleDescendingResponse(heard: heard)
        case .ascending:
            handleAscendingResponse(heard: heard)
        case .confirmation:
            handleConfirmationResponse(heard: heard)
        }
    }
    
    private func handleFamiliarizationResponse(heard: Bool) {
        if heard {
            // Patient is familiarized, move to descending phase
            testPhase = .descending
            lastLevel = currentDBLevel
            // Re-test at same level to begin descent
            playTone()
        } else {
            // Increase by 20dB and try again
            let wasIncreased = increaseDBLevel(by: 20)
            
            // If we couldn't increase (already at max), record "not heard" and move on
            if !wasIncreased && currentDBLevel >= 90 {
                // Already at very high level and still not heard, record as profound loss
                recordThreshold(atLevel: 100) // Use 100 dB to indicate profound loss
                moveToNextFrequencyOrEar()
            } else {
                playTone()
            }
        }
    }
    
    // Add a clearer log in handleAscendingResponse and handleDescendingResponse:
    private func handleDescendingResponse(heard: Bool) {
        if heard {
            // Decrease by 10dB
            let wasDecreased = decreaseDBLevel(by: 10)
            print("Descending phase: Heard at \(lastLevel)dB, decreasing to \(currentDBLevel)dB")
            if !wasDecreased {
                // Already at minimum, record this as threshold and move on
                recordThreshold()
                moveToNextFrequencyOrEar()
            } else {
                lastLevel = currentDBLevel
                playTone()
            }
        } else {
            // Not heard, switch to ascending phase
            testPhase = .ascending
            responseCount = 0
            positiveResponseCount = 0
            
            // Increase by 5dB for ascending phase
            increaseDBLevel(by: 5)
            print("Switching to ascending phase at \(currentDBLevel)dB")
            lastLevel = currentDBLevel
            playTone()
        }
    }
    
    // Key improvements to the hearing test flow
    func handleAscendingResponse(heard: Bool) {
        responseCount += 1
        
        if heard {
            positiveResponseCount += 1
            print("Ascending phase: Heard at \(currentDBLevel)dB, positive responses: \(positiveResponseCount)/\(responseCount)")
            
            // Need at least 2 positive responses out of 3 attempts at same level
            if positiveResponseCount >= 2 && responseCount >= 3 {
                // Threshold confirmed
                print("Threshold confirmed at \(currentDBLevel)dB")
                recordThreshold()
                moveToNextFrequencyOrEar()
            } else if responseCount >= 5 {
                // Too many attempts without confirmation
                print("Maximum attempts reached, recording \(currentDBLevel)dB as threshold")
                recordThreshold()  // Use current level as best estimate
                moveToNextFrequencyOrEar()
            } else {
                // Continue testing at same level
                playTone()
            }
        } else {
            // If not heard, increase by 5dB and continue
            increaseDBLevel(by: 5)
            print("Ascending phase: Not heard at \(lastLevel)dB, increasing to \(currentDBLevel)dB")
            responseCount = 0  // Reset response tracking at new level
            positiveResponseCount = 0
            playTone()
        }
    }
    
    private func handleConfirmationResponse(heard: Bool) {
        responseCount += 1
        if heard {
            positiveResponseCount += 1
        }
        
        // Check for 2 out of 3 or 3 out of 5 identical responses
        if positiveResponseCount >= 2 && responseCount >= 3 {
            // Threshold confirmed
            recordThreshold()
            moveToNextFrequencyOrEar()
        } else if responseCount >= 5 {
            // 5 responses but not enough positive ones
            // Try again at 5dB higher
            increaseDBLevel(by: 5)
            testPhase = .ascending
            responseCount = 0
            positiveResponseCount = 0
            lastLevel = currentDBLevel
            playTone()
        } else {
            // Need more responses at same level
            playTone()
        }
    }
    
    private func increaseDBLevel(by amount: Float) -> Bool {
        // Find the next level that is at least 'amount' higher
        if let currentIndex = dbHLLevels.firstIndex(of: currentDBLevel) {
            for i in (currentIndex + 1)..<dbHLLevels.count {
                if dbHLLevels[i] >= currentDBLevel + amount {
                    dbLevelIndex = i
                    currentDBLevel = dbHLLevels[i]
                    return true
                }
            }
            // If we get here, use the maximum level
            dbLevelIndex = dbHLLevels.count - 1
            currentDBLevel = dbHLLevels.last ?? 90
            return currentDBLevel > lastLevel
        }
        return false
    }
    
    private func decreaseDBLevel(by amount: Float) -> Bool {
        // Find the next level that is at least 'amount' lower
        if let currentIndex = dbHLLevels.firstIndex(of: currentDBLevel) {
            for i in (0..<currentIndex).reversed() {
                if dbHLLevels[i] <= currentDBLevel - amount {
                    dbLevelIndex = i
                    currentDBLevel = dbHLLevels[i]
                    return true
                }
            }
            // If we get here, use the minimum level
            dbLevelIndex = 0
            currentDBLevel = dbHLLevels.first ?? -10
            return currentDBLevel < lastLevel
        }
        return false
    }
    
    // Fix the recordThreshold method to ensure dB values are stored correctly
    private func recordThreshold(atLevel: Float? = nil) {
        // Use provided level or current level
        let level = atLevel ?? currentDBLevel
        
        print("Recording threshold for \(currentFrequency) Hz at \(level) dB")
        
        // Convert from dBHL to volume level for storage
        // Store the actual dB value directly
        let response = AudioService.TestResponse(
            frequency: currentFrequency,
            volumeHeard: level,  // Store dB value directly
            ear: currentEar,
            timestamp: Date()
        )
        testResults.append(response)
        
        // Store in appropriate ear's thresholds
        if currentEar == .right {
            rightEarThresholds[currentFrequency] = level
        } else {
            leftEarThresholds[currentFrequency] = level
        }
    }
    
    private func moveToNextFrequencyOrEar() {
        currentFrequencyIndex += 1
        
        // Check if we need to change ears or complete test
        if currentFrequencyIndex >= standardFrequencySequence.count {
            if currentEar == .right {
                // Switch to left ear and reset frequency index
                currentEar = .left
                currentFrequencyIndex = 0
                updateProgress()
            } else {
                // Test complete
                completeTest()
                return
            }
        }
        
        // Start with the next frequency
        currentFrequency = standardFrequencySequence[currentFrequencyIndex]
        
        // Reset to familiarization phase
        testPhase = .familiarization
        dbLevelIndex = dbHLLevels.firstIndex(of: 40) ?? 10 // Start at 40 dB for familiarization
        currentDBLevel = dbHLLevels[dbLevelIndex]
        lastLevel = currentDBLevel
        responseCount = 0
        positiveResponseCount = 0
        
        updateProgress()
        playTone()
    }
    
    private func updateProgress() {
        // Total steps: 2 ears * number of frequencies (minus 1 for the retest of 1000 Hz)
        let totalFrequencies = standardFrequencySequence.count * 2 - 1
        let completedFrequencies =
            (currentEar == .right ? 0 : standardFrequencySequence.count) +
            currentFrequencyIndex
        
        progress = Float(completedFrequencies) / Float(totalFrequencies)
    }
    
    private func completeTest() {
        testStatus = .complete
        progress = 1.0
    }
    
    // For debugging purposes
//    private func updateDebugInfo() {
//        debugInfo = "Phase: \(testPhase.rawValue), Freq: \(Int(currentFrequency))Hz, Level: \(Int(currentDBLevel))dB, \(currentEar == .right ? "Right" : "Left") Ear"
//    }
    
    // MARK: - Results Processing
    
    func getAudiogramData() -> (right: [FrequencyDataPoint], left: [FrequencyDataPoint]) {
        // Convert thresholds to FrequencyDataPoint objects for the audiogram
        let rightEarData = rightEarThresholds.map { frequency, level in
            FrequencyDataPoint(frequency: frequency, hearingLevel: level)
        }
        
        let leftEarData = leftEarThresholds.map { frequency, level in
            FrequencyDataPoint(frequency: frequency, hearingLevel: level)
        }
        
        return (right: rightEarData, left: leftEarData)
    }
}
