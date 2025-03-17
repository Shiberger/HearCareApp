//
//  ResultsProcessor.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// Services/CoreML/ResultsProcessor.swift
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
        // Group responses by ear and frequency
        let rightEarResponses = responses.filter { $0.ear == .right }
        let leftEarResponses = responses.filter { $0.ear == .left }
        
        // These are the frequencies used in our model training
        let testFrequencies = [500.0, 1000.0, 2000.0, 4000.0, 8000.0]
        
        // Process right ear
        var rightEarHearingLevel: [Float: Float] = [:]
        for frequency in testFrequencies {
            let responsesForFrequency = rightEarResponses.filter { $0.frequency == Float(frequency) }
            if let lowestVolumeHeard = responsesForFrequency.map({ $0.volumeHeard }).min() {
                // Convert volume to hearing level in dB
                let hearingLevel = volumeTodB(lowestVolumeHeard)
                rightEarHearingLevel[Float(frequency)] = hearingLevel
            }
        }
        
        // Process left ear
        var leftEarHearingLevel: [Float: Float] = [:]
        for frequency in testFrequencies {
            let responsesForFrequency = leftEarResponses.filter { $0.frequency == Float(frequency) }
            if let lowestVolumeHeard = responsesForFrequency.map({ $0.volumeHeard }).min() {
                // Convert volume to hearing level in dB
                let hearingLevel = volumeTodB(lowestVolumeHeard)
                leftEarHearingLevel[Float(frequency)] = hearingLevel
            }
        }
        
        // Classify using CoreML model
        var rightClassification: HearingModelService.HearingClassification
        var leftClassification: HearingModelService.HearingClassification
        
        if let classifications = modelService.classifyHearing(
            rightEarLevels: rightEarHearingLevel,
            leftEarLevels: leftEarHearingLevel
        ) {
            rightClassification = classifications.right
            leftClassification = classifications.left
        } else {
            // Fallback to manual classification if ML model fails
            rightClassification = modelService.classifyHearingManually(levels: rightEarHearingLevel)
            leftClassification = modelService.classifyHearingManually(levels: leftEarHearingLevel)
        }
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            rightClassification: rightClassification,
            leftClassification: leftClassification
        )
        
        return HearingResult(
            rightEarHearingLevel: rightEarHearingLevel,
            leftEarHearingLevel: leftEarHearingLevel,
            rightEarClassification: rightClassification,
            leftEarClassification: leftClassification,
            recommendations: recommendations
        )
    }
    
    private func volumeTodB(_ volume: Float) -> Float {
        if volume == Float.infinity {
            return 120.0  // Max testable threshold
        }
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
        if let dB = volumeLevels[volume] {
            return dB
        }
        // Linear interpolation for intermediate values
        let sortedKeys = volumeLevels.keys.sorted()
        for i in 0..<(sortedKeys.count - 1) {
            let v1 = sortedKeys[i]
            let v2 = sortedKeys[i + 1]
            if volume >= v1 && volume <= v2 {
                let dB1 = volumeLevels[v1]!
                let dB2 = volumeLevels[v2]!
                return dB1 + (dB2 - dB1) * (volume - v1) / (v2 - v1)
            }
        }
        return min(max(volume * 80.0, 0), 120)  // Fallback, capped at 120 dB
    }
    
    private func generateRecommendations(
        rightClassification: HearingModelService.HearingClassification,
        leftClassification: HearingModelService.HearingClassification
    ) -> [String] {
        // Get the worse classification
        let classifications = [rightClassification, leftClassification]
        let worstIndex = classifications.indices.max(by: {
            HearingModelService.HearingClassification.allCases.firstIndex(of: classifications[$0])! <
            HearingModelService.HearingClassification.allCases.firstIndex(of: classifications[$1])!
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
