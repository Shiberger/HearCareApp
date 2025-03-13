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
        
        // Process right ear
        var rightEarHearingLevel: [Float: Float] = [:]
        for frequency in [250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0] {
            let responsesForFrequency = rightEarResponses.filter { $0.frequency == Float(frequency) }
            if let lowestVolumeHeard = responsesForFrequency.map({ $0.volumeHeard }).min() {
                // Convert volume to hearing level in dB
                let hearingLevel = volumeTodB(lowestVolumeHeard)
                rightEarHearingLevel[Float(frequency)] = hearingLevel
            }
        }
        
        // Process left ear
        var leftEarHearingLevel: [Float: Float] = [:]
        for frequency in [250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0] {
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
        // Calibration for a proper audiogram
        // For typical audiometric testing:
        // - Lower volumes that were heard = better hearing = lower dB values (0-25 dB)
        // - Higher volumes needed to hear = poorer hearing = higher dB values (40+ dB)
        
        // Special case for "not heard" (infinity)
        if volume == Float.infinity {
            return 90.0  // Not heard even at maximum - severe to profound loss
        }
        
        // Map our testing volume range to proper audiometric dB values
        // volumeLevels: [0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9]
        // should map approximately to: [0, 10, 20, 30, 40, 50, 60, 70]
        
        // Simple linear mapping - adjust these values based on your calibration
        let minVolume: Float = 0.05
        let maxVolume: Float = 0.9
        
        // Normalize the volume
        let normalizedVolume = (volume - minVolume) / (maxVolume - minVolume)
        
        // Map to dB range (0-80 dB) with lower volumes = better hearing
        return normalizedVolume * 80.0
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
