//
//  HearingModelService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//  Updated with improved error handling and diagnostics
//  Fixed conditional binding issue with stringValue

import Foundation
import CoreML

class HearingModelService {
    private let model: HearingClassifier?
    private let debugLogging = true // Enable detailed logging
    
    enum HearingClassification: String, CaseIterable {
        case normal = "normal"
        case mild = "mild"
        case moderate = "moderate"
        case moderatelySevere = "moderatelySevere"
        case severe = "severe"
        case profound = "profound"
        
        var displayName: String {
            switch self {
            case .normal: return "Normal Hearing"
            case .mild: return "Mild Hearing Loss"
            case .moderate: return "Moderate Hearing Loss"
            case .moderatelySevere: return "Moderately Severe Hearing Loss"
            case .severe: return "Severe Hearing Loss"
            case .profound: return "Profound Hearing Loss"
            }
        }
        
        var description: String {
            switch self {
            case .normal:
                return "You can hear soft sounds across most frequencies."
            case .mild:
                return "You may have difficulty hearing soft sounds and understanding speech in noisy environments."
            case .moderate:
                return "You likely have difficulty following conversations without hearing aids."
            case .moderatelySevere:
                return "You have difficulty with normal conversations and may miss significant speech elements without amplification."
            case .severe:
                return "You may hear almost no speech when a person talks at a normal level."
            case .profound:
                return "You may not hear loud speech or sounds without powerful hearing aids or a cochlear implant."
            }
        }

        var recommendations: [String] {
            switch self {
            case .normal:
                return [
                    "Your hearing appears to be within normal range.",
                    "Continue to protect your hearing by avoiding prolonged exposure to loud noises.",
                    "Get your hearing checked annually as part of your health routine."
                ]
            case .mild:
                return [
                    "You have mild hearing loss in one or both ears.",
                    "Consider scheduling a follow-up appointment with an audiologist.",
                    "Avoid noisy environments when possible.",
                    "Consider using assistive listening devices in challenging situations."
                ]
            case .moderate:
                return [
                    "You have moderate hearing loss that may impact your daily communication.",
                    "We recommend consulting with an audiologist to discuss hearing aid options.",
                    "Consider strategies for better communication in noisy environments.",
                    "Look into hearing assistive technologies for phones and other devices."
                ]
            case .moderatelySevere:
                return [
                    "You have moderately severe hearing loss that significantly impacts daily communication.",
                    "Hearing aids are strongly recommended for this level of hearing loss.",
                    "Consider additional assistive listening devices for specific situations.",
                    "Learn communication strategies to maximize understanding in conversations."
                ]
            case .severe, .profound:
                return [
                    "You have significant hearing loss that requires professional attention.",
                    "Please consult with an audiologist as soon as possible.",
                    "Hearing aids or other assistive devices may significantly improve your quality of life.",
                    "Consider learning about additional communication strategies like speech reading."
                ]
            }
        }
    }
    
    init() {
        do {
            self.model = try HearingClassifier()
            logMessage("HearingClassifier model loaded successfully")
        } catch {
            logMessage("Failed to initialize Core ML model: \(error.localizedDescription)", isError: true)
            self.model = nil
        }
    }
    
    func classifyHearing(rightEarLevels: [Float: Float], leftEarLevels: [Float: Float]) -> (right: HearingClassification, left: HearingClassification)? {
        logMessage("---------- HEARING CLASSIFICATION START ----------")
        logMessage("Input data - Right ear frequencies: \(rightEarLevels.keys.sorted())")
        logMessage("Input data - Left ear frequencies: \(leftEarLevels.keys.sorted())")
        
        // Validate input data first
        if rightEarLevels.isEmpty || leftEarLevels.isEmpty {
            logMessage("Missing data for one or both ears", isError: true)
            logMessage("Using manual classification due to missing data")
            
            let rightClassification = classifyHearingManually(levels: rightEarLevels)
            let leftClassification = classifyHearingManually(levels: leftEarLevels)
            
            logMessage("Manual classification results:")
            logMessage("Right ear: \(rightClassification.displayName)")
            logMessage("Left ear: \(leftClassification.displayName)")
            logMessage("---------- HEARING CLASSIFICATION END ----------")
            
            return (right: rightClassification, left: leftClassification)
        }
        
        // Check if model is available
        guard let model = model else {
            logMessage("CoreML model not available", isError: true)
            logMessage("Using manual classification due to missing model")
            
            let rightClassification = classifyHearingManually(levels: rightEarLevels)
            let leftClassification = classifyHearingManually(levels: leftEarLevels)
            
            logMessage("Manual classification results:")
            logMessage("Right ear: \(rightClassification.displayName)")
            logMessage("Left ear: \(leftClassification.displayName)")
            logMessage("---------- HEARING CLASSIFICATION END ----------")
            
            return (right: rightClassification, left: leftClassification)
        }
        
        // Define the frequencies required by the model (standard audiogram frequencies)
        let modelFrequencies = [500, 1000, 2000, 4000, 8000]
        
        // Check if we have enough frequencies for a reliable classification
        let rightFrequencies = Set(rightEarLevels.keys.map { Int($0) })
        let leftFrequencies = Set(leftEarLevels.keys.map { Int($0) })
        let requiredFrequencies = Set(modelFrequencies)
        
        let rightHasEnoughData = rightFrequencies.intersection(requiredFrequencies).count >= 3
        let leftHasEnoughData = leftFrequencies.intersection(requiredFrequencies).count >= 3
        
        logMessage("Right ear has sufficient frequencies: \(rightHasEnoughData)")
        logMessage("Left ear has sufficient frequencies: \(leftHasEnoughData)")
        
        if !rightHasEnoughData || !leftHasEnoughData {
            logMessage("Insufficient frequency coverage for ML model", isError: true)
            logMessage("Using manual classification due to insufficient frequency coverage")
            
            let rightClassification = classifyHearingManually(levels: rightEarLevels)
            let leftClassification = classifyHearingManually(levels: leftEarLevels)
            
            logMessage("Manual classification results:")
            logMessage("Right ear: \(rightClassification.displayName)")
            logMessage("Left ear: \(leftClassification.displayName)")
            logMessage("---------- HEARING CLASSIFICATION END ----------")
            
            return (right: rightClassification, left: leftClassification)
        }
        
        // Create a dictionary of input values with proper types
        var inputDict: [String: Double] = [:]
        var missingFrequencies = false
        
        // Add right ear data for the frequencies the model expects
        logMessage("Preparing right ear inputs:")
        for frequency in modelFrequencies {
            let floatFreq = Float(frequency)
            let key = "\(frequency)Hz_right"
            
            // Look for exact or closest match
            if let level = rightEarLevels[floatFreq] {
                inputDict[key] = Double(level)
                logMessage("  \(key) = \(level) dB (exact match)")
            } else {
                // Try to find a close frequency match (within 10% tolerance)
                let closestKey = findClosestFrequency(frequency: floatFreq, in: rightEarLevels.keys)
                if let closestKey = closestKey, let level = rightEarLevels[closestKey] {
                    inputDict[key] = Double(level)
                    logMessage("  \(key) = \(level) dB (using \(closestKey) Hz as approximate match)")
                } else {
                    // Use an interpolated or default value
                    let estimatedValue = estimateValueForFrequency(frequency: floatFreq, in: rightEarLevels)
                    inputDict[key] = Double(estimatedValue)
                    logMessage("  \(key) = \(estimatedValue) dB (estimated/default value)")
                    missingFrequencies = true
                }
            }
        }
        
        // Add left ear data for the frequencies the model expects
        logMessage("Preparing left ear inputs:")
        for frequency in modelFrequencies {
            let floatFreq = Float(frequency)
            let key = "\(frequency)Hz_left"
            
            // Look for exact or closest match
            if let level = leftEarLevels[floatFreq] {
                inputDict[key] = Double(level)
                logMessage("  \(key) = \(level) dB (exact match)")
            } else {
                // Try to find a close frequency match (within 10% tolerance)
                let closestKey = findClosestFrequency(frequency: floatFreq, in: leftEarLevels.keys)
                if let closestKey = closestKey, let level = leftEarLevels[closestKey] {
                    inputDict[key] = Double(level)
                    logMessage("  \(key) = \(level) dB (using \(closestKey) Hz as approximate match)")
                } else {
                    // Use an interpolated or default value
                    let estimatedValue = estimateValueForFrequency(frequency: floatFreq, in: leftEarLevels)
                    inputDict[key] = Double(estimatedValue)
                    logMessage("  \(key) = \(estimatedValue) dB (estimated/default value)")
                    missingFrequencies = true
                }
            }
        }
        
        // Final input validation
        if missingFrequencies {
            logMessage("Warning: Some frequencies were missing and estimated values were used")
        }
        
        // Print complete input dictionary for debugging
        logMessage("Complete model input dictionary:")
        let sortedKeys = inputDict.keys.sorted()
        for key in sortedKeys {
            logMessage("  \(key): \(inputDict[key]!)")
        }
        
        // Try to make prediction
        do {
            // Use the generic model interface
            let genericModel = model.model
            
            // Create a feature provider from our dictionary
            let provider = try MLDictionaryFeatureProvider(dictionary: inputDict.mapValues { NSNumber(value: $0) })
            
            logMessage("Model prediction attempt with \(inputDict.count) features")
            
            // Make prediction using the generic model interface
            let prediction = try genericModel.prediction(from: provider)
            
            // Log all output features for debugging
            logMessage("Model prediction succeeded. Outputs:")
            for featureName in prediction.featureNames {
                if let featureValue = prediction.featureValue(for: featureName) {
                    logMessage("  \(featureName): \(featureValue)")
                }
            }
            
            // Extract the main classification output
            if let outputFeatureValue = prediction.featureValue(for: "hearingClassification") {
                let outputString = outputFeatureValue.stringValue
                
                if let classification = HearingClassification(rawValue: outputString) {
                    logMessage("Overall classification from model: \(classification.displayName)")
                    
                    // Analyze each ear separately for more specific results
                    let rightClassification = determineEarClassification(levels: rightEarLevels)
                    let leftClassification = determineEarClassification(levels: leftEarLevels)
                    
                    logMessage("Right ear: \(rightClassification.displayName)")
                    logMessage("Left ear: \(leftClassification.displayName)")
                    logMessage("---------- HEARING CLASSIFICATION END ----------")
                    
                    return (right: rightClassification, left: leftClassification)
                } else {
                    logMessage("Invalid classification value: \(outputString)", isError: true)
                    logMessage("Using manual classification as fallback")
                    
                    // Fallback to manual classification
                    let rightClassification = classifyHearingManually(levels: rightEarLevels)
                    let leftClassification = classifyHearingManually(levels: leftEarLevels)
                    
                    logMessage("Manual classification results:")
                    logMessage("Right ear: \(rightClassification.displayName)")
                    logMessage("Left ear: \(leftClassification.displayName)")
                    logMessage("---------- HEARING CLASSIFICATION END ----------")
                    
                    return (right: rightClassification, left: leftClassification)
                }
            } else {
                // Feature not present error
                logMessage("Could not find 'hearingClassification' in model output", isError: true)
                logMessage("Using manual classification as fallback")
                
                let rightClassification = classifyHearingManually(levels: rightEarLevels)
                let leftClassification = classifyHearingManually(levels: leftEarLevels)
                
                logMessage("Manual classification results:")
                logMessage("Right ear: \(rightClassification.displayName)")
                logMessage("Left ear: \(leftClassification.displayName)")
                logMessage("---------- HEARING CLASSIFICATION END ----------")
                
                return (right: rightClassification, left: leftClassification)
            }
        } catch {
            logMessage("Error making prediction: \(error.localizedDescription)", isError: true)
            logMessage("Using manual classification due to prediction error")
            
            let rightClassification = classifyHearingManually(levels: rightEarLevels)
            let leftClassification = classifyHearingManually(levels: leftEarLevels)
            
            logMessage("Manual classification results:")
            logMessage("Right ear: \(rightClassification.displayName)")
            logMessage("Left ear: \(leftClassification.displayName)")
            logMessage("---------- HEARING CLASSIFICATION END ----------")
            
            return (right: rightClassification, left: leftClassification)
        }
    }
    
    // Helper function to find the closest frequency in a set of keys
    private func findClosestFrequency(frequency: Float, in keys: Dictionary<Float, Float>.Keys) -> Float? {
        let tolerance = frequency * 0.1 // 10% tolerance
        
        // First check if we have an exact match
        if keys.contains(frequency) {
            return frequency
        }
        
        // Look for frequencies within tolerance range
        let closeFrequencies = keys.filter { abs($0 - frequency) <= tolerance }
        if let closest = closeFrequencies.min(by: { abs($0 - frequency) < abs($1 - frequency) }) {
            return closest
        }
        
        return nil
    }
    
    // Helper function to estimate a value for a missing frequency
    private func estimateValueForFrequency(frequency: Float, in levels: [Float: Float]) -> Float {
        // If no data, return a default value in the normal hearing range
        if levels.isEmpty {
            return 20.0 // Default to mild hearing range
        }
        
        // Sort the available frequencies
        let sortedFreqs = levels.keys.sorted()
        
        // If frequency is below the lowest available, use the lowest
        if frequency < sortedFreqs.first! {
            return levels[sortedFreqs.first!]!
        }
        
        // If frequency is above the highest available, use the highest
        if frequency > sortedFreqs.last! {
            return levels[sortedFreqs.last!]!
        }
        
        // Find the two surrounding frequencies for interpolation
        var lowerFreq: Float = 0
        var higherFreq: Float = 0
        
        for i in 0..<sortedFreqs.count {
            if sortedFreqs[i] >= frequency {
                if i > 0 {
                    lowerFreq = sortedFreqs[i-1]
                    higherFreq = sortedFreqs[i]
                    break
                } else {
                    // This shouldn't happen due to earlier checks, but just in case
                    return levels[sortedFreqs[i]]!
                }
            }
        }
        
        // Interpolate between the two nearest frequencies
        let lowerLevel = levels[lowerFreq]!
        let higherLevel = levels[higherFreq]!
        
        // Linear interpolation
        let ratio = (frequency - lowerFreq) / (higherFreq - lowerFreq)
        return lowerLevel + ratio * (higherLevel - lowerLevel)
    }
    
    // Helper function to determine classification for a single ear
    private func determineEarClassification(levels: [Float: Float]) -> HearingClassification {
        // Always use manual classification for individual ears
        // This is more reliable than trying to use the model for single ear classification
        return classifyHearingManually(levels: levels)
    }
    
    // Improved manual classification method with error handling
    func classifyHearingManually(levels: [Float: Float]) -> HearingClassification {
        // Handle empty data
        if levels.isEmpty {
            logMessage("No hearing level data provided for manual classification", isError: true)
            return .normal // Default to normal if no data
        }
        
        // Calculate average hearing level
        let sum = levels.values.reduce(0, +)
        let avgHearingLevel = sum / Float(levels.count)
        
        logMessage("Manual classification - Average hearing level: \(avgHearingLevel) dB across \(levels.count) frequencies")
        
        // Custom weighting could be applied here based on frequency importance
        
        // Classify based on standard audiometric ranges
        let classification: HearingClassification
        switch avgHearingLevel {
        case -10..<25:
            classification = .normal           // Normal hearing: -10 to 25 dB
        case 25..<40:
            classification = .mild             // Mild loss: 25-40 dB
        case 40..<55:
            classification = .moderate         // Moderate loss: 40-55 dB
        case 55..<70:
            classification = .moderatelySevere // Moderately severe loss: 55-70 dB
        case 70..<90:
            classification = .severe           // Severe loss: 70-90 dB
        default:
            classification = .profound         // Profound loss: 90+ dB
        }
        
        logMessage("Manual classification result: \(classification.displayName)")
        return classification
    }
    
    // Helper method for logging
    private func logMessage(_ message: String, isError: Bool = false) {
        if debugLogging {
            let prefix = isError ? "❌ ERROR: " : "ℹ️ "
            print("\(prefix)\(message)")
        }
    }
}
