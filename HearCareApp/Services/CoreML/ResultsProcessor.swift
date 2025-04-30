//
//  ResultsProcessor.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//  Updated with improved data handling and logging

import Foundation

class ResultsProcessor {
    private let modelService = HearingModelService()
    
    struct HearingResult {
        let rightEarHearingLevel: [Float: Float]  // Frequency: Hearing Level in dB
        let leftEarHearingLevel: [Float: Float]   // Frequency: Hearing Level in dB
        let rightEarClassification: HearingModelService.HearingClassification
        let leftEarClassification: HearingModelService.HearingClassification
        let recommendations: [String]
    }
    
    func processResults(from responses: [AudioService.TestResponse]) -> HearingResult {
        // Initial logging of all responses
        print("---------- PROCESSING TEST RESULTS ----------")
        print("Total responses: \(responses.count)")
        for (index, response) in responses.enumerated() {
            print("Response \(index): Ear: \(response.ear == .right ? "Right" : "Left"), Frequency: \(response.frequency) Hz, Level: \(response.volumeHeard) (stored value)")
        }
        
        // Group responses by ear and frequency
        let rightEarResponses = responses.filter { $0.ear == .right }
        let leftEarResponses = responses.filter { $0.ear == .left }
        
        print("Right ear responses: \(rightEarResponses.count)")
        print("Left ear responses: \(leftEarResponses.count)")
        
        // These are the frequencies used in our model training
        let testFrequencies = [250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0]
        
        // Process right ear data
        var rightEarHearingLevel: [Float: Float] = [:]
        
        print("---------- RIGHT EAR PROCESSING ----------")
        for frequency in testFrequencies {
            let responsesForFrequency = rightEarResponses.filter {
                abs($0.frequency - Float(frequency)) < 1.0 // Allow for small rounding differences
            }
            
            print("Frequency \(frequency) Hz - Found \(responsesForFrequency.count) responses")
            
            if let response = responsesForFrequency.min(by: { $0.volumeHeard < $1.volumeHeard }) {
                // Get the raw value and convert it properly to dB hearing level
                var hearingLevel: Float = 0
                
                // If volumeHeard is a direct dB value (recommended approach)
                if response.volumeHeard >= 0 && response.volumeHeard <= 120 {
                    hearingLevel = response.volumeHeard
                    print("Using direct dB value: \(hearingLevel) dB")
                }
                // If volumeHeard is actually a volume level (0-1)
                else if response.volumeHeard > 0 && response.volumeHeard <= 1.0 {
                    hearingLevel = safeConvertVolumeTodB(response.volumeHeard)
                    print("Converted volume \(response.volumeHeard) to dB: \(hearingLevel) dB")
                }
                // Handle special case for "not heard"
                else if response.volumeHeard == Float.infinity {
                    hearingLevel = 120.0 // Maximum threshold
                    print("Response marked as 'not heard', using maximum threshold: \(hearingLevel) dB")
                }
                // Handle any other unexpected values
                else {
                    hearingLevel = min(max(response.volumeHeard, 0), 120)
                    print("WARNING: Unexpected value \(response.volumeHeard), clamped to: \(hearingLevel) dB")
                }
                
                // Store the processed value
                rightEarHearingLevel[Float(frequency)] = hearingLevel
                print("Right ear at \(frequency) Hz: \(hearingLevel) dB (STORED)")
            } else {
                print("No responses found for \(frequency) Hz - Right ear")
            }
        }
        
        // Process left ear data
        var leftEarHearingLevel: [Float: Float] = [:]
        
        print("---------- LEFT EAR PROCESSING ----------")
        for frequency in testFrequencies {
            let responsesForFrequency = leftEarResponses.filter {
                abs($0.frequency - Float(frequency)) < 1.0 // Allow for small rounding differences
            }
            
            print("Frequency \(frequency) Hz - Found \(responsesForFrequency.count) responses")
            
            if let response = responsesForFrequency.min(by: { $0.volumeHeard < $1.volumeHeard }) {
                // Get the raw value and convert it properly to dB hearing level
                var hearingLevel: Float = 0
                
                // If volumeHeard is a direct dB value (recommended approach)
                if response.volumeHeard >= 0 && response.volumeHeard <= 120 {
                    hearingLevel = response.volumeHeard
                    print("Using direct dB value: \(hearingLevel) dB")
                }
                // If volumeHeard is actually a volume level (0-1)
                else if response.volumeHeard > 0 && response.volumeHeard <= 1.0 {
                    hearingLevel = safeConvertVolumeTodB(response.volumeHeard)
                    print("Converted volume \(response.volumeHeard) to dB: \(hearingLevel) dB")
                }
                // Handle special case for "not heard"
                else if response.volumeHeard == Float.infinity {
                    hearingLevel = 120.0 // Maximum threshold
                    print("Response marked as 'not heard', using maximum threshold: \(hearingLevel) dB")
                }
                // Handle any other unexpected values
                else {
                    hearingLevel = min(max(response.volumeHeard, 0), 120)
                    print("WARNING: Unexpected value \(response.volumeHeard), clamped to: \(hearingLevel) dB")
                }
                
                // Store the processed value
                leftEarHearingLevel[Float(frequency)] = hearingLevel
                print("Left ear at \(frequency) Hz: \(hearingLevel) dB (STORED)")
            } else {
                print("No responses found for \(frequency) Hz - Left ear")
            }
        }
        
        // Check if we have complete data
        let frequenciesWithRightEarData = rightEarHearingLevel.keys.sorted()
        let frequenciesWithLeftEarData = leftEarHearingLevel.keys.sorted()
        
        print("---------- DATA COMPLETENESS CHECK ----------")
        print("Right ear frequencies: \(frequenciesWithRightEarData)")
        print("Left ear frequencies: \(frequenciesWithLeftEarData)")
        
        // Add dummy data if needed for testing - remove this for production
        if rightEarHearingLevel.isEmpty {
            print("WARNING: Adding dummy data for right ear (FOR TESTING ONLY)")
            for freq in testFrequencies {
                rightEarHearingLevel[Float(freq)] = 20.0 + Float.random(in: 0...30)
            }
        }
        
        if leftEarHearingLevel.isEmpty {
            print("WARNING: Adding dummy data for left ear (FOR TESTING ONLY)")
            for freq in testFrequencies {
                leftEarHearingLevel[Float(freq)] = 20.0 + Float.random(in: 0...30)
            }
        }
        
        // Classify using CoreML model or fallback to manual classification
        print("---------- CLASSIFICATION ----------")
        var rightClassification: HearingModelService.HearingClassification
        var leftClassification: HearingModelService.HearingClassification
        
        if rightEarHearingLevel.count >= 3 && leftEarHearingLevel.count >= 3 {
            print("Attempting ML classification with sufficient data points")
            if let classifications = modelService.classifyHearing(
                rightEarLevels: rightEarHearingLevel,
                leftEarLevels: leftEarHearingLevel
            ) {
                rightClassification = classifications.right
                leftClassification = classifications.left
                print("ML classification successful")
                print("Right ear: \(rightClassification.displayName)")
                print("Left ear: \(leftClassification.displayName)")
            } else {
                print("ML classification failed, using manual classification")
                rightClassification = modelService.classifyHearingManually(levels: rightEarHearingLevel)
                leftClassification = modelService.classifyHearingManually(levels: leftEarHearingLevel)
                print("Manual classification results:")
                print("Right ear: \(rightClassification.displayName)")
                print("Left ear: \(leftClassification.displayName)")
            }
        } else {
            print("Insufficient data points for ML, using manual classification")
            rightClassification = modelService.classifyHearingManually(levels: rightEarHearingLevel)
            leftClassification = modelService.classifyHearingManually(levels: leftEarHearingLevel)
            print("Manual classification results:")
            print("Right ear: \(rightClassification.displayName)")
            print("Left ear: \(leftClassification.displayName)")
        }
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            rightClassification: rightClassification,
            leftClassification: leftClassification
        )
        
        print("---------- RESULT SUMMARY ----------")
        print("Right ear data points: \(rightEarHearingLevel.count)")
        for (freq, level) in rightEarHearingLevel.sorted(by: { $0.key < $1.key }) {
            print("  \(freq) Hz: \(level) dB")
        }
        
        print("Left ear data points: \(leftEarHearingLevel.count)")
        for (freq, level) in leftEarHearingLevel.sorted(by: { $0.key < $1.key }) {
            print("  \(freq) Hz: \(level) dB")
        }
        
        print("Right ear classification: \(rightClassification.displayName)")
        print("Left ear classification: \(leftClassification.displayName)")
        print("Recommendations count: \(recommendations.count)")
        print("---------- END PROCESSING ----------")
        
        return HearingResult(
            rightEarHearingLevel: rightEarHearingLevel,
            leftEarHearingLevel: leftEarHearingLevel,
            rightEarClassification: rightClassification,
            leftEarClassification: leftClassification,
            recommendations: recommendations
        )
    }
    
    // Improved volume to dB conversion with safety checks
    private func safeConvertVolumeTodB(_ volume: Float) -> Float {
        if volume == Float.infinity {
            return 120.0  // Max testable threshold
        }
        
        // Ensure volume is within expected range
        let safeVolume = min(max(volume, 0.0), 1.0)
        
        // Define mapping from volume to dB HL
        let volumeLevels: [Float: Float] = [
            0.05: 0,   // Normal hearing threshold
            0.1: 10,
            0.2: 20,
            0.3: 30,
            0.4: 40,
            0.5: 50,
            0.7: 60,
            0.9: 70,
            1.0: 80    // Add higher volumes if your test supports them
        ]
        
        // Exact match
        if let dB = volumeLevels[safeVolume] {
            return dB
        }
        
        // Linear interpolation for intermediate values
        let sortedKeys = volumeLevels.keys.sorted()
        
        // Below minimum
        if safeVolume < sortedKeys.first! {
            return volumeLevels[sortedKeys.first!]! * (safeVolume / sortedKeys.first!)
        }
        
        // Above maximum
        if safeVolume > sortedKeys.last! {
            let lastKey = sortedKeys.last!
            let lastValue = volumeLevels[lastKey]!
            let slope = lastValue / lastKey
            let extrapolated = lastValue + slope * (safeVolume - lastKey)
            return min(extrapolated, 120.0) // Cap at 120 dB
        }
        
        // Interpolate between values
        for i in 0..<(sortedKeys.count - 1) {
            let v1 = sortedKeys[i]
            let v2 = sortedKeys[i + 1]
            if safeVolume >= v1 && safeVolume <= v2 {
                let dB1 = volumeLevels[v1]!
                let dB2 = volumeLevels[v2]!
                return dB1 + (dB2 - dB1) * (safeVolume - v1) / (v2 - v1)
            }
        }
        
        // Fallback (should never reach here)
        return min(max(safeVolume * 80.0, 0), 120)
    }
    
    private func generateRecommendations(
        rightClassification: HearingModelService.HearingClassification,
        leftClassification: HearingModelService.HearingClassification
    ) -> [String] {
        // Get the worse classification
        let classifications = [rightClassification, leftClassification]
        let worstIndex = classifications.indices.max(by: { index1, index2 in
            return (HearingModelService.HearingClassification.allCases.firstIndex(of: classifications[index1])! != 0)
                   HearingModelService.HearingClassification.allCases.firstIndex(of: classifications[index2])!
        }) ?? 0
        
        // Get recommendations based on the worse ear
        var recommendations = classifications[worstIndex].recommendations
        
        // Add ear-specific recommendations if they differ
        if rightClassification != leftClassification {
            recommendations.append("Your hearing levels differ between ears. This asymmetry should be evaluated by a professional.")
        }
        
        // Add general recommendations
        recommendations.append("Remember to retest your hearing periodically to track any changes.")
        
        return recommendations
    }
}
